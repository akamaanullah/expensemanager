# Firestore Security Rules - Notifications Collection

## Error:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Solution: Add Notifications Collection to Firestore Rules

### Go to Firebase Console:
1. Open: https://console.firebase.google.com/
2. Select project: **expensetracking-df9e8**
3. Go to **Firestore Database** → **Rules** tab

### Complete Updated Rules (Add Notifications Collection):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && (
        request.resource.data.userId == request.auth.uid ||
        (request.resource.data.category == 'Transfer' && 
         request.resource.data.type == 'income')
      );
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.id == request.auth.uid;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isOwner(userId);
    }
    
    // Categories collection
    match /categories/{categoryId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId) && !resource.data.isDefault;
    }
    
    // Loans collection
    match /loans/{loanId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Saved Recipients collection
    match /savedRecipients/{recipientId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // ⭐ NEW: Notifications collection
    match /notifications/{notificationId} {
      // Users can only read their own notifications
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      // Anyone authenticated can create notifications (for transfer notifications)
      allow create: if isAuthenticated();
      // Users can only update their own notifications (mark as read)
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      // Users can only delete their own notifications
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Important Notes:

1. **Notifications Read Access:**
   - Users can only read notifications where `userId` matches their own `uid`
   - This allows the app to listen to notifications for the current user

2. **Notifications Create:**
   - Any authenticated user can create notifications (needed for transfer notifications)
   - The `userId` field in the notification document determines who can read it

3. **Notifications Update/Delete:**
   - Users can only update/delete their own notifications
   - Used for marking notifications as read

## Steps to Apply:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: **expensetracking-df9e8**
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the complete rules above (including notifications collection)
5. Click **"Publish"** button
6. Wait 1-2 minutes for rules to propagate

## After Applying Rules:

- Notification listener will work properly
- Users will receive notifications when money is transferred
- No more permission denied errors


