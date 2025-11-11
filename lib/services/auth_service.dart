import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    UserCredential? credential;
    
    try {
      // Create user in Firebase Auth
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user ID before async operations
      final userId = credential.user!.uid;

      // Update display name (non-blocking)
      credential.user?.updateDisplayName(displayName).catchError((e) {
        print('Warning: Could not update display name: $e');
      });
      
      // Generate unique account number (deterministic - same userId always generates same number)
      final accountNumber = UserModel.generateAccountNumber(userId);
      
      // Create user document in Firestore (fire-and-forget, completely async)
      // This won't block registration at all
      // Account number is generated at registration time and will be preserved
      Future.microtask(() {
        _firestoreService.createOrUpdateUser(
          UserModel(
            id: userId,
            email: email,
            displayName: displayName,
            createdAt: DateTime.now(),
            preferences: {
              'currency': 'Rs.',
              'notificationsEnabled': true,
              'biometricEnabled': false,
            },
            accountNumber: accountNumber, // Generated at registration - will be saved
          ),
        ).catchError((e) {
          // If Firestore fails, user is still created in Auth
          // This allows user to login even if Firestore setup is pending
          print('Warning: Could not save user data to Firestore: $e');
        });

        // Create default categories (fire-and-forget)
        _createDefaultCategories(userId).catchError((e) {
          // Categories can be created later
          print('Warning: Could not create default categories: $e');
        });
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // If credential was created but other operations failed, still return it
      if (credential != null) {
        return credential;
      }
      throw Exception('Error signing up: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      await _firestoreService.createOrUpdateUser(
        UserModel(
          id: credential.user!.uid,
          email: email,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        ),
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error signing in: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      // Simple email send without action code settings for better compatibility
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Handle specific error cases
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email address. Please check your email and try again.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email address. Please enter a valid email.');
      } else if (e.code == 'too-many-requests') {
        throw Exception('Too many requests. Please wait a few minutes before trying again.');
      } else if (e.code == 'missing-android-pkg-name' || e.code == 'missing-ios-bundle-id') {
        // These are just warnings, email should still be sent
        // Continue normally
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error sending password reset email: ${e.toString()}');
    }
  }

  // Create default categories for new user
  Future<void> _createDefaultCategories(String userId) async {
    final incomeCategories = [
      {'name': 'Salary', 'icon': 'account_balance'},
      {'name': 'Freelance', 'icon': 'work'},
      {'name': 'Investment', 'icon': 'trending_up'},
      {'name': 'Business', 'icon': 'business'},
      {'name': 'Gift', 'icon': 'card_giftcard'},
      {'name': 'Rental', 'icon': 'home'},
      {'name': 'Other', 'icon': 'category'},
    ];

    final expenseCategories = [
      {'name': 'Food', 'icon': 'restaurant'},
      {'name': 'Transport', 'icon': 'directions_car'},
      {'name': 'Shopping', 'icon': 'shopping_bag'},
      {'name': 'Bills', 'icon': 'receipt'},
      {'name': 'Entertainment', 'icon': 'movie'},
      {'name': 'Healthcare', 'icon': 'medical_services'},
      {'name': 'Education', 'icon': 'school'},
      {'name': 'Travel', 'icon': 'flight'},
      {'name': 'Other', 'icon': 'category'},
    ];

    final batch = FirebaseFirestore.instance.batch();
    final categoriesRef = FirebaseFirestore.instance.collection('categories');

    // Add income categories
    for (var category in incomeCategories) {
      final docRef = categoriesRef.doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'name': category['name'],
        'type': 'income',
        'icon': category['icon'],
        'isDefault': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    // Add expense categories
    for (var category in expenseCategories) {
      final docRef = categoriesRef.doc();
      batch.set(docRef, {
        'id': docRef.id,
        'userId': userId,
        'name': category['name'],
        'type': 'expense',
        'icon': category['icon'],
        'isDefault': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await batch.commit();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'configuration-not-found':
      case 'CONFIGURATION_NOT_FOUND':
        return 'Firebase configuration error. Please check:\n1. Email/Password authentication is enabled in Firebase Console\n2. SHA-1 fingerprint is added to Firebase project\n3. google-services.json is up to date';
      default:
        return 'An error occurred: ${e.message ?? e.code}';
    }
  }
}

