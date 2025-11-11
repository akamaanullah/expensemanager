@echo off
REM Deploy Firebase Cloud Functions for Windows
REM Make sure you have Node.js and Firebase CLI installed

echo 🚀 Deploying Firebase Cloud Functions...

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    exit /b 1
)

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Firebase CLI is not installed. Installing...
    npm install -g firebase-tools
)

REM Navigate to functions directory
cd functions

REM Install dependencies
echo 📦 Installing dependencies...
call npm install

REM Go back to root
cd ..

REM Deploy functions
echo ☁️ Deploying to Firebase...
call firebase deploy --only functions

echo ✅ Deployment complete!
echo 📝 Check function logs: firebase functions:log

pause

