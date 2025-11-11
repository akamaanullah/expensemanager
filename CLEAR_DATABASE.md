# Database Empty Karne Ka Guide

## ⚠️ WARNING
**Database empty karne se sab data permanently delete ho jayega. Undo nahi hoga!**

---

## Method 1: Firebase Console Se Manually (Recommended - Safest)

### Steps:

1. **Firebase Console Kholo:**
   - https://console.firebase.google.com/
   - Project: **expensetracking-df9e8**
   - **Firestore Database** → **Data** tab

2. **Har Collection Ko Delete Karein:**

   **Collections:**
   - `transactions` → Sab documents delete
   - `categories` → Sab documents delete
   - `loans` → Sab documents delete
   - `notifications` → Sab documents delete
   - `savedRecipients` → Sab documents delete
   - `users` → ⚠️ **Careful** - Yeh user accounts delete ho jayengi

3. **Collection Delete Karne Ka Process:**
   - Collection par click karo
   - Har document par click karo
   - Delete button click karo
   - Ya collection header par right-click → "Delete collection"

---

## Method 2: Automated Script (Fast)

Main ek utility service bana diya hai jo sab collections ko clear kar sakta hai.

### Usage (Flutter App Se):

```dart
import 'services/database_utility_service.dart';

// Complete database empty (including users)
final utility = DatabaseUtilityService();
await utility.clearAllCollections();

// Ya sirf data clear (users preserve)
await utility.clearAllDataExceptUsers();
```

### Steps:

1. **App mein ek temporary button add karo:**
   - Settings screen mein ya kisi test screen mein
   - Button par click → Confirmation dialog → Database clear

2. **Ya Flutter console se run karo:**
   - App mein ek function call karo
   - Database clear ho jayega

---

## Method 3: Quick Firebase Console Steps

### Fastest Way:

1. Firebase Console → Firestore Database → Data
2. Har collection par click karo
3. Collection dropdown se "Delete collection" select karo
4. Confirm karo

### Collections to Delete:
- ✅ transactions
- ✅ categories  
- ✅ loans
- ✅ notifications
- ✅ savedRecipients
- ✅ users (⚠️ Optional - agar user accounts bhi delete karni hain)

---

## Recommended Approach:

**Testing ke liye:**
1. `users` collection ko **skip** karo (user accounts preserve)
2. Baaki sab collections clear karo

**Complete fresh start:**
1. Sab collections clear karo (including `users`)
2. Phir new accounts register karo

---

## After Clearing:

✅ Database fresh ho jayega
✅ Naye accounts register kar sakte hain
✅ Sab testing data clean ho jayega

**Note:** Agar `users` collection clear ki, to sab users ko phir se register karna hoga.


