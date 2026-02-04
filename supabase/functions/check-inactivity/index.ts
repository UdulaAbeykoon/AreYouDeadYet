// Supabase Edge Function: check-inactivity
// This function checks for inactive users and sends emergency emails to their contacts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!

interface Profile {
    id: string
    display_name: string
    email: string
    last_check_in: string
    alert_threshold_days: number
    status: string
}

interface Contact {
    contact_name: string
    contact_email: string
    relationship: string
}

interface UserMessage {
    message: string
}

serve(async (req) => {
    try {
        // Create Supabase client with service role key (bypasses RLS)
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        console.log('Starting inactivity check...')

        // Query profiles to find users who have exceeded their alert threshold
        const { data: expiredUsers, error: profileError } = await supabase
            .from('profiles')
            .select('*')
            .eq('status', 'active')
            .lt('last_check_in', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()) // At least 1 day old

        if (profileError) {
            console.error('Error fetching profiles:', profileError)
            throw profileError
        }

        console.log(`Found ${expiredUsers?.length || 0} potentially expired users`)

        // Filter users who have actually exceeded their threshold
        const now = new Date()
        const trulyExpiredUsers = (expiredUsers || []).filter((user: Profile) => {
            const lastCheckIn = new Date(user.last_check_in)
            const thresholdMs = user.alert_threshold_days * 24 * 60 * 60 * 1000
            const timeSinceCheckIn = now.getTime() - lastCheckIn.getTime()
            return timeSinceCheckIn >= thresholdMs
        })

        console.log(`${trulyExpiredUsers.length} users have truly expired`)

        let emailsSent = 0
        let errors = 0

        // Process each expired user
        for (const user of trulyExpiredUsers) {
            try {
                console.log(`Processing user: ${user.display_name} (${user.email})`)

                // Fetch user's contacts
                const { data: contacts, error: contactError } = await supabase
                    .from('contacts')
                    .select('*')
                    .eq('user_id', user.id)

                if (contactError) {
                    console.error(`Error fetching contacts for user ${user.id}:`, contactError)
                    errors++
                    continue
                }

                if (!contacts || contacts.length === 0) {
                    console.log(`No contacts found for user ${user.display_name}`)
                    continue
                }

                // Fetch user's custom message
                const { data: messageData } = await supabase
                    .from('user_messages')
                    .select('message')
                    .eq('user_id', user.id)
                    .single()

                const customMessage = messageData?.message || 'please come check on me.'

                console.log(`Sending emails to ${contacts.length} contacts...`)

                // Send email to each contact
                for (const contact of contacts) {
                    try {
                        const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background-color: #dc2626; color: white; padding: 20px; border-radius: 5px 5px 0 0; }
    .content { background-color: #f9fafb; padding: 20px; border: 1px solid #e5e7eb; }
    .message-box { background-color: #fee2e2; border-left: 4px solid #dc2626; padding: 15px; margin: 20px 0; }
    .footer { background-color: #f3f4f6; padding: 15px; border-radius: 0 0 5px 5px; font-size: 12px; color: #6b7280; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2 style="margin: 0;">🚨 Emergency Alert</h2>
    </div>
    <div class="content">
      <p>Dear ${contact.contact_name},</p>
      <p><strong>${user.display_name}</strong> has not checked in for ${user.alert_threshold_days} day(s) and may need assistance.</p>
      <div class="message-box">
        <p style="margin: 0; color: #991b1b;"><strong>Message from ${user.display_name}:</strong></p>
        <p style="margin: 10px 0 0 0;">${customMessage}</p>
      </div>
      <p><strong>Please check on them as soon as possible.</strong></p>
      <p>Last check-in: ${new Date(user.last_check_in).toLocaleString()}</p>
    </div>
    <div class="footer">
      <p style="margin: 0;">This is an automated emergency alert from the "Are You Dead Yet?" application.</p>
      <p style="margin: 5px 0 0 0;">Contact: ${user.display_name} &lt;${user.email}&gt;</p>
    </div>
  </div>
</body>
</html>
            `

                        // Send email using Resend
                        const emailResponse = await fetch('https://api.resend.com/emails', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                                'Authorization': `Bearer ${RESEND_API_KEY}`,
                            },
                            body: JSON.stringify({
                                from: 'Are You Dead Yet? <onboarding@resend.dev>',
                                reply_to: user.email,
                                to: [contact.contact_email],
                                subject: `Emergency Alert - ${user.display_name} needs help`,
                                html: emailHtml,
                            }),
                        })

                        if (emailResponse.ok) {
                            console.log(`✓ Email sent to ${contact.contact_email}`)
                            emailsSent++
                        } else {
                            const errorData = await emailResponse.text()
                            console.error(`✗ Failed to send email to ${contact.contact_email}:`, errorData)
                            errors++
                        }
                    } catch (emailError) {
                        console.error(`Error sending email to ${contact.contact_email}:`, emailError)
                        errors++
                    }
                }

                // Update user status to 'alerted' to prevent duplicate emails
                const { error: updateError } = await supabase
                    .from('profiles')
                    .update({ status: 'alerted' })
                    .eq('id', user.id)

                if (updateError) {
                    console.error(`Error updating status for user ${user.id}:`, updateError)
                } else {
                    console.log(`✓ Updated status to 'alerted' for ${user.display_name}`)
                }

            } catch (userError) {
                console.error(`Error processing user ${user.id}:`, userError)
                errors++
            }
        }

        return new Response(
            JSON.stringify({
                success: true,
                message: 'Inactivity check completed',
                stats: {
                    usersChecked: expiredUsers?.length || 0,
                    usersExpired: trulyExpiredUsers.length,
                    emailsSent,
                    errors,
                }
            }),
            {
                status: 200,
                headers: { 'Content-Type': 'application/json' }
            }
        )

    } catch (error) {
        console.error('Fatal error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                status: 500,
                headers: { 'Content-Type': 'application/json' }
            }
        )
    }
})
