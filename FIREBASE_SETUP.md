# Firebase Setup Guide - Fix CONFIGURATION_NOT_FOUND Error

## Step 1: Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `expensetracking-df9e8`
3. Click on **Authentication** in left menu
4. Click **Get Started** (if not already done)
5. Go to **Sign-in method** tab
6. Click on **Email/Password**
7. **Enable** the first toggle (Email/Password)
8. Click **Save**

## Step 2: Add SHA-1 Fingerprint

### Method 1: Using Android Studio
1. Open Android Studio
2. Open your project
3. Click on **Gradle** tab (right side)
4. Navigate to: `app` → `Tasks` → `android` → `signingReport`
5. Double-click on `signingReport`
6. Copy the **SHA1** fingerprint from output console

### Method 2: Using Command Line
```bash
cd android
gradlew signingReport
```
Look for SHA1 fingerprint in the output.

### Method 3: Using Keytool (if you have Java installed)
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## Step 3: Add SHA-1 to Firebase

1. Go to Firebase Console → Project Settings
2. Scroll down to **Your apps** section
3. Click on your Android app (package name: `com.zain.expensemanage`)
4. Click **Add fingerprint**
5. Paste the SHA-1 fingerprint
6. Click **Save**

## Step 4: Download Updated google-services.json

1. In Firebase Console → Project Settings
2. Scroll to **Your apps**
3. Download the **google-services.json** file
4. Replace the existing file in: `android/app/google-services.json`

## Step 5: Rebuild and Run

```bash
flutter clean
flutter pub get
flutter run
```

## Important Notes:

- After adding SHA-1, wait 2-3 minutes for Firebase to update
- Make sure `google-services.json` is in correct location
- Ensure Firebase Authentication is enabled
- Check that your package name matches in Firebase Console

## Troubleshooting:

If still getting error:
1. Double-check Email/Password is enabled in Firebase Console
2. Verify SHA-1 fingerprint is added correctly
3. Make sure you're using the latest `google-services.json`
4. Wait a few minutes after adding SHA-1 for changes to propagate

