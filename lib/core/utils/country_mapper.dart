/// Country code to full name mapping for API
class CountryMapper {
  /// Map of country codes to full country names (as expected by API)
  static const Map<String, String> countryCodeToName = {
    'GH': 'GHANA',
    'NG': 'NIGERIA',
    'KE': 'KENYA',
    'UG': 'UGANDA',
    'TZ': 'TANZANIA',
    'ZA': 'SOUTH AFRICA',
    'ET': 'ETHIOPIA',
    'RW': 'RWANDA',
    'ZM': 'ZAMBIA',
    'ZW': 'ZIMBABWE',
    'MW': 'MALAWI',
    'BW': 'BOTSWANA',
    'NA': 'NAMIBIA',
    'AO': 'ANGOLA',
    'MZ': 'MOZAMBIQUE',
    'MG': 'MADAGASCAR',
    'CM': 'CAMEROON',
    'CI': 'IVORY COAST',
    'SN': 'SENEGAL',
    'ML': 'MALI',
    'BF': 'BURKINA FASO',
    'NE': 'NIGER',
    'TD': 'CHAD',
    'SD': 'SUDAN',
    'EG': 'EGYPT',
    'MA': 'MOROCCO',
    'TN': 'TUNISIA',
    'DZ': 'ALGERIA',
    'LY': 'LIBYA',
  };

  /// Get full country name from country code
  /// Returns the country code in uppercase if mapping not found
  static String getCountryName(String countryCode) {
    return countryCodeToName[countryCode.toUpperCase()] ?? 
           countryCode.toUpperCase();
  }

  /// Get country code from full country name
  static String? getCountryCode(String countryName) {
    for (final entry in countryCodeToName.entries) {
      if (entry.value.toUpperCase() == countryName.toUpperCase()) {
        return entry.key;
      }
    }
    return null;
  }

  /// Check if country code exists in mapping
  static bool hasCountryCode(String countryCode) {
    return countryCodeToName.containsKey(countryCode.toUpperCase());
  }

  /// Get all available country names
  static List<String> getAllCountryNames() {
    return countryCodeToName.values.toList()..sort();
  }

  /// Get all available country codes
  static List<String> getAllCountryCodes() {
    return countryCodeToName.keys.toList()..sort();
  }
}

