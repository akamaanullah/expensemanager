# Firebase Cloud Functions for Expense Manager

This directory contains Firebase Cloud Functions for handling push notifications.

## Functions

### sendTransferNotification
Automatically sends push notifications when a transfer notification document is created in Firestore.

**Trigger:** `notifications/{notificationId}` document creation

**What it does:**
- Sends push notification to receiver's device
- Includes amount, sender name, and account number
- Handles Android and iOS notification formats
- Marks notification as sent/failed in Firestore

### cleanupOldNotifications
Automatically cleans up old notifications (older than 30 days).

**Trigger:** Daily at midnight (via Cloud Scheduler)

**What it does:**
- Deletes notifications older than 30 days
- Keeps Firestore database clean
- Runs automatically

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Deploy:
   ```bash
   firebase deploy --only functions
   ```

## Testing

Test locally with emulators:
```bash
firebase emulators:start --only functions
```

## Configuration

- **Node version:** 18
- **Firebase Admin SDK:** Latest
- **Firebase Functions:** v2

