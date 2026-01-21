import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Helper utility for onboarding-related operations
class OnboardingHelper {
  /// Check if onboarding has been completed
  static bool isCompleted(SharedPreferences prefs) {
    return prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding(SharedPreferences prefs) async {
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);
  }

  /// Reset onboarding status (useful for testing/debugging)
  static Future<void> resetOnboarding(SharedPreferences prefs) async {
    await prefs.setBool(AppConstants.onboardingCompletedKey, false);
  }

  /// Get the initial route based on onboarding status
  static String getInitialRoute(SharedPreferences prefs) {
    return isCompleted(prefs) ? '/login' : '/onboarding';
  }
}
