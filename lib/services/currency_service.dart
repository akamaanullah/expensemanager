import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // Cache for exchange rates (valid for 1 hour)
  Map<String, double> _rateCache = {};
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(hours: 1);

  // Currency code mapping
  static const Map<String, String> currencyCodes = {
    'Rs.': 'PKR',
    '\$': 'USD',
    '€': 'EUR',
    '£': 'GBP',
    '¥': 'JPY',
    'A\$': 'AUD',
    'C\$': 'CAD',
    '₹': 'INR',
  };

  // Get currency code from symbol
  String getCurrencyCode(String symbol) {
    return currencyCodes[symbol] ?? 'PKR';
  }

  // Get exchange rate from PKR to target currency
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    // If same currency, return 1.0
    if (fromCurrency == toCurrency) {
      return 1.0;
    }

    // Check cache
    final cacheKey = '${fromCurrency}_$toCurrency';
    if (_rateCache.containsKey(cacheKey) && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < _cacheValidity) {
        return _rateCache[cacheKey]!;
      }
    }

    try {
      // Use exchangerate-api.com (free tier, no API key needed for basic usage)
      // Alternative: You can use https://api.exchangerate-api.com/v4/latest/PKR
      final fromCode = getCurrencyCode(fromCurrency);
      final toCode = getCurrencyCode(toCurrency);

      // Using free API: exchangerate-api.com
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/$fromCode');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Exchange rate API timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        if (rates.containsKey(toCode)) {
          final rate = (rates[toCode] as num).toDouble();
          
          // Cache the rate
          _rateCache[cacheKey] = rate;
          _cacheTimestamp = DateTime.now();
          
          return rate;
        } else {
          throw Exception('Currency code $toCode not found in exchange rates');
        }
      } else {
        throw Exception('Failed to fetch exchange rate: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching exchange rate: $e');
      
      // Return cached rate if available (even if expired)
      if (_rateCache.containsKey(cacheKey)) {
        return _rateCache[cacheKey]!;
      }
      
      // Fallback: Return 1.0 if API fails (will show original amount)
      return 1.0;
    }
  }

  // Convert amount from one currency to another
  Future<double> convertAmount(double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  // Clear cache
  void clearCache() {
    _rateCache.clear();
    _cacheTimestamp = null;
  }

  // Get currency symbol from code
  static String getCurrencySymbol(String code) {
    return currencyCodes.entries.firstWhere(
      (entry) => entry.value == code,
      orElse: () => const MapEntry('Rs.', 'PKR'),
    ).key;
  }
}

