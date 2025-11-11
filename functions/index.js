const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to send push notification when a new notification document is created
 * This triggers when a transfer notification document is added to Firestore
 */
exports.sendTransferNotification = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notification = snap.data();

      // Only process transfer notifications
      if (notification.type !== "transfer_received") {
        return null;
      }

      const fcmToken = notification.fcmToken;
      if (!fcmToken || fcmToken.trim() === "") {
        console.log("No FCM token found, skipping notification");
        return null;
      }

      const message = {
        notification: {
          title: notification.title || "Money Received",
          body: notification.body || "You have received money",
        },
        data: {
          type: notification.type || "transfer_received",
          amount: notification.amount != null ? notification.amount.toString() : "0",
          currency: notification.currency || "PKR",
          senderName: notification.senderName || "Unknown",
          senderAccountNumber: notification.senderAccountNumber || "N/A",
          timestamp: notification.timestamp || new Date().toISOString(),
        },
        token: fcmToken,
        android: {
          priority: "high",
          notification: {
            sound: "default",
            channelId: "transfer_notifications",
            priority: "high",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        const response = await admin.messaging().send(message);
        console.log("Successfully sent notification:", response);

        // Mark notification as sent
        await snap.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return response;
      } catch (error) {
        console.error("Error sending notification:", error);

        // Mark notification as failed
        await snap.ref.update({
          sent: false,
          error: error.message,
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        throw error;
      }
    });

/**
 * Cleanup old notifications (older than 30 days)
 * Runs daily at midnight
 */
exports.cleanupOldNotifications = functions.pubsub
    .schedule("every 24 hours")
    .onRun(async (context) => {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const snapshot = await admin.firestore()
          .collection("notifications")
          .where("timestamp", "<", thirtyDaysAgo.toISOString())
          .get();

      const batch = admin.firestore().batch();
      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Cleaned up ${snapshot.size} old notifications`);
      return null;
    });

