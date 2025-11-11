import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Initialize local notifications
  Future<void> initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      final bool? initialized = await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print('Notification tapped: ${response.payload}');
        },
      );
      
      if (initialized == null || !initialized) {
        print('Local notifications initialization failed or already initialized');
        return;
      }
      
      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'transfer_notifications',
        'Transfer Notifications',
        description: 'Notifications for money transfers',
        importance: Importance.high,
        playSound: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      print('Error initializing local notifications: $e');
      // Don't throw - app should work without notifications
    }
  }
  
  // Listen to Firestore notifications and show local notification
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  Set<String> _processedNotificationIds = {};
  DateTime? _lastNotificationTime;
  String? _lastNotificationBody;
  
  void startListeningToNotifications(String userId) {
    _notificationSubscription?.cancel();
    _processedNotificationIds.clear();
    _lastNotificationTime = null;
    _lastNotificationBody = null;
    
    // Listen to unread notifications for this user
    // Using where query only (no orderBy to avoid index requirement)
    _notificationSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      // Only process if there are new documents (not just updates)
      if (snapshot.docs.isEmpty) return;
      
      // Process each new notification, but only once per unique notification
      for (var docChange in snapshot.docChanges) {
        // Only process newly added documents, not modified ones
        if (docChange.type != DocumentChangeType.added) {
          continue;
        }
        
        final notificationId = docChange.doc.id;
        
        // Skip if already processed
        if (_processedNotificationIds.contains(notificationId)) {
          continue;
        }
        
        final data = docChange.doc.data();
        if (data == null) continue; // Skip if data is null
        
        final notificationBody = data['body'] ?? 'You have received money';
        
        // Prevent duplicate notifications within 5 seconds
        final now = DateTime.now();
        if (_lastNotificationTime != null &&
            _lastNotificationBody == notificationBody &&
            now.difference(_lastNotificationTime!) < const Duration(seconds: 5)) {
          print('Skipping duplicate notification within 5 seconds');
          continue;
        }
        
        // Show local notification
        await _showLocalNotification(
          title: data['title'] ?? 'Money Received',
          body: notificationBody,
          payload: notificationId,
        );
        
        // Mark as read
        await docChange.doc.reference.update({'read': true});
        _processedNotificationIds.add(notificationId);
        _lastNotificationTime = now;
        _lastNotificationBody = notificationBody;
      }
    }, onError: (error) {
      print('Notification listener error: $error');
      // Try to recreate listener if error occurs
      Future.delayed(const Duration(seconds: 2), () {
        if (FirebaseAuth.instance.currentUser != null) {
          startListeningToNotifications(userId);
        }
      });
    });
  }
  
  void stopListeningToNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }
  
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'transfer_notifications',
      'Transfer Notifications',
      channelDescription: 'Notifications for money transfers',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Request notification permissions and get FCM token
  Future<String?> initializeNotifications() async {
    try {
      // Request permission (iOS) - with error handling
      NotificationSettings? settings;
      try {
        settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      } catch (e) {
        print('Error requesting FCM permission (may need app restart): $e');
        // On Android, permission is not needed, continue
        if (e.toString().contains('MissingPluginException')) {
          print('Plugin not available - app may need full restart');
          return null;
        }
      }

      if (settings != null && settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        try {
          String? token = await _messaging.getToken();
          
          if (token != null) {
            // Save token to user document
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await _firestore.collection('users').doc(user.uid).update({
                'fcmToken': token,
              });
            }
            return token;
          }
        } catch (e) {
          print('Error getting FCM token: $e');
        }
      }
      return null;
    } catch (e) {
      print('Error initializing notifications: $e');
      // Don't throw - app should work without FCM
      return null;
    }
  }

  // Send notification to receiver when money is transferred
  Future<void> sendTransferNotification({
    required String receiverId,
    required String receiverName,
    required String senderName,
    required String senderAccountNumber,
    required double amount,
    required String currency,
  }) async {
    try {
      // Format notification message properly
      // Format: "You have received {amount} from {username} ({account number})"
      String notificationBody;
      
      if (senderAccountNumber != 'N/A' && senderAccountNumber.isNotEmpty) {
        // Show username and account number
        notificationBody = 'You have received $currency ${amount.toStringAsFixed(2)} from $senderName ($senderAccountNumber)';
      } else {
        // Fallback if account number not available
        notificationBody = 'You have received $currency ${amount.toStringAsFixed(2)} from $senderName';
      }
      
      // Always create notification document - app-side listener will show it
      // FCM token check removed - notification will work via Firestore listener
      
      // Create notification document (always create, even without FCM token)
      await _firestore.collection('notifications').add({
        'userId': receiverId,
        'title': 'Money Received',
        'body': notificationBody,
        'type': 'transfer_received',
        'senderName': senderName,
        'senderAccountNumber': senderAccountNumber,
        'amount': amount,
        'currency': currency,
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Notification created for receiver: $receiverName');
    } catch (e) {
      print('Error sending notification: $e');
      // Don't throw error - notification failure shouldn't block transfer
    }
  }

  // Handle foreground messages
  static Future<void> handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message received: ${message.notification?.title}');
    print('Notification body: ${message.notification?.body}');
    print('Notification data: ${message.data}');
    
    // You can show a local notification here if needed
    // For now, the app will handle it through the notification handler
  }

  // Handle background messages
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Background message received: ${message.notification?.title}');
    // Handle notification when app is in background
  }
}

