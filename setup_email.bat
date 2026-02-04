@echo off
echo ========================================
echo  Email Setup for "Are You Dead Yet?"
echo ========================================
echo.

echo Step 1: Installing Supabase CLI...
call npm install -g supabase
if %errorlevel% neq 0 (
    echo ERROR: Failed to install Supabase CLI
    pause
    exit /b 1
)
echo.

echo Step 2: Logging into Supabase...
call supabase login
if %errorlevel% neq 0 (
    echo ERROR: Failed to login to Supabase
    pause
    exit /b 1
)
echo.

echo Step 3: Linking to Supabase project...
call supabase link --project-ref hccwunsexiirnuoqgkuu
if %errorlevel% neq 0 (
    echo ERROR: Failed to link project
    pause
    exit /b 1
)
echo.

echo Step 4: Setting Resend API Key...
echo.
echo Please enter your Resend API Key (get it from https://resend.com/):
set /p RESEND_KEY="API Key: "
call supabase secrets set RESEND_API_KEY=%RESEND_KEY%
if %errorlevel% neq 0 (
    echo ERROR: Failed to set API key
    pause
    exit /b 1
)
echo.

echo Step 5: Deploying Edge Function...
call supabase functions deploy send-emergency-email
if %errorlevel% neq 0 (
    echo ERROR: Failed to deploy function
    pause
    exit /b 1
)
echo.

echo ========================================
echo  Setup Complete!
echo ========================================
echo.
echo The email system is now ready to use.
echo Users can send emergency alerts from their own email addresses.
echo.
pause
