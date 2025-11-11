#!/bin/bash

# Deploy Firebase Cloud Functions
# Make sure you have Node.js and Firebase CLI installed

echo "🚀 Deploying Firebase Cloud Functions..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Installing..."
    npm install -g firebase-tools
fi

# Navigate to functions directory
cd functions

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Go back to root
cd ..

# Deploy functions
echo "☁️ Deploying to Firebase..."
firebase deploy --only functions

echo "✅ Deployment complete!"
echo "📝 Check function logs: firebase functions:log"

