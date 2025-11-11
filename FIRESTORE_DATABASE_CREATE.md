# Firestore Database Create - Quick Fix

## Error:
```
The database (default) does not exist for project expensetracking-df9e8
```

## Solution: Create Firestore Database

### Step 1: Go to Firebase Console

1. Open: https://console.firebase.google.com/
2. Select your project: **expensetracking-df9e8**

### Step 2: Create Firestore Database

1. Click on **"Firestore Database"** in the left sidebar menu
2. Click **"Create database"** button
3. **Choose mode:**
   - For testing: Choose **"Start in test mode"** (Allows read/write for 30 days)
   - For production: Choose **"Start in production mode"** (Requires security rules)
4. **Select location:**
   - Choose region closest to you (e.g., `asia-south1` for India, `us-central` for US)
   - **Important:** Location cannot be changed later!
5. Click **"Enable"**
6. Wait 2-3 minutes for database to be created

### Step 3: Add Security Rules (If Production Mode)

1. In Firestore Database page, click on **"Rules"** tab
2. Replace the rules with:

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

3. Click **"Publish"**

### Step 4: Create Indexes (Important!)

Firestore will automatically prompt you to create indexes when you use the app. But you can create them manually:

1. Go to **"Indexes"** tab in Firestore Database
2. Click **"Create Index"**
3. Create these indexes:

**Index 1:**
- Collection: `transactions`
- Fields:
  - `userId` (Ascending)
  - `date` (Descending)
- Query scope: Collection

**Index 2:**
- Collection: `transactions`
- Fields:
  - `userId` (Ascending)
  - `type` (Ascending)
  - `date` (Descending)
- Query scope: Collection

**Index 3:**
- Collection: `categories`
- Fields:
  - `userId` (Ascending)
  - `type` (Ascending)
  - `name` (Ascending)
- Query scope: Collection

### Step 5: Test the App

1. Wait 2-3 minutes after creating database
2. Restart your Flutter app
3. Try adding a transaction or updating profile
4. Check if data appears in Firestore Console → Data tab

### Quick Links:

- **Firebase Console:** https://console.firebase.google.com/project/expensetracking-df9e8/firestore
- **Create Database Direct:** https://console.firebase.google.com/project/expensetracking-df9e8/firestore/databases/-default-/rules

## Troubleshooting:

- **Still getting error?** Wait 5-10 minutes and try again
- **Test mode not working?** Make sure you're logged in to Firebase Auth
- **Production mode errors?** Check security rules are published

