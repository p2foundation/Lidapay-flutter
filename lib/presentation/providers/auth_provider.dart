import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/api_models.dart';
import '../../data/datasources/api_client.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be initialized');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final dio = DioClient.createDio(
    getToken: () async => prefs.getString(AppConstants.authTokenKey),
  );
  // Note: Not using errorLogger due to version mismatch between generator and runtime
  // Errors are handled via Dio interceptors (LoggingInterceptor) instead
  return ApiClient(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthRepository(apiClient, prefs);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<Map<String, String>?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AsyncValue<Map<String, String>?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String country,
    String? roles, // String like "USER", "MERCHANT", "AGENT"
    String? referrerClientId,
  }) async {
    AppLogger.info('📝 Registration initiated', 'AuthProvider');
    state = const AsyncValue.loading();
    try {
      await _repository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        country: country,
        roles: roles,
        referrerClientId: referrerClientId,
      );
      AppLogger.info('✅ Registration completed successfully', 'AuthProvider');
      state = const AsyncValue.data(null); // Registration successful
    } catch (e, stackTrace) {
      AppLogger.error('❌ Registration failed in provider', e, stackTrace, 'AuthProvider');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> login(String username, String password, {bool rememberMe = false}) async {
    AppLogger.info('🔐 Login initiated for: $username', 'AuthProvider');
    state = const AsyncValue.loading();
    try {
      final tokens = await _repository.login(username, password, rememberMe: rememberMe);
      AppLogger.info('✅ Login successful in provider', 'AuthProvider');
      state = AsyncValue.data(tokens);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Login failed in provider', e, stackTrace, 'AuthProvider');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refreshToken() async {
    try {
      final tokens = await _repository.refreshToken();
      state = AsyncValue.data(tokens);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<bool> checkAuth() async {
    return await _repository.isAuthenticated();
  }
}

final currentUserProvider = FutureProvider<User?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  try {
    return await repository.getUserProfile();
  } catch (e) {
    return null;
  }
});

