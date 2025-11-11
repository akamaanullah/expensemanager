# Deploy Firebase Cloud Functions

## Prerequisites

1. **Install Node.js** (v18 or higher)
   - Download from: https://nodejs.org/
   - Verify: `node --version`

2. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

3. **Login to Firebase**
   ```bash
   firebase login
   ```

4. **Initialize Firebase in your project** (if not already done)
   ```bash
   firebase init
   ```
   - Select "Functions"
   - Use existing project or create new
   - Select JavaScript
   - Install dependencies? Yes

## Deploy Functions

1. **Install dependencies:**
   ```bash
   cd functions
   npm install
   cd ..
   ```

2. **Deploy functions:**
   ```bash
   firebase deploy --only functions
   ```

   Or deploy specific function:
   ```bash
   firebase deploy --only functions:sendTransferNotification
   ```

## Testing

1. **Test locally (optional):**
   ```bash
   firebase emulators:start --only functions
   ```

2. **Check function logs:**
   ```bash
   firebase functions:log
   ```

3. **Monitor in Firebase Console:**
   - Go to Firebase Console → Functions
   - View logs and execution metrics

## Function Details

### sendTransferNotification
- **Trigger:** When a new document is created in `notifications` collection
- **Action:** Sends push notification to receiver's device
- **Data:** Includes amount, sender name, account number

### cleanupOldNotifications
- **Trigger:** Daily at midnight
- **Action:** Deletes notifications older than 30 days
- **Purpose:** Keeps Firestore clean

## Troubleshooting

### Error: "functions directory not found"
- Make sure you're in the project root directory
- Check that `functions/` folder exists

### Error: "Permission denied"
- Run `firebase login` again
- Check Firebase project permissions

### Error: "Module not found"
- Run `npm install` in the `functions/` directory

### Notifications not received
- Check FCM token is saved in user document
- Verify Firebase Cloud Messaging is enabled in Firebase Console
- Check function logs for errors
- Verify Android/iOS notification permissions

