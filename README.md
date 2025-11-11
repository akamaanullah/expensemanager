# ExpenseManager

ExpenseManager is a multi-platform Flutter application for tracking and managing personal finances. It is backed by Firebase services and runs on Android, iOS, Web, Windows, macOS, and Linux.

## Core Features

- **Dashboard & Analytics**: Real-time overview of income, expenses, and net balance.
- **Transactions Management**:
  - Add, edit, and delete income/expense entries with categories.
  - Multi-currency support with original amounts and preferred currency conversions.
  - Generate detailed transaction slips (PDF) for export and sharing.
- **Loans Module**:
  - Track loans given or taken with person-wise summaries and balances.
  - Loan detail screens, payment reminders, and quick settlement flows.
- **Payees & Transfers**:
  - Save recipients with account profiles.
  - In-app transfer workflow with double-entry accounting, receipts, and notifications.
- **Statements & Exports**:
  - Download account statements (PDF) showing opening and closing balances.
  - Export data as CSV/JSON for bookkeeping.
- **Notifications**:
  - Transfer alerts via Firebase Cloud Messaging and local notifications.
- **Security**:
  - Email/password authentication.
  - Optional biometric login helpers (where supported).

## Tech Stack

- **Flutter** (Dart) with Material 3 UI.
- **Firebase**: Authentication, Cloud Firestore, Cloud Functions, Cloud Messaging.
- **Local storage**: Shared Preferences, Flutter Secure Storage (biometrics).
- **CI/CD ready**: npm scripts for Firebase Cloud Functions linting/builds.

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
   - Firebase CLI (for deployments)
   - Node.js (for Cloud Functions)

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
   - Generate `lib/firebase_options.dart` using the FlutterFire CLI.  
     ```bash
     flutterfire configure
     ```
   - Download platform-specific config files and place them in the project:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
     - `macos/Runner/GoogleService-Info.plist` (if targeting macOS)
   - Enable Email/Password Authentication, add the Android SHA-1 fingerprint, then download the updated config files.

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

> ❗️ `lib/firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist` are not tracked in the repository. Keep them locally—`.gitignore` already covers these files.

## Environment Configuration

| Variable/Step                  | Description                                                   |
| ----------------------------- | ------------------------------------------------------------- |
| Firebase Project              | `expensetracking-df9e8` (replace with your project if needed) |
| Auth Provider                 | Email/Password                                                |
| Firestore Rules               | Deploy from `/firestore.rules`                               |
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

- In-app analytics charts.
- Advanced budgeting alerts.
- Offline sync improvements.

## Support & Contact

- 📧 Email: [info@amaanullah.com](mailto:info@amaanullah.com)
- 🌐 Website: [amaanullah.com](https://amaanullah.com)
- Issues or feature requests: please use the GitHub Issues tab.

---

© 2025 ExpenseManager by Amaanullah. All rights reserved.
