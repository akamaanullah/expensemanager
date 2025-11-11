# Firebase Storage Setup Guide

## Error:
```
StorageException: Object does not exist at location
Code: -13010 HttpResult: 404
The server has terminated the upload session
```

## Solution: Enable Firebase Storage

### Step 1: Go to Firebase Console

1. Open: https://console.firebase.google.com/
2. Select your project: **expensetracking-df9e8**

### Step 2: Enable Firebase Storage

1. Click on **"Storage"** in the left sidebar menu
2. If you see "Get started" or "Create bucket", click it
3. **Choose mode:**
   - **"Start in test mode"** (for testing - allows uploads for 30 days)
   - OR **"Start in production mode"** (requires security rules)
4. **Select location:**
   - Choose the same location as Firestore (e.g., `asia-south1`)
   - OR choose closest to you
5. Click **"Done"** or **"Enable"**
6. Wait 2-3 minutes for Storage to be set up

### Step 3: Add Security Rules (If Production Mode)

1. In Storage page, click on **"Rules"** tab
2. Replace the rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Profile pictures
    match /profile_pictures/{userId}.jpg {
      allow read: if true; // Anyone can read profile pictures
      allow write: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Transaction attachments (for future use)
    match /transaction_attachments/{userId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isAuthenticated() && request.auth.uid == userId;
    }
  }
}
```

3. Click **"Publish"**

### Step 4: Test Image Upload

1. Wait 2-3 minutes after enabling Storage
2. Restart your Flutter app
3. Try uploading a profile picture
4. Check Storage Console → Files tab - image should appear

### Quick Links:

- **Firebase Storage Console:** https://console.firebase.google.com/project/expensetracking-df9e8/storage
- **Direct Setup:** https://console.firebase.google.com/project/expensetracking-df9e8/storage/rules

## Troubleshooting:

- **Still getting 404 error?** Wait 5-10 minutes and try again
- **Test mode not working?** Make sure you're logged in to Firebase Auth
- **Production mode errors?** Check security rules are published
- **Bucket not found?** Make sure Storage is enabled in Firebase Console

## Important Notes:

1. **Storage Location:** Choose same region as Firestore for better performance
2. **Test Mode:** Allows unrestricted access for 30 days (good for development)
3. **Production Mode:** Requires proper security rules (good for production)

