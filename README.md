# ExpenseManager

ExpenseManager ek multi-platform Flutter application hai jo personal finance ko track aur manage karna asaan banata hai. App Firebase ke upar build hai aur Android, iOS, Web, Windows, macOS, aur Linux par run kar sakta hai.

## Core Features

- **Dashboard & Analytics**: Income, expense, aur net balance ka real-time overview.
- **Transactions Management**:
  - Income & expense entries category-wise add/edit/delete.
  - Multi-currency support: original currency store + user preferred currency conversion.
  - Detailed transaction slips (PDF) export & share.
- **Loans Module**:
  - Loans given/taken track karein, person-wise summary aur balance.
  - Loan detail screens, pay reminders, aur quick settlement flows.
- **Payees & Transfers**:
  - Saved recipients (account number + profile).
  - In-app transfer workflow: expense/income double-entry, receipts & notifications.
- **Statements & Exports**:
  - Account statement (PDF) download with opening/closing balance.
  - CSV/JSON exports for bookkeeping.
- **Notifications**:
  - Firebase Cloud Messaging + local notifications for transfer alerts.
- **Security**:
  - Email/Password authentication.
  - Optional biometric login helpers (platform support dependent).

## Tech Stack

- **Flutter** (Dart) with Material 3 UI.
- **Firebase**: Authentication, Cloud Firestore, Cloud Functions, Cloud Messaging.
- **Local storage**: Shared Preferences, Flutter Secure Storage (biometrics).
- **CI/CD ready**: npm scripts for Firebase functions lint/build.

## Project Structure

```
lib/
  models/          # Data models (Transaction, Loan, User, SavedRecipient)
  screens/         # UI screens (home, auth, loans, payees, settings, etc.)
  services/        # Firebase, notifications, currency, export services
  utils/           # Helpers (category icons, currency conversion)
  widgets/         # Shared widgets (AuthWrapper)
functions/         # Firebase Cloud Functions (Node.js)
android/ios/...    # Platform-specific runners & configs
```

## Getting Started

1. **Prerequisites**
   - Flutter SDK (latest stable)
   - Dart SDK (Flutter bundle)
   - Firebase CLI (deployment ke liye)
   - Node.js (Cloud Functions ke liye)

2. **Clone**
   ```bash
   git clone git@github.com:akamaanullah/expensemanager.git
   cd expensemanager
   ```

3. **Dependencies Install**
   ```bash
   flutter pub get
   cd functions
   npm install
   cd ..
   ```

4. **Firebase Configuration**
   - FlutterFire CLI chalakar `lib/firebase_options.dart` generate karein.  
     ```bash
     flutterfire configure
     ```
   - Platform specific config files download karke place karein:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
     - `macos/Runner/GoogleService-Info.plist` (agar macOS target hai)
   - Email/Password auth enable karein, SHA-1 fingerprint add karein (Android), phir updated config files replace karein.

5. **Run**
   ```bash
   flutter run
   ```

6. **Firebase Functions Deploy**
   ```bash
   firebase login
   firebase use <project-id>
   npm --prefix functions run lint
   npm --prefix functions run build
   firebase deploy --only functions
   ```

> ❗️ `lib/firebase_options.dart`, `google-services.json`, aur `GoogleService-Info.plist` repo me include nahin hain. Ye files local rakhein aur `.gitignore` me already ignore hain.

## Environment Configuration

| Variable/Step                  | Description                                                   |
| ----------------------------- | ------------------------------------------------------------- |
| Firebase Project              | `expensetracking-df9e8` (replace with apna project if needed) |
| Auth Provider                 | Email/Password                                                |
| Firestore Rules               | `/firestore.rules` ke according deploy karein                 |
| Functions Region              | Default (`us-central1`)                                       |
| Currency API (built-in)       | exchangerate-api.com free endpoint (no key required)          |

## Common Commands

```bash
flutter analyze                # Static analysis
flutter test                   # Unit/widget tests (if available)
flutter build apk --release    # Android release build
firebase emulators:start       # Local emulation (auth, firestore)
```

## Known TODOs / Enhancements

- In-app analytics charts (future).
- Advanced budgeting alerts.
- Offline sync improvements.

## Support & Contact

- 📧 Email: [info@amaanullah.com](mailto:info@amaanullah.com)
- 🌐 Website: [amaanullah.com](https://amaanullah.com)
- Issues / feature requests: GitHub Issues tab par report karein.

---

© 2025 ExpenseManager by Amaanullah. All rights reserved.
