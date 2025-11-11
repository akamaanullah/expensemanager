# Create Second Index for Income/Expense Filter

## Problem:
- "All Transactions" mein sab dikh raha hai ✅
- "Income" filter mein nahi dikh raha ❌
- "Expense" filter mein nahi dikh raha ❌

## Reason:
Ek index already hai (userId + date), lekin filter ke liye ek aur index chahiye (userId + type + date).

## Solution: Create Second Index

### Step 1: Indexes Tab
1. Firebase Console → Firestore Database → **"Indexes"** tab
2. Abhi ek index dikhega: `userId` (↑) + `date` (↓)

### Step 2: Create New Index
1. **"+ Create Index"** ya **"Add index"** button click karein
2. **"Create a composite index"** dialog open hoga

### Step 3: Fill Details (IMPORTANT - Different from first index!)

**Collection ID:**
- Type: `transactions`

**Fields to index:**
1. **Field 1:**
   - Field path: `userId`
   - Order: **Ascending** (↑)
2. **Field 2:**
   - Field path: `type` ⬅️ **YEH IMPORTANT HAI!**
   - Order: **Ascending** (↑)
3. **Field 3:**
   - Field path: `date`
   - Order: **Descending** (↓)

**Query scope:**
- Select: **Collection**

### Step 4: Create
1. **"Create"** button click karein
2. Status: **"Building"** dikhega
3. 2-5 minutes wait karein
4. Status: **"Enabled"** ho jayega

## Difference Between Two Indexes:

**Index 1 (Already exists):**
- `userId` (Ascending)
- `date` (Descending)
- **Use:** All transactions load karne ke liye

**Index 2 (Create karna hai):**
- `userId` (Ascending)
- `type` (Ascending) ⬅️ **YEH EXTRA HAI!**
- `date` (Descending)
- **Use:** Income/Expense filter ke liye

## Quick Link:
Direct to Indexes: https://console.firebase.google.com/project/expensetracking-df9e8/firestore/indexes

## After Creating:
1. Wait 2-5 minutes
2. Status "Enabled" check karein
3. App restart karein
4. Income/Expense filter test karein

