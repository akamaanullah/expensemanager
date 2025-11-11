# Notification Setup Guide

## ✅ Complete Implementation

1. **Firebase Messaging Package Added** - `firebase_messaging: ^15.1.3`
2. **FCM Token Storage** - User model mein `fcmToken` field add kiya gaya
3. **Notification Service** - `NotificationService` class create ki gayi
4. **Transfer Notification** - Transfer hone par notification document create hota hai
5. **FCM Initialization** - App start aur login par FCM token automatically save hota hai
6. **Firebase Cloud Functions** - Complete setup with automatic push notifications
7. **Android Configuration** - Notification permissions and FCM service configured
8. **Foreground/Background Handlers** - Complete message handling setup

## 📋 Current Implementation

### Notification Document Structure
Jab transfer hota hai, Firestore mein ek notification document create hota hai:
```javascript
{
  userId: 'receiver_user_id',
  title: 'Money Received',
  body: 'You have received PKR 100.00 from John Doe (ACC-1234-5678-9012)',
  type: 'transfer_received',
  senderName: 'John Doe',
  senderAccountNumber: 'ACC-1234-5678-9012',
  amount: 100.00,
  currency: 'PKR',
  timestamp: '2024-01-01T12:00:00Z',
  read: false,
  fcmToken: 'receiver_fcm_token'
}
```

## 🚀 Push Notifications Setup

### ✅ Firebase Cloud Functions (Already Created!)

**Files Created:**
- `firebase.json` - Firebase configuration
- `functions/index.js` - Cloud Functions code
- `functions/package.json` - Dependencies
- `functions/.eslintrc.js` - Linting rules

**Functions Implemented:**
1. **sendTransferNotification** - Automatically sends push notification when transfer happens
2. **cleanupOldNotifications** - Daily cleanup of old notifications

### 🚀 Deploy Functions

**Quick Deploy (Windows):**
```bash
deploy-functions.bat
```

**Quick Deploy (Mac/Linux):**
```bash
chmod +x deploy-functions.sh
./deploy-functions.sh
```

**Manual Deploy:**
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 📋 Deployment Steps

1. **Install Node.js** (v18 or higher)
   - Download from: https://nodejs.org/

2. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

3. **Login to Firebase:**
   ```bash
   firebase login
   ```

4. **Deploy Functions:**
   ```bash
   firebase deploy --only functions
   ```

### 📝 Cloud Function Details

**sendTransferNotification Function:**
   ```javascript
   // functions/index.js
   const functions = require('firebase-functions');
   const admin = require('firebase-admin');
   admin.initializeApp();

   exports.sendTransferNotification = functions.firestore
     .document('notifications/{notificationId}')
     .onCreate(async (snap, context) => {
       const notification = snap.data();
       
       const message = {
         notification: {
           title: notification.title,
           body: notification.body,
         },
         token: notification.fcmToken,
         data: {
           type: notification.type,
           amount: notification.amount.toString(),
           currency: notification.currency,
           senderName: notification.senderName,
           senderAccountNumber: notification.senderAccountNumber,
         },
       };

       try {
         await admin.messaging().send(message);
         console.log('Notification sent successfully');
       } catch (error) {
         console.error('Error sending notification:', error);
       }
     });
   ```

4. **Deploy Function:**
   ```bash
   firebase deploy --only functions
   ```

### Option 2: Backend Server (Node.js/Express)

1. **Install dependencies:**
   ```bash
   npm install firebase-admin express
   ```

2. **Create API endpoint:**
   ```javascript
   const admin = require('firebase-admin');
   admin.initializeApp();

   app.post('/send-notification', async (req, res) => {
     const { fcmToken, title, body, data } = req.body;
     
     const message = {
       notification: { title, body },
       token: fcmToken,
       data: data,
     };

     try {
       await admin.messaging().send(message);
       res.json({ success: true });
     } catch (error) {
       res.status(500).json({ error: error.message });
     }
   });
   ```

3. **Update NotificationService:**
   Replace `sendTransferNotification` method to call your API instead of creating Firestore document.

## 📱 Android Setup

1. **Update `android/app/build.gradle`:**
   ```gradle
   android {
       defaultConfig {
           // ... existing code
           minSdkVersion 21  // Required for FCM
       }
   }
   ```

2. **Add to `AndroidManifest.xml`:**
   ```xml
   <manifest>
       <application>
           <!-- ... existing code -->
           <service
               android:name="com.google.firebase.messaging.FirebaseMessagingService"
               android:exported="false">
               <intent-filter>
                   <action android:name="com.google.firebase.MESSAGING_EVENT" />
               </intent-filter>
           </service>
       </application>
   </manifest>
   ```

## 🍎 iOS Setup

1. **Enable Push Notifications in Xcode:**
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Go to "Signing & Capabilities"
   - Click "+ Capability" and add "Push Notifications"

2. **Add to `ios/Runner/Info.plist`:**
   ```xml
   <key>FirebaseAppDelegateProxyEnabled</key>
   <false/>
   ```

3. **Update `ios/Runner/AppDelegate.swift`:**
   ```swift
   import UIKit
   import Flutter
   import FirebaseCore
   import FirebaseMessaging

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       FirebaseApp.configure()
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

## 🔔 Testing

1. **Check FCM Token:**
   - Login karke check karo ke FCM token save ho raha hai ya nahi
   - Firestore `users` collection mein `fcmToken` field check karo

2. **Send Test Notification:**
   - Transfer karo
   - Firestore `notifications` collection mein notification document check karo
   - Cloud Function deploy karke push notification test karo

## ✅ Complete Setup Status

### ✅ Implemented:
- ✅ Firebase Cloud Functions created and ready to deploy
- ✅ Android notification permissions configured
- ✅ FCM token management
- ✅ Foreground/background message handlers
- ✅ Notification service integrated
- ✅ Transfer notification triggers

### 📋 To Complete:

1. **Deploy Cloud Functions:**
   ```bash
   firebase deploy --only functions
   ```

2. **Test Notifications:**
   - Send a transfer from one account to another
   - Check if receiver gets push notification
   - Verify in Firebase Console → Functions → Logs

3. **iOS Setup (if deploying to iOS):**
   - Follow iOS setup steps above
   - Enable Push Notifications capability

## 🔔 How It Works

1. **User Login** → FCM token automatically saved to Firestore
2. **Transfer Money** → Notification document created in Firestore
3. **Cloud Function Triggered** → Push notification sent to receiver
4. **Receiver Gets Notification** → "You have received PKR X from Name (ACC-XXXX)"

## 📝 Notes

- **Push Notifications:** Cloud Functions automatically send push notifications
- **Token Refresh:** FCM token automatically refresh hota hai
- **Cleanup:** Old notifications automatically deleted after 30 days
- **Error Handling:** Notification failures don't block transfers

## 🎯 Testing

1. Deploy functions: `firebase deploy --only functions`
2. Login two different users on different devices
3. Send transfer from one to another
4. Receiver should get push notification immediately

## 📞 Support

If notifications don't work:
1. Check Firebase Console → Functions → Logs for errors
2. Verify FCM token is saved in user document
3. Check notification permissions on device
4. Verify Cloud Functions are deployed

