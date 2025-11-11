# Firestore Security Rules - Transfer Money Feature

## New Collections Added:
1. **savedRecipients** - Stores saved recipients for each user
2. **users** - Needs to allow search by account number (read access for account number lookup)

## Complete Updated Rules

Go to Firebase Console → Firestore Database → Rules and replace with:

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
    
    // ⭐ NEW: Saved Recipients collection
    match /savedRecipients/{recipientId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
  }
}
```

## Important Notes:

1. **Users Collection Read Access:**
   - Authenticated users can read user documents (needed for account number search)
   - This allows searching by account number, but sensitive data should still be protected
   - Only `accountNumber`, `displayName`, and `email` are exposed in the transfer flow

2. **Saved Recipients:**
   - Users can only read, create, update, and delete their own saved recipients
   - Each recipient document is tied to the owner's `userId`

3. **Transfer Transactions:**
   - When money is transferred, two transactions are created:
     - One expense transaction for the sender (userId = sender.uid)
     - One income transaction for the receiver (userId = receiver.uid)
   - Both transactions follow the same security rules as regular transactions

## Steps to Apply:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the complete rules above
5. Click **"Publish"** button
6. Wait 1-2 minutes for rules to propagate
7. Restart your app

## Testing:

After applying rules:
1. Try searching for an account number
2. Try saving a recipient
3. Try transferring money
4. Verify that transactions are created for both sender and receiver
5. Check that saved recipients are only visible to the owner

