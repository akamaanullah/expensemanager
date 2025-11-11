# Firestore Database Setup Guide

## Issue:
Registration successful hai Firebase Auth mein, lekin Firestore API disabled hai isliye user data save nahi ho raha.

## Solution:

### Step 1: Enable Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `expensetracking-df9e8`
3. Click on **Firestore Database** in left menu
4. Click **Create database**
5. Choose **Production mode** (we'll add security rules later)
6. Select location (choose closest to you)
7. Click **Enable**

### Step 2: Enable Cloud Firestore API

1. Go to: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=expensetracking-df9e8
2. Or manually:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select project: `expensetracking-df9e8`
   - Go to **APIs & Services** → **Library**
   - Search for "Cloud Firestore API"
   - Click **Enable**

### Step 3: Add Security Rules

1. In Firebase Console → Firestore Database
2. Go to **Rules** tab
3. Replace with these rules:

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
    
    // Users
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.id == request.auth.uid;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Categories
    match /categories/{categoryId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId) && !resource.data.isDefault;
    }
  }
}
```

4. Click **Publish**

### Step 4: Create Indexes (Optional but Recommended)

Go to **Indexes** tab and create these:

1. **transactions** collection:
   - Fields: `userId` (Ascending), `date` (Descending)

2. **transactions** collection:
   - Fields: `userId` (Ascending), `type` (Ascending), `date` (Descending)

3. **categories** collection:
   - Fields: `userId` (Ascending), `type` (Ascending), `name` (Ascending)

### Step 5: Wait and Retry

After enabling Firestore API, wait 2-3 minutes for it to propagate, then try registration again.

## Quick Link:
Enable Firestore API: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=expensetracking-df9e8

