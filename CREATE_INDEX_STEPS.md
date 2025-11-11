# How to Create Firestore Index - Step by Step

## Current Error:
All Transactions screen mein Income/Expense filter ke liye index chahiye.

## Solution: Create Index in Firebase Console

### Step 1: Go to Indexes Tab

1. Firebase Console mein aap abhi "Data" tab par hain
2. Top bar mein tabs dekhein: **Data**, **Rules**, **Indexes**, etc.
3. **"Indexes"** tab par click karein

### Step 2: Create Index

1. **"Indexes"** tab open hoga
2. Top right mein **"+ Create Index"** ya **"Create Index"** button dikhega
3. Click karein

### Step 3: Fill Index Details

**Collection ID:**
- Type: `transactions`

**Fields to index:**
1. Click **"Add field"** ya **"+"** button
2. Field 1:
   - Field path: `userId`
   - Order: **Ascending** (↑)
3. Click **"Add field"** again
4. Field 2:
   - Field path: `type`
   - Order: **Ascending** (↑)
5. Click **"Add field"** again
6. Field 3:
   - Field path: `date`
   - Order: **Descending** (↓)

**Query scope:**
- Select: **Collection**

### Step 4: Create

1. **"Create"** button click karein
2. Index building start hoga
3. Status: **"Building"** dikhega
4. 2-5 minutes wait karein
5. Status: **"Enabled"** ho jayega

### Step 5: Verify

1. Indexes list mein check karein
2. Agar **"Enabled"** status dikhe, to ready hai
3. App restart karein
4. All Transactions screen test karein

## Quick Link:

**Direct to Indexes Tab:**
https://console.firebase.google.com/project/expensetracking-df9e8/firestore/indexes

## Index Details Summary:

**Collection:** `transactions`
**Fields:**
- `userId` (Ascending)
- `type` (Ascending) 
- `date` (Descending)

**Query scope:** Collection

## Note:

- Index creation 2-5 minutes lagta hai
- Building status mein wait karein
- Enabled hone ke baad automatically kaam karega
- Agar pehle se ek index hai (userId + date), to ab ek aur chahiye (userId + type + date)

