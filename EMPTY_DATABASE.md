# Firestore Database Empty Karne Ka Guide

## Method 1: Firebase Console Se Manually (Recommended - Safe)

### Step 1: Firebase Console Kholo
1. https://console.firebase.google.com/
2. Project select karo: **expensetracking-df9e8**
3. **Firestore Database** → **Data** tab

### Step 2: Har Collection Ko Delete Karein

**Collections jo delete karni hain:**
- ✅ categories
- ✅ loans
- ✅ notifications
- ✅ savedRecipients
- ✅ transactions
- ✅ users (⚠️ Careful - yeh user accounts delete ho jayengi)

### Step 3: Collection Delete Karne Ka Process

**Option A: Individual Documents Delete**
1. Collection select karo (e.g., `transactions`)
2. Har document par click karo
3. Delete button click karo
4. Repeat for all documents

**Option B: Collection Delete (Faster)**
1. Collection par right-click karo
2. "Delete collection" option select karo
3. Confirm karo

### Step 4: Verify
- Sab collections empty ho jayengi
- Database fresh ho jayega

---

## Method 2: Automated Script (Fast but Dangerous)

Agar bulk delete karna hai, to main ek utility function bana sakta hoon jo sab collections ko clear kar de.

**⚠️ Warning:**
- Ye sab data permanently delete kar dega
- Undo nahi hoga
- Production database par use mat karo

---

## Quick Steps (Firebase Console):

1. **Firestore Database** → **Data** tab
2. **transactions** collection → Delete all documents
3. **categories** collection → Delete all documents
4. **loans** collection → Delete all documents
5. **notifications** collection → Delete all documents
6. **savedRecipients** collection → Delete all documents
7. **users** collection → Delete all documents (⚠️ Careful)

**Note:** Agar sirf testing data delete karna hai, to `users` collection ko skip kar sakte hain.


