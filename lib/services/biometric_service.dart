import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      return isSupported;
    } catch (e) {
      print('Error checking device support: $e');
      // If channel error (usually happens with hot restart), return false
      // User needs to do full app restart
      if (e.toString().contains('channel-error') || e.toString().contains('Unable to establish connection')) {
        print('Note: Full app restart required for biometric to work properly');
        return false;
      }
      // Try fallback method
      try {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      } catch (e2) {
        print('Error checking available biometrics: $e2');
        return false;
      }
    }
  }

  // Check available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  // Check if biometric authentication is enabled for user (by userId)
  Future<bool> isBiometricEnabledForUser(String userId) async {
    try {
      // Check if biometric is enabled in preferences
      final biometricEnabled = await _secureStorage.read(
        key: 'biometric_enabled_$userId',
      );
      return biometricEnabled == 'true';
    } catch (e) {
      print('Error checking biometric enabled: $e');
      return false;
    }
  }

  // Enable biometric authentication for user
  Future<void> enableBiometric(String email, String password) async {
    try {
      final authService = AuthService();
      final userId = authService.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Store credentials securely
      await _secureStorage.write(key: 'user_email_$userId', value: email);
      await _secureStorage.write(key: 'user_password_$userId', value: password);
      await _secureStorage.write(key: 'biometric_enabled_$userId', value: 'true');
    } catch (e) {
      print('Error enabling biometric: $e');
      throw Exception('Failed to enable biometric authentication');
    }
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      final authService = AuthService();
      final userId = authService.currentUser?.uid;
      if (userId == null) return;

      // Remove stored credentials
      await _secureStorage.delete(key: 'user_email_$userId');
      await _secureStorage.delete(key: 'user_password_$userId');
      await _secureStorage.delete(key: 'biometric_enabled_$userId');
    } catch (e) {
      print('Error disabling biometric: $e');
    }
  }

  // Authenticate using biometric
  Future<bool> authenticate() async {
    try {
      // Check if device supports biometric
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        throw Exception('Biometric authentication is not supported on this device');
      }

      // Check available biometrics
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        throw Exception('No biometric authentication methods available');
      }

      // Get biometric type name for display
      String biometricType = 'biometric';
      if (availableBiometrics.contains(BiometricType.face)) {
        biometricType = 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        biometricType = 'Fingerprint';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        biometricType = 'Biometric';
      }

      // Authenticate
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      print('Biometric authentication error: $e');
      // Check if it's the FragmentActivity error
      if (e.toString().contains('no_fragment_activity') || 
          e.toString().contains('FragmentActivity')) {
        print('Error: Full app restart required. Hot restart does not work with biometric authentication.');
        throw Exception('Please restart the app completely (not hot restart) for biometric to work');
      }
      return false;
    }
  }

  // Login using stored credentials after biometric authentication
  Future<bool> loginWithBiometric() async {
    try {
      final authService = AuthService();
      final currentUserId = authService.currentUser?.uid;
      
      // User is not logged in, need to get stored credentials
      final email = await _secureStorage.read(key: 'last_user_email');
      final password = await _secureStorage.read(key: 'last_user_password');
      
      if (email == null || password == null) {
        throw Exception('No stored credentials found');
      }

      // Authenticate with biometric first
      final authenticated = await authenticate();
      if (!authenticated) {
        return false;
      }

      // Login with stored credentials
      await authService.signInWithEmail(email: email, password: password);
      return true;
    } catch (e) {
      print('Error logging in with biometric: $e');
      return false;
    }
  }

  // Get last logged in user ID
  Future<String?> getLastUserId() async {
    try {
      return await _secureStorage.read(key: 'last_user_id');
    } catch (e) {
      print('Error getting last user ID: $e');
      return null;
    }
  }

  // Get last login credentials (for enabling biometric)
  Future<Map<String, String?>> getLastLoginCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'last_user_email');
      final password = await _secureStorage.read(key: 'last_user_password');
      return {'email': email, 'password': password};
    } catch (e) {
      print('Error getting last login credentials: $e');
      return {'email': null, 'password': null};
    }
  }

  // Store last login credentials (for biometric login when not logged in)
  Future<void> storeLastLoginCredentials(String email, String password, String userId) async {
    try {
      await _secureStorage.write(key: 'last_user_email', value: email);
      await _secureStorage.write(key: 'last_user_password', value: password);
      await _secureStorage.write(key: 'last_user_id', value: userId);
    } catch (e) {
      print('Error storing credentials: $e');
    }
  }

  // Clear stored credentials
  Future<void> clearStoredCredentials() async {
    try {
      final authService = AuthService();
      final userId = authService.currentUser?.uid;
      
      if (userId != null) {
        await _secureStorage.delete(key: 'user_email_$userId');
        await _secureStorage.delete(key: 'user_password_$userId');
        await _secureStorage.delete(key: 'biometric_enabled_$userId');
      }
      
      await _secureStorage.delete(key: 'last_user_email');
      await _secureStorage.delete(key: 'last_user_password');
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }

  // Get stored credentials for current user
  Future<Map<String, String?>> getStoredCredentials() async {
    try {
      final authService = AuthService();
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        // Try to get last login credentials
        final email = await _secureStorage.read(key: 'last_user_email');
        final password = await _secureStorage.read(key: 'last_user_password');
        return {'email': email, 'password': password};
      }
      
      final email = await _secureStorage.read(key: 'user_email_$userId');
      final password = await _secureStorage.read(key: 'user_password_$userId');
      return {'email': email, 'password': password};
    } catch (e) {
      print('Error getting stored credentials: $e');
      return {'email': null, 'password': null};
    }
  }
}

