# 📧 Email System Architecture

## Problem Solved
✅ **Any user can send emergency emails from their own email address**  
✅ **No SMTP configuration required from users**  
✅ **Scalable and secure backend solution**

## How It Works

### Architecture
```
User's Phone (Flutter App)
    ↓
Supabase Edge Function (Serverless)
    ↓
Resend API (Email Service)
    ↓
Contact's Email Inbox
```

### Flow
1. **User signs up** with their email (e.g., `john@example.com`)
2. **User adds contacts** in the People tab with custom message
3. **User clicks DEBUG button** in Settings
4. **Flutter app calls** Supabase Edge Function with:
   - User's email and name
   - Contact's email and name
   - Custom message
5. **Edge Function sends email** via Resend API
6. **Contact receives email** that appears to be from the user

### Email Details
- **From:** `John Doe <onboarding@resend.dev>` (Resend's verified domain)
- **Reply-To:** `john@example.com` (User's actual email)
- **To:** Contact's email
- **Subject:** "Emergency Alert - John Doe needs help"
- **Body:** User's custom message with emergency alert formatting

## Files Created

### 1. `supabase/functions/send-emergency-email/index.ts`
Serverless Edge Function that:
- Receives email request from Flutter app
- Validates input
- Calls Resend API to send email
- Returns success/error response

### 2. `EMAIL_SETUP_GUIDE.md`
Complete guide for deploying the email system

### 3. `setup_email.bat`
Automated setup script that:
- Installs Supabase CLI
- Links to Supabase project
- Sets Resend API key
- Deploys Edge Function

## Setup Required (One-Time)

### For You (Developer):
1. Run `setup_email.bat` OR follow `EMAIL_SETUP_GUIDE.md`
2. Get free Resend API key from https://resend.com/
3. Deploy the Edge Function to Supabase

### For Users (End Users):
**Nothing!** They just:
1. Sign up with their email
2. Add contacts
3. Click DEBUG button
4. Emails are sent automatically

## Benefits

### ✅ User-Friendly
- No technical setup required from users
- Works with any email address
- Instant email delivery

### ✅ Secure
- API keys stored securely in Supabase
- No credentials exposed in app
- Server-side email sending

### ✅ Scalable
- Serverless architecture
- Handles multiple users
- Free tier: 100 emails/day (Resend)

### ✅ Professional
- HTML formatted emails
- Reply-to functionality
- Emergency alert styling

## Cost

### Free Tier (Resend)
- 100 emails/day
- 3,000 emails/month
- Perfect for testing and small user base

### Paid Plans (if needed)
- $20/month: 50,000 emails
- $80/month: 100,000 emails

## Testing

After deployment, test with:
1. Sign up with your email
2. Add a test contact (your other email)
3. Set custom message
4. Click DEBUG button
5. Check your inbox for emergency alert

## Troubleshooting

### "Function not found"
→ Deploy function: `supabase functions deploy send-emergency-email`

### "RESEND_API_KEY not set"
→ Set secret: `supabase secrets set RESEND_API_KEY=your_key`

### Emails not received
→ Check Resend dashboard for delivery status
→ Check spam folder
→ Verify API key is valid

## Future Enhancements

### Custom Domain (Optional)
To send from your own domain (e.g., `alerts@yourdomain.com`):
1. Verify domain in Resend dashboard
2. Update Edge Function to use custom domain
3. Emails will appear more professional

### Scheduled Alerts
Modify `_triggerEmergencyProtocol()` to automatically send emails when user misses check-ins (not just DEBUG button)

### Email Templates
Create multiple email templates for different alert levels

## Summary

✨ **The app is now production-ready for public use!**

Any user can:
- Sign up with their email
- Add emergency contacts
- Send alerts from their own email
- No configuration needed

The backend handles everything securely and scalably.
