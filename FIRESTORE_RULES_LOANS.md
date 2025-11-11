# Firestore Security Rules - Loans Collection Fix

## Error:
```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
Error fetching loan persons: [cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## Solution: Update Firestore Security Rules

### Step 1: Go to Firebase Console
1. Open: https://console.firebase.google.com/
2. Select project: **expensetracking-df9e8**
3. Go to **Firestore Database** → **Rules** tab

### Step 2: Add Loans Collection Rules

Aapke existing rules mein **loans collection** ke liye rules add karein:

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
    
    // ⭐ NEW: Loans collection
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
1. App restart karein (hot restart)
2. Loans screen open karein
3. Ab error nahi aana chahiye

## Important Notes:
- Rules update hone mein 1-2 minutes lag sakte hain
- Loans collection ke liye same security pattern use kiya gaya hai jaise transactions aur categories ke liye
- User sirf apne hi loans dekh sakta hai, create kar sakta hai, update kar sakta hai, aur delete kar sakta hai

## Quick Steps:
1. Firebase Console → Firestore Database → Rules
2. Upar wali complete rules copy karein
3. Publish karein
4. 1-2 minutes wait karein
5. App restart karein



