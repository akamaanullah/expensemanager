# Expense Manager - Firestore Database Schema

## Collections Structure

### 1. **transactions** Collection
Stores all income and expense transactions.

**Document Structure:**
```json
{
  "id": "string (auto-generated)",
  "userId": "string (user ID)",
  "type": "string ('income' or 'expense')",
  "title": "string",
  "description": "string (optional)",
  "amount": "number",
  "category": "string",
  "date": "string (ISO 8601)",
  "createdAt": "string (ISO 8601)",
  "updatedAt": "string (ISO 8601, optional)"
}
```

**Indexes Required:**
- `userId` + `date` (descending)
- `userId` + `type` + `date` (descending)

**Query Examples:**
- Get all transactions for a user: `where('userId', == userId).orderBy('date', desc)`
- Get income transactions: `where('userId', == userId).where('type', == 'income')`
- Get transactions by date range: `where('date', >= startDate).where('date', <= endDate)`

---

### 2. **users** Collection
Stores user profile and preferences.

**Document Structure:**
```json
{
  "id": "string (user ID from Firebase Auth)",
  "email": "string",
  "displayName": "string (optional)",
  "photoUrl": "string (optional)",
  "createdAt": "string (ISO 8601)",
  "lastLoginAt": "string (ISO 8601, optional)",
  "preferences": {
    "currency": "string (default: 'Rs.')",
    "notificationsEnabled": "boolean",
    "biometricEnabled": "boolean"
  }
}
```

**Indexes:** Not required (queries by document ID)

---

### 3. **categories** Collection
Stores user-defined and default categories.

**Document Structure:**
```json
{
  "id": "string (auto-generated)",
  "userId": "string (user ID)",
  "name": "string",
  "type": "string ('income' or 'expense')",
  "icon": "string (icon identifier)",
  "color": "string (hex color, optional)",
  "isDefault": "boolean",
  "createdAt": "string (ISO 8601)"
}
```

**Indexes Required:**
- `userId` + `type` + `name`

**Query Examples:**
- Get income categories: `where('userId', == userId).where('type', == 'income')`
- Get expense categories: `where('userId', == userId).where('type', == 'expense')`

---

## Default Categories

### Income Categories:
1. Salary
2. Freelance
3. Investment
4. Business
5. Gift
6. Rental
7. Other

### Expense Categories:
1. Food
2. Transport
3. Shopping
4. Bills
5. Entertainment
6. Healthcare
7. Education
8. Travel
9. Other

---

## Security Rules (Firestore Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the resource
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
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.resource.data.id == request.auth.uid;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
    
    // Categories collection
    match /categories/{categoryId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId) && !resource.data.isDefault;
    }
  }
}
```

---

## Database Indexes to Create in Firebase Console

1. **transactions** collection:
   - Fields: `userId` (Ascending), `date` (Descending)
   - Fields: `userId` (Ascending), `type` (Ascending), `date` (Descending)

2. **categories** collection:
   - Fields: `userId` (Ascending), `type` (Ascending), `name` (Ascending)

---

## Data Flow

1. **User Registration:**
   - Create user in Firebase Auth
   - Create user document in `users` collection
   - Create default categories in `categories` collection

2. **Add Transaction:**
   - Create transaction document in `transactions` collection
   - Update user totals (calculated on-demand)

3. **View Transactions:**
   - Query `transactions` collection filtered by `userId`
   - Real-time updates via Stream listeners

4. **Update Transaction:**
   - Update transaction document
   - Set `updatedAt` timestamp

5. **Delete Transaction:**
   - Delete transaction document
   - User totals automatically recalculate

---

## Best Practices

1. **Always use userId** to filter queries (security)
2. **Use Streams** for real-time updates
3. **Calculate totals on-demand** instead of storing
4. **Use batch writes** for multiple operations
5. **Index all query fields** to avoid performance issues
6. **Validate data** before writing to Firestore
7. **Use transactions** for critical operations

