// Supabase Edge Function: send-emergency-email
// This function is called manually (e.g., from DEBUG button) to send test emails

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!
const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')!

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Create Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: {
        headers: { Authorization: authHeader },
      },
    })

    // Get the current user
    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      throw new Error('Not authenticated')
    }

    console.log(`Manual email trigger for user: ${user.id}`)

    // Fetch user's profile
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single()

    if (profileError || !profile) {
      throw new Error('Profile not found')
    }

    // Fetch user's contacts
    const { data: contacts, error: contactError } = await supabase
      .from('contacts')
      .select('*')
      .eq('user_id', user.id)

    if (contactError) {
      throw new Error('Error fetching contacts')
    }

    if (!contacts || contacts.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No contacts found. Add contacts in the People tab.' }),
        {
          status: 400,
          headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
        }
      )
    }

    // Fetch user's custom message
    const { data: messageData } = await supabase
      .from('user_messages')
      .select('message')
      .eq('user_id', user.id)
      .single()

    const customMessage = messageData?.message || 'please come check on me.'

    console.log(`Sending test emails to ${contacts.length} contacts...`)

    let emailsSent = 0
    const errors = []

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
    .debug-badge { background-color: #f59e0b; color: white; padding: 5px 10px; border-radius: 3px; display: inline-block; margin-bottom: 10px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h2 style="margin: 0;">🚨 Emergency Alert (TEST)</h2>
    </div>
    <div class="content">
      <span class="debug-badge">DEBUG MODE - Test Email</span>
      <p>Dear ${contact.contact_name},</p>
      <p><strong>${profile.display_name}</strong> has triggered a test emergency alert.</p>
      <div class="message-box">
        <p style="margin: 0; color: #991b1b;"><strong>Message from ${profile.display_name}:</strong></p>
        <p style="margin: 10px 0 0 0;">${customMessage}</p>
      </div>
      <p><strong>This is a TEST email.</strong> In a real emergency, you would receive this notification when ${profile.display_name} hasn't checked in for ${profile.alert_threshold_days} day(s).</p>
    </div>
    <div class="footer">
      <p style="margin: 0;">This is a test email from the "Are You Dead Yet?" application.</p>
      <p style="margin: 5px 0 0 0;">Contact: ${profile.display_name} &lt;${profile.email}&gt;</p>
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
            reply_to: profile.email,
            to: [contact.contact_email],
            subject: `[TEST] Emergency Alert - ${profile.display_name} needs help`,
            html: emailHtml,
          }),
        })

        if (emailResponse.ok) {
          console.log(`✓ Email sent to ${contact.contact_email}`)
          emailsSent++
        } else {
          const errorData = await emailResponse.text()
          console.error(`✗ Failed to send email to ${contact.contact_email}:`, errorData)
          errors.push({ contact: contact.contact_email, error: errorData })
        }
      } catch (emailError) {
        console.error(`Error sending email to ${contact.contact_email}:`, emailError)
        errors.push({ contact: contact.contact_email, error: emailError.message })
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Test emails sent to ${emailsSent} contact(s)`,
        emailsSent,
        totalContacts: contacts.length,
        errors: errors.length > 0 ? errors : undefined,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
      }
    )
  }
})
