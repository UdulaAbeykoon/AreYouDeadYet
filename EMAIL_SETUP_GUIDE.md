# Email Setup Guide for "Are You Dead Yet?" App

## Overview
The app now uses **Supabase Edge Functions** with **Resend API** to send emails. This allows any user to send emergency alerts from their own email address without configuring SMTP credentials.

## Setup Steps

### 1. Install Supabase CLI

```powershell
# Install Supabase CLI using npm
npm install -g supabase
```

### 2. Login to Supabase

```powershell
# Login to your Supabase account
supabase login
```

### 3. Link Your Supabase Project

```powershell
# Navigate to your project directory
cd c:\Users\udula\OneDrive\Documents\apps\deathapp

# Link to your existing Supabase project
supabase link --project-ref hccwunsexiirnuoqgkuu
```

### 4. Get Resend API Key

1. Go to https://resend.com/
2. Sign up for a free account (100 emails/day free tier)
3. Create an API key from the dashboard
4. Copy the API key

### 5. Set Environment Variable in Supabase

```powershell
# Set the Resend API key as a secret in Supabase
supabase secrets set RESEND_API_KEY=re_your_api_key_here
```

### 6. Deploy the Edge Function

```powershell
# Deploy the send-emergency-email function
supabase functions deploy send-emergency-email
```

### 7. Test the Function (Optional)

```powershell
# Test the function locally
supabase functions serve send-emergency-email
```

## How It Works

1. **User clicks DEBUG button** → App calls Supabase Edge Function
2. **Edge Function receives**:
   - `fromEmail`: User's email (from sign-up)
   - `fromName`: User's name (from sign-up)
   - `toEmail`: Contact's email (from People tab)
   - `toName`: Contact's name
   - `message`: Custom message (from People screen)

3. **Edge Function sends email** via Resend API
4. **Email appears** as sent from "onboarding@resend.dev" with reply-to set to user's email
5. **Contact receives** emergency alert with custom message

## Email Format

**Subject:** Emergency Alert - [User Name] needs help

**Body:**
```
🚨 Emergency Alert

[User Name] ([user@email.com]) may need assistance.

[Custom message from People screen]

---
This is an automated emergency alert from the "Are You Dead Yet?" application.
If you have any concerns, please contact [User Name] at [user@email.com].
```

## Important Notes

- **Free Tier**: Resend allows 100 emails/day for free
- **Verified Domain**: To use a custom "from" address, you need to verify a domain in Resend
- **Reply-To**: Recipients can reply directly to the user's email address
- **No User Configuration**: Users don't need to configure anything - it just works!

## Troubleshooting

### Function not found error
```powershell
# Make sure you're linked to the correct project
supabase projects list
supabase link --project-ref hccwunsexiirnuoqgkuu
```

### RESEND_API_KEY not set
```powershell
# Check if secret is set
supabase secrets list

# Set it again if needed
supabase secrets set RESEND_API_KEY=your_key_here
```

### Emails not sending
- Check Resend dashboard for errors
- Verify API key is valid
- Check Edge Function logs: `supabase functions logs send-emergency-email`

## Alternative: Using SendGrid

If you prefer SendGrid over Resend, modify the Edge Function to use SendGrid's API:

```typescript
// Replace Resend API call with SendGrid
const res = await fetch('https://api.sendgrid.com/v3/mail/send', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${SENDGRID_API_KEY}`,
  },
  body: JSON.stringify({
    personalizations: [{ to: [{ email: toEmail }] }],
    from: { email: 'noreply@yourdomain.com', name: fromName },
    reply_to: { email: fromEmail },
    subject: `Emergency Alert - ${fromName} needs help`,
    content: [{ type: 'text/html', value: htmlContent }]
  })
})
```

## Next Steps

After deployment:
1. Rebuild the Flutter app
2. Test the DEBUG button
3. Check console logs for success/error messages
4. Verify emails are received by contacts
