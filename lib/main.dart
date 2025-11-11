import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'widgets/auth_wrapper.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  NotificationService.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Setup Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Setup foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground notification received: ${message.notification?.title}');
      NotificationService.handleForegroundMessage(message);
    });
    
    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app: ${message.notification?.title}');
      // Navigate to transaction detail or home screen based on notification data
    });
    
    // Check if app was opened from a notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.notification?.title}');
    }
    
    // Initialize notifications for logged-in users
    final authService = AuthService();
    if (authService.currentUser != null) {
      final notificationService = NotificationService();
      await notificationService.initializeNotifications();
    }
  } catch (e) {
    // Handle Firebase initialization error
    print('Firebase initialization error: $e');
  }
  runApp(const ExpenseManagerApp());
}

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Expense Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Indigo color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const AuthWrapper(), // Protected route
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
    
    // Check authentication and navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      
      try {
        // Check if Firebase is initialized
        try {
          Firebase.app();
        } catch (e) {
          // Firebase not initialized, check onboarding then go to login
          print('Firebase not initialized: $e');
          final prefs = await SharedPreferences.getInstance();
          final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
          
          if (!onboardingCompleted) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/onboarding');
            }
          } else {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
          return;
        }
        
        // Try to get auth service and check user
      final authService = AuthService();
      final user = authService.currentUser;
      
      if (user != null) {
          // User is logged in, go directly to home (skip onboarding)
          if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
          }
      } else {
          // User is not logged in, check onboarding status
          final prefs = await SharedPreferences.getInstance();
          final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
          
          if (!onboardingCompleted) {
            // Show onboarding screen for first-time users who are not logged in
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/onboarding');
            }
          } else {
            // Onboarding completed, go to login
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          }
            }
      } catch (e) {
        // If any error occurs, check onboarding then navigate to login screen
        print('Error during authentication check: $e');
        try {
          final prefs = await SharedPreferences.getInstance();
          final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
          
          if (!onboardingCompleted) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/onboarding');
            }
      } else {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
        } catch (prefsError) {
          // If SharedPreferences also fails, go to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
    });
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main Content (Centered)
            Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon/Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 70,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // App Name
                  const Text(
                    'My Expense Manager',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tagline
                  Text(
                    'Track Your Money, Control Your Life',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Loading Indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ),
            // Developer Credit at Bottom
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Text(
                    'Developed by Amaanullah',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
