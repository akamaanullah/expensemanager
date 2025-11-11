# Troubleshooting: Clear All Data Not Working

## 🔍 Debugging Steps:

### Step 1: Check Console Logs
App run karte waqt console mein detailed logs dikhenge:
- `🗑️ Starting deleteAllUserData for userId: ...`
- `✅ User authenticated: ...`
- `📝 Deleting transactions...`
- etc.

**Agar koi step fail ho raha hai, woh log mein dikhega.**

### Step 2: Check Firebase Rules Status

1. Firebase Console mein jayen: https://console.firebase.google.com/
2. Project: **expensetracking-df9e8**
3. **Firestore Database** → **Rules** tab
4. Check karein ke rules properly published hain

**Important:** Rules editor mein rules dikh rahi hain, lekin **"Publish" button click kiya hai ya nahi?**
- Agar nahi kiya, toh **"Publish"** button click karein
- Rules publish hone ke baad 2-3 minutes wait karein

### Step 3: Verify Rules Content

Rules mein yeh sab collections ke liye `allow delete` hona chahiye:

```javascript
✅ Transactions: allow delete: if isOwner(resource.data.userId);
✅ Categories: allow delete: if isOwner(resource.data.userId) && !resource.data.isDefault;
✅ Loans: allow delete: if isOwner(resource.data.userId);
✅ Saved Recipients: allow delete: if isOwner(resource.data.userId);
✅ Notifications: allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
✅ Users: allow delete: if isOwner(userId);
```

### Step 4: Check Authentication

App mein login ho kar check karein:
1. Settings screen par jayen
2. User logged in hai ya nahi verify karein
3. Agar logged out hain, toh login karein

### Step 5: Check Error Message

Agar error aa raha hai, toh exact error message check karein:

**Common Errors:**

1. **`permission-denied`**
   - **Cause:** Rules publish nahi hui hain ya rules mein issue hai
   - **Fix:** Rules publish karein (Step 2)

2. **`User not authenticated`**
   - **Cause:** User logged out hai
   - **Fix:** App mein login karein

3. **`userId mismatch`**
   - **Cause:** Current user aur userId match nahi kar rahe
   - **Fix:** App restart karein aur phir try karein

4. **`Firestore error (permission-denied)`**
   - **Cause:** Specific collection ke liye permission nahi hai
   - **Fix:** Rules check karein (Step 3)

### Step 6: Test with Console Logs

1. App run karein (debug mode)
2. Settings → "Clear All Data" click karein
3. Console mein logs check karein:
   ```
   🗑️ Starting deleteAllUserData for userId: ...
   ✅ User authenticated: ...
   📝 Deleting transactions...
   ```

**Agar koi step fail ho raha hai:**
- Console mein exact error dikhega
- Error message copy karein
- Firebase Console mein rules double-check karein

### Step 7: Manual Rules Test

Firebase Console mein Rules Simulator use karein:

1. **Firestore Database** → **Rules** tab
2. **"Rules Playground"** (ya "Simulator") click karein
3. Test scenario:
   - **Location:** `transactions/{transactionId}`
   - **Operation:** Delete
   - **Authenticated:** Yes
   - **User ID:** Apna user ID
   - **Resource Data:** `{ userId: "your-user-id" }`
4. **"Run"** click karein
5. Result check karein - **"Allow"** hona chahiye

### Step 8: Common Issues & Solutions

#### Issue 1: Rules Not Published
**Symptom:** Permission denied error
**Solution:** Rules editor mein **"Publish"** button click karein

#### Issue 2: Rules Syntax Error
**Symptom:** Rules validate nahi ho rahi
**Solution:** 
- Rules mein syntax check karein
- All brackets properly closed hain
- No extra commas or semicolons

#### Issue 3: Cache Issue
**Symptom:** Rules publish ki, lekin abhi bhi error
**Solution:**
- App completely close karein
- 5-10 minutes wait karein (rules propagate hone mein time lagta hai)
- App restart karein

#### Issue 4: Default Categories
**Symptom:** Categories delete nahi ho rahi
**Solution:** Rules mein `!resource.data.isDefault` check hai - default categories delete nahi hongi (yeh expected behavior hai)

### Step 9: Verify Rules Are Active

1. Firebase Console → Firestore Database → Rules
2. Rules editor mein jo rules hain, woh **exactly** `FIREBASE_RULES_VERIFIED.txt` file se match karni chahiye
3. **"Publish"** button par check karein - agar grayed out hai, matlab rules already published hain
4. Agar red/active hai, matlab changes publish nahi hui hain

### Step 10: Final Checklist

- [ ] Firebase Console mein rules properly set hain
- [ ] Rules **PUBLISH** ki hui hain (not just saved)
- [ ] Rules publish ke baad 2-3 minutes wait kiya
- [ ] App completely restart kiya (not just hot reload)
- [ ] User properly logged in hai
- [ ] Console logs check kiye (detailed error messages)
- [ ] Rules Simulator mein test kiya (optional)

---

## 🆘 Still Not Working?

Agar abhi bhi issue hai, toh yeh information share karein:

1. **Exact error message** (console se copy karein)
2. **Console logs** (deleteAllUserData function ke logs)
3. **Firebase Rules status** (published hain ya nahi)
4. **User authentication status** (logged in hai ya nahi)

Yeh information se main exact issue identify kar sakta hoon! 🎯

