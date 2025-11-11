# Firestore Index Fix

## Error:
```
The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/expensetracking-df9e8/firestore/indexes?create_composite=...
```

## Solution: Create Firestore Index

### Method 1: Direct Link from Terminal (Easiest)

1. Terminal mein error message mein link copy karein
2. Browser mein paste karein
3. **"Create Index"** button click karein
4. Wait 2-5 minutes for index to build
5. Restart your app

### Method 2: Direct Link - Income/Expense Filter Index

**For All Transactions screen filter:**
```
https://console.firebase.google.com/v1/r/project/expensetracking-df9e8/firestore/indexes?create_composite=Clpwcm9qZWN0cy9leHBlbnNldHJhY2tpbmctZGY5ZTgvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3RyYW5zYWN0aW9ucy9pbmRleGVzL18QARoICgR0eXBlEAEaCgoGdXNlcklkEAEaCAoEZGF0ZRACGgwKCF9fbmFtZV9fEAI
```

**For All Transactions (no filter):**
```
https://console.firebase.google.com/v1/r/project/expensetracking-df9e8/firestore/indexes?create_composite=Clpwcm9qZWN0cy9leHBlbnNldHJhY2tpbmctZGY5ZTgvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3RyYW5zYWN0aW9ucy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoICgRkYXRlEAIaDAoIX19uYW1lX18QAg
```

### Method 3: Manual Creation (Step by Step)

**Yeh steps follow karein:**

1. **Firebase Console mein "Indexes" tab par jayein:**
   - Top bar mein tabs: Data, Rules, **Indexes**, etc.
   - **"Indexes"** tab click karein

2. **"+ Create Index" button click karein**

3. **Index settings fill karein:**
   - **Collection ID:** `transactions`
   - **Fields to index:**
     - Field 1: `userId` - **Ascending** (↑)
     - Field 2: `type` - **Ascending** (↑)
     - Field 3: `date` - **Descending** (↓)
   - **Query scope:** Collection

4. **"Create" click karein**

5. **Wait 2-5 minutes** - Status "Building" se "Enabled" ho jayega

**You need to create TWO indexes:**

**Index 1: For All Transactions**
1. Go to [Firebase Console](https://console.firebase.google.com/project/expensetracking-df9e8/firestore)
2. Click on **"Indexes"** tab
3. Click **"Create Index"**
4. Set:
   - **Collection ID:** `transactions`
   - **Fields to index:**
     - `userId` - Ascending
     - `date` - Descending
   - **Query scope:** Collection
5. Click **"Create"**

**Index 2: For Filtered Transactions (Income/Expense)**
1. In same **"Indexes"** tab
2. Click **"Create Index"** again
3. Set:
   - **Collection ID:** `transactions`
   - **Fields to index:**
     - `userId` - Ascending
     - `type` - Ascending
     - `date` - Descending
   - **Query scope:** Collection
4. Click **"Create"**
5. Wait 2-5 minutes for both indexes

### Method 3: Auto-create (When App Runs)

Firestore will automatically prompt you to create indexes when needed. You can:
1. Wait for the error message in terminal
2. Click the link provided
3. Create the index

## Note:

- Index creation takes 2-5 minutes
- Your app will work once index is created
- You might see this error until index is ready

