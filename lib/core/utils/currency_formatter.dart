import '../../data/models/api_models.dart';

/// Utility class for currency formatting
class CurrencyFormatter {
  /// Returns the appropriate currency code for a country
  static String getCurrencyCode(Country country) {
    // For Ghana, always return GHS
    if (country.code == 'GH') {
      return 'GHS';
    }
    // For other countries, use their default currency code
    return country.currencyCode ?? 'USD';
  }

  /// Returns the appropriate currency symbol for a country
  static String getCurrencySymbol(Country country) {
    // For Ghana, always return GHS
    if (country.code == 'GH') {
      return 'GHS';
    }
    // For other countries, use their default currency symbol
    return country.currencySymbol ?? '\$';
  }

  /// Formats amount with currency for display
  static String formatAmount(double amount, Country country, {bool showCode = true}) {
    final currency = showCode ? getCurrencyCode(country) : getCurrencySymbol(country);
    return '$currency${amount.toStringAsFixed(2)}';
  }

  /// Formats amount with currency symbol for display
  static String formatAmountWithSymbol(double amount, Country country) {
    final symbol = getCurrencySymbol(country);
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Checks if the country is Ghana
  static bool isGhana(Country? country) {
    return country?.code == 'GH';
  }
}
