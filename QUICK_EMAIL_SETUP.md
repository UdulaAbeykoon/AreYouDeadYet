# QUICK EMAIL SETUP - 5 MINUTES

## What This Does
Sends emails **FROM YOUR EMAIL** to your contacts with your custom message.

## Setup Steps

### 1. Get Free SMTP2GO API Key (2 minutes)

1. Go to: https://www.smtp2go.com/
2. Click "Sign Up Free"
3. Enter your email and create account
4. Verify your email
5. Go to Settings → API Keys
6. Click "Create API Key"
7. Copy the API key (starts with "api-")

### 2. Add API Key to .env File (1 minute)

Open `.env` file and replace:
```
SMTP2GO_API_KEY=your-smtp2go-api-key-here
```

With:
```
SMTP2GO_API_KEY=api-YOUR-ACTUAL-KEY-HERE
```

### 3. Verify Your Sender Email (2 minutes)

1. In SMTP2GO dashboard, go to "Sender Domains"
2. Click "Add Sender"
3. Enter the email you used to sign up in the app
4. Verify it (they'll send you a verification email)

### 4. Done!

Restart the app and click the DEBUG button. Emails will be sent FROM your email TO your contacts!

## How It Works

- **From:** Your email (the one you signed up with)
- **To:** Contact's email (from People tab)
- **Subject:** "Emergency Alert - [Your Name] needs help"
- **Message:** Your custom message from People tab
- **Free Tier:** 1000 emails/month

## Troubleshooting

### "API key not configured"
→ Make sure you added the API key to `.env` file

### "Sender not verified"
→ Verify your email in SMTP2GO dashboard

### Still not working?
→ Check the console for error messages
→ Make sure you restarted the app after adding the API key
