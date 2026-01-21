class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://api.advansistechnologies.com';
  static const String apiVersion = '/api/v1';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeModeKey = 'theme_mode';
  static const String recentTransactionsKey = 'recent_transactions';
  static const String onboardingCompletedKey = 'onboarding_completed';
  
  // Remember Me Keys
  static const String rememberMeKey = 'remember_me';
  static const String savedUsernameKey = 'saved_username';
  static const String savedPasswordKey = 'saved_password';
  
  // Default Values
  static const String defaultCountryCode = 'GH'; // Ghana
  static const String defaultCurrency = 'GHS';
  static const String defaultLanguage = 'en';
  
  // UI Constants
  static const double borderRadius = 20.0;
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusLarge = 24.0;
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxRecentTransactions = 10;
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPhoneLength = 15;
  static const int minPhoneLength = 10;
  
  // Airtime/Data
  static const List<double> airtimePresets = [10.0, 20.0, 50.0, 100.0, 200.0, 500.0];
  static const List<double> dataPresets = [1.0, 2.0, 5.0, 10.0, 20.0, 50.0]; // GB
  
  // Ghana API Configuration
  static const bool usePrymoForGhanaAirtime = true; // Switch to false to use Reloadly
  static const bool usePrymoForGhanaData = true; // Switch to false to use Reloadly
  
  // Prymo API Credentials (for Ghana)
  static const String prymoApiKey = 'YOUR_API_KEY'; // Replace with actual API key
  static const String prymoApiSecret = 'YOUR_API_SECRET'; // Replace with actual API secret
}

