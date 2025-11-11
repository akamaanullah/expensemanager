# Firestore Security Rules Fix - Permission Denied Error

## Error:
```
[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Solution: Update Firestore Security Rules

### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com/
2. Select project: **expensetracking-df9e8**
3. Go to **Firestore Database** → **Rules** tab

### Step 2: Update Security Rules

Replace existing rules with these (aur properly update karein):

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
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Users collection - IMPORTANT: Allow update for preferences
    match /users/{userId} {
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
  }
}
```

### Step 3: Publish Rules
1. Click **"Publish"** button
2. Wait 1-2 minutes for rules to propagate

### Step 4: Test
1. App restart karein
2. Settings → Currency change karein
3. Ab error nahi aana chahiye

## Alternative: Simpler Rules (For Testing)

Agar upar wala kaam nahi kare, to temporarily simpler rules use karein (testing ke liye):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Transactions
    match /transactions/{transactionId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Users - Allow authenticated users to update their own document
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.id == request.auth.uid;
      allow update: if isAuthenticated() && request.auth.uid == userId;
      allow delete: if isOwner(userId);
    }
    
    // Categories
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
  }
}
```

## Important Notes:
- Rules update hone mein 1-2 minutes lag sakte hain
- Production mein proper security rules use karein
- Testing ke liye simpler rules use kar sakte hain

