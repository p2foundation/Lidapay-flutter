import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import 'auth_provider.dart';

/// Provider that tracks whether onboarding has been completed
final onboardingCompletedProvider = Provider<bool>((ref) {
  // This provider should be overridden with the actual value from SharedPreferences
  return false;
});

/// Async provider that checks onboarding completion status
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
});

/// Provider to mark onboarding as completed
final onboardingNotifierProvider = Provider<OnboardingNotifier>((ref) {
  return OnboardingNotifier(ref.read(sharedPreferencesProvider));
});

class OnboardingNotifier {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs);

  Future<void> completeOnboarding() async {
    await _prefs.setBool(AppConstants.onboardingCompletedKey, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.setBool(AppConstants.onboardingCompletedKey, false);
  }

  bool get isCompleted => _prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
}
