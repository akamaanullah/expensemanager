import '../models/transaction_model.dart';
import '../services/currency_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class CurrencyHelper {
  static final CurrencyService _currencyService = CurrencyService();
  static final AuthService _authService = AuthService();
  static final FirestoreService _firestoreService = FirestoreService();

  // Get user's current currency preference
  static Future<String> getUserCurrency() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return 'Rs.';

      final userModel = await _firestoreService.getUser(user.uid);
      if (userModel?.preferences != null) {
        return userModel!.preferences!['currency'] ?? 'Rs.';
      }
      return 'Rs.';
    } catch (e) {
      print('Error getting user currency: $e');
      return 'Rs.';
    }
  }

  // Get converted amount for display
  static Future<String> getFormattedAmount(
    TransactionModel transaction, {
    String? currency,
  }) async {
    try {
      final userCurrency = currency ?? await getUserCurrency();
      
      // If transaction currency matches user currency, show as is
      if (transaction.originalCurrency == userCurrency) {
        return '${_getCurrencySymbol(userCurrency)}${transaction.originalAmount.toStringAsFixed(2)}';
      }

      // Convert from original currency to user's currency
      final convertedAmount = await _currencyService.convertAmount(
        transaction.originalAmount,
        transaction.originalCurrency,
        userCurrency,
      );

      return '${_getCurrencySymbol(userCurrency)}${convertedAmount.toStringAsFixed(2)}';
    } catch (e) {
      print('Error formatting amount: $e');
      // Fallback to original amount
      return '${_getCurrencySymbol(transaction.originalCurrency)}${transaction.originalAmount.toStringAsFixed(2)}';
    }
  }

  // Get converted amount as double (for calculations)
  static Future<double> getConvertedAmount(
    TransactionModel transaction, {
    String? currency,
  }) async {
    try {
      final userCurrency = currency ?? await getUserCurrency();
      
      // If transaction currency matches user currency, return as is
      if (transaction.originalCurrency == userCurrency) {
        return transaction.originalAmount;
      }

      // Convert from original currency to user's currency
      return await _currencyService.convertAmount(
        transaction.originalAmount,
        transaction.originalCurrency,
        userCurrency,
      );
    } catch (e) {
      print('Error converting amount: $e');
      // Fallback to original amount
      return transaction.originalAmount;
    }
  }

  // Get currency symbol
  static String _getCurrencySymbol(String currency) {
    return currency; // Currency is already stored as symbol (Rs., $, etc.)
  }

  // Format amount with currency symbol (for display)
  static String formatAmount(double amount, String currency) {
    return '${_getCurrencySymbol(currency)}${amount.toStringAsFixed(2)}';
  }
}

