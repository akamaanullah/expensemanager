import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/notification_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when widget is created
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final notificationService = NotificationService();
        
        // Initialize local notifications first (works without FCM)
        await notificationService.initializeLocalNotifications();
        
        // Try to initialize FCM (may fail on hot reload, that's okay)
        await notificationService.initializeNotifications();
        
        // Start listening to Firestore notifications (main feature)
        notificationService.startListeningToNotifications(user.uid);
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      // Continue even if notifications fail - app should work without them
    }
  }
  
  @override
  void dispose() {
    final notificationService = NotificationService();
    notificationService.stopListeningToNotifications();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show home screen
        if (snapshot.hasData && snapshot.data != null) {
          // Initialize notifications when user logs in
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeNotifications();
            });
          }
          return const HomeScreen();
        }

        // If user is not logged in, show login screen
        return const LoginScreen();
      },
    );
  }
}

