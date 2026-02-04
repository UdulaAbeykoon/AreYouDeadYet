# Complete Backend Setup Guide

## Overview
This guide will help you set up the complete backend for the "Are You Dead Yet?" app using Supabase.

## Prerequisites
- Supabase account (free tier works)
- Resend account for sending emails (free tier: 3000 emails/month)

## Step 1: Set Up Database Schema (5 minutes)

### Option A: Using Supabase Dashboard
1. Go to your Supabase project dashboard
2. Click on "SQL Editor" in the left sidebar
3. Click "New Query"
4. Copy the entire contents of `supabase/migrations/001_initial_schema.sql`
5. Paste into the SQL editor
6. Click "Run" to execute

### Option B: Using Supabase CLI
```bash
# Install Supabase CLI (if not already installed)
npm install -g supabase

# Login to Supabase
npx supabase login

# Link your project
npx supabase link --project-ref YOUR_PROJECT_REF

# Push the migration
npx supabase db push
```

## Step 2: Get Resend API Key (2 minutes)

1. Go to https://resend.com/
2. Sign up for free account
3. Verify your email
4. Go to API Keys section
5. Create a new API key
6. Copy the API key (starts with `re_`)

## Step 3: Deploy Edge Functions (3 minutes)

### Set Environment Variables
```bash
# Set Resend API key
supabase secrets set RESEND_API_KEY=re_your_actual_key_here
```

### Deploy Functions
```bash
# Deploy the check-inactivity function (for automated checks)
npx supabase functions deploy check-inactivity

# Deploy the send-emergency-email function (for manual/DEBUG triggers)
npx supabase functions deploy send-emergency-email
```

## Step 4: Set Up Cron Job (2 minutes)

To automatically check for inactive users every hour:

1. Go to Supabase Dashboard → Database → Extensions
2. Enable the `pg_cron` extension
3. Go to SQL Editor and run:

```sql
-- Schedule the check-inactivity function to run every hour
SELECT cron.schedule(
  'check-inactive-users',
  '0 * * * *', -- Every hour at minute 0
  $$
  SELECT
    net.http_post(
      url:='https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-inactivity',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb
    ) as request_id;
  $$
);
```

Replace:
- `YOUR_PROJECT_REF` with your Supabase project reference
- `YOUR_ANON_KEY` with your Supabase anon key (from Settings → API)

## Step 5: Update Flutter App (5 minutes)

The app needs to be updated to work with the new database schema. Key changes:

1. **Check-in updates** → Update `last_check_in` in `profiles` table
2. **Contacts** → Store in `contacts` table instead of SharedPreferences
3. **Messages** → Store in `user_messages` table
4. **DEBUG button** → Call `send-emergency-email` Edge Function

## How It Works

### Automated Flow (Production)
1. **User checks in** → Updates `last_check_in` in database
2. **Cron job runs hourly** → Calls `check-inactivity` function
3. **Function finds expired users** → Users who haven't checked in for X days
4. **Sends emails** → To all contacts with custom message
5. **Updates status** → Marks user as 'alerted' to prevent duplicates

### Manual Flow (DEBUG Button)
1. **User clicks DEBUG** → Calls `send-emergency-email` function
2. **Function fetches contacts** → From database
3. **Sends test emails** → To all contacts immediately
4. **Returns result** → Shows success/error in app

## Email Details

**From:** Are You Dead Yet? <alerts@resend.dev>  
**Reply-To:** User's email address  
**To:** Contact's email  
**Subject:** Emergency Alert - [User Name] needs help  

## Testing

### Test the DEBUG Button
1. Sign up in the app
2. Add contacts in People tab
3. Set custom message
4. Click DEBUG button in Settings
5. Check contact's inbox for test email

### Test Automated Checks
1. Manually update `last_check_in` to 2 days ago:
```sql
UPDATE profiles 
SET last_check_in = NOW() - INTERVAL '2 days'
WHERE email = 'your-email@example.com';
```

2. Manually trigger the function:
```bash
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-inactivity' \
  -H 'Authorization: Bearer YOUR_ANON_KEY'
```

3. Check if emails were sent

## Troubleshooting

### "Function not found"
→ Make sure you deployed the functions:
```bash
supabase functions list
```

### "Resend API error"
→ Check if API key is set:
```bash
supabase secrets list
```

### "No contacts found"
→ Make sure contacts are in the database, not just SharedPreferences

### Emails not sending
→ Check function logs:
```bash
supabase functions logs check-inactivity
supabase functions logs send-emergency-email
```

## Database Schema Summary

### `profiles` table
- `id`: UUID (links to auth.users)
- `display_name`: User's name
- `email`: User's email (for reply-to)
- `last_check_in`: Timestamp of last check-in
- `alert_threshold_days`: Days before alert (default: 1)
- `status`: 'active', 'alerted', or 'inactive'

### `contacts` table
- `id`: UUID
- `user_id`: FK to profiles
- `contact_name`: Contact's name
- `contact_email`: Contact's email
- `relationship`: Relationship to user

### `user_messages` table
- `user_id`: FK to profiles (primary key)
- `message`: Custom emergency message

## Cost Breakdown

### Free Tier
- **Supabase**: 500MB database, 2GB bandwidth/month
- **Resend**: 3,000 emails/month, 100 emails/day
- **Total**: $0/month for small user base

### Paid (if needed)
- **Supabase Pro**: $25/month (8GB database, 50GB bandwidth)
- **Resend**: $20/month (50,000 emails)

## Next Steps

1. Run the SQL migration
2. Get Resend API key
3. Deploy Edge Functions
4. Set up cron job
5. Update Flutter app to use new schema
6. Test everything!

The backend is now production-ready and will automatically check for inactive users and send emergency emails! 🎉
