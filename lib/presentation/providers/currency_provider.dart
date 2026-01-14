import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('USD') {
    _loadCurrency();
  }

  static const String _currencyKey = 'selected_currency';

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_currencyKey) ?? 'USD';
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
    state = currency;
  }

  // Helper to get currency symbol
  String getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'NGN':
        return '₦';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'INR':
        return '₹';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return '\$';
    }
  }
}
