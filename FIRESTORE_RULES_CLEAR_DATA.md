# Firestore Rules - Clear All Data Fix

## Error:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Problem:
Firestore security rules mein batch delete operations ke liye proper permissions nahi hain.

## Solution:
Firebase Console mein Firestore rules update karein:

### Step 1: Firebase Console mein jayen
1. https://console.firebase.google.com/ open karein
2. Project select karein: **expensetracking-df9e8**
3. **Firestore Database** → **Rules** tab par jayen

### Step 2: Complete Rules Update Karein

Yeh complete rules copy karein aur Firebase Console mein paste karein:

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
    
    // Saved Recipients collection
    match /savedRecipients/{recipientId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Notifications collection
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

### Step 3: Rules Publish Karein
1. Rules paste karne ke baad **"Publish"** button click karein
2. Rules update hone mein 1-2 minutes lag sakte hain

### Important Notes:
- ✅ **allow delete** rules har collection mein properly set hain
- ✅ Batch delete operations ab properly allowed hain
- ✅ User sirf apni hi data delete kar sakta hai
- ⚠️ Rules update hone ke baad app restart karein

### Testing:
1. App restart karein
2. Settings screen par jayen
3. "Clear All Data" option try karein
4. Ab error nahi aana chahiye

## Code Changes:
- `deleteAllUserData` method ko improve kiya gaya hai
- Ab yeh batches mein delete karta hai (500 documents per batch)
- Saved recipients aur notifications bhi delete ho jayenge
- Firestore batch limit (500) ko handle kar raha hai

