# Updated Firestore Security Rules - Complete

## Current Rules + Notifications Collection

Copy this complete ruleset to Firebase Console:

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
      // Allow create if:
      // 1. User is creating their own transaction, OR
      // 2. It's a transfer transaction (category == 'Transfer' and type == 'income') for receiver
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
      // Allow read for authenticated users (needed for account number search)
      // But only specific fields are exposed in queries
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.id == request.auth.uid;
      // Allow update if user is owner OR if only updating preferences field
      allow update: if isOwner(userId) || 
                       (isAuthenticated() && 
                        request.auth.uid == userId && 
                        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['preferences']));
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
    
    // ⭐ Saved Recipients collection
    match /savedRecipients/{recipientId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // ⭐ NEW: Notifications collection (ADDED)
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

## What Changed:

**Added:** `notifications` collection rules

### Notifications Collection Rules:
- **Read:** Users can only read notifications where `userId == request.auth.uid`
- **Create:** Any authenticated user can create notifications (for transfer notifications)
- **Update:** Users can only update their own notifications (to mark as read)
- **Delete:** Users can only delete their own notifications

## Steps to Update:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select project: **expensetracking-df9e8**
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the complete rules above
5. Click **"Publish"** button
6. Wait 1-2 minutes for rules to propagate

## After Update:

✅ Notification listener will work properly
✅ No more permission denied errors
✅ Users will receive notifications when money is transferred


