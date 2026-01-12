import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  AuthRepository(this._apiClient, this._prefs);

  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String country,
    String? roles, // String like "AGENT", "USER", "MERCHANT"
    String? referrerClientId,
  }) async {
    try {
      AppLogger.info('Starting user registration', 'AuthRepository');
      AppLogger.debug('Registration data: email=$email, phone=$phoneNumber, country=$country, roles=$roles', 'AuthRepository');
      
      final response = await _apiClient.register(
        RegisterRequest(
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          password: password,
          country: country,
          roles: roles ?? 'USER', // Default to "USER" if not specified
          referrerClientId: referrerClientId,
        ),
      );
      
      if (response.user == null) {
        AppLogger.error('Registration failed: ${response.message}', null, null, 'AuthRepository');
        throw Exception(response.message);
      }
      
      AppLogger.info('✅ Registration successful: User ID=${response.user!.id}', 'AuthRepository');
      return response.user!;
    } on DioException catch (e) {
      AppLogger.error('Registration error', e, e.stackTrace, 'AuthRepository');
      if (e.response?.data != null) {
        AppLogger.debug('Error response body: ${e.response?.data}', 'AuthRepository');
        
        // Parse nested error structure from API
        final errorData = e.response?.data;
        String? errorMessage;
        
        if (errorData is Map<String, dynamic>) {
          // Check for nested message structure
          if (errorData['message'] is Map<String, dynamic>) {
            final nestedMessage = errorData['message'] as Map<String, dynamic>;
            errorMessage = nestedMessage['message'] as String?;
          } else if (errorData['message'] is String) {
            errorMessage = errorData['message'] as String;
          }
        }
        
        if (e.response?.statusCode == 400) {
          throw Exception(errorMessage ?? 'Invalid registration data. Please check your information.');
        } else if (e.response?.statusCode == 409) {
          throw Exception(errorMessage ?? 'User already exists with this email or phone number.');
        } else if (e.response?.statusCode != null) {
          throw Exception(errorMessage ?? 'Registration failed: ${e.response?.statusMessage ?? 'Server error'}');
        }
      }
      
      // Fallback error handling
      if (e.response?.statusCode == 400) {
        throw Exception('Invalid registration data. Please check your information.');
      } else if (e.response?.statusCode == 409) {
        throw Exception('User already exists with this email or phone number.');
      } else {
        throw Exception('Registration failed: ${e.response?.statusMessage ?? e.message ?? 'Unknown error'}');
      }
    } catch (e) {
      AppLogger.error('Registration error', e);
      rethrow;
    }
  }

  Future<Map<String, String>> login(String username, String password, {bool rememberMe = false}) async {
    try {
      AppLogger.info('🔐 Attempting login for username: $username', 'AuthRepository');
      
      // Validate inputs
      if (username.isEmpty) {
        throw Exception('Username cannot be empty');
      }
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      final response = await _apiClient.login(
        LoginRequest(username: username, password: password),
      );

      // Validate response has valid tokens
      if (response.accessToken.isEmpty) {
        AppLogger.error('❌ Login failed: Empty access token received', null, null, 'AuthRepository');
        throw Exception('Invalid response from server. Please try again.');
      }
      
      if (response.refreshToken.isEmpty) {
        AppLogger.error('❌ Login failed: Empty refresh token received', null, null, 'AuthRepository');
        throw Exception('Invalid response from server. Please try again.');
      }

      // Validate token format (JWT tokens should have 3 parts separated by dots)
      final accessTokenParts = response.accessToken.split('.');
      if (accessTokenParts.length != 3) {
        AppLogger.error('❌ Login failed: Invalid access token format', null, null, 'AuthRepository');
        throw Exception('Invalid authentication token received. Please try again.');
      }

      // Save tokens only after validation
      await _prefs.setString(AppConstants.authTokenKey, response.accessToken);
      await _prefs.setString(AppConstants.refreshTokenKey, response.refreshToken);
      
      // Save user ID if available
      if (response.user != null) {
        await _prefs.setString(AppConstants.userIdKey, response.user!.id);
        AppLogger.info('✅ User info saved: ${response.user!.email ?? response.user!.phoneNumber}', 'AuthRepository');
      }
      
      // Handle remember me functionality
      if (rememberMe) {
        await _prefs.setBool(AppConstants.rememberMeKey, true);
        await _prefs.setString(AppConstants.savedUsernameKey, username);
        await _prefs.setString(AppConstants.savedPasswordKey, password);
        AppLogger.info('💾 Credentials saved for remember me', 'AuthRepository');
      } else {
        // Clear saved credentials if remember me is not checked
        await _prefs.remove(AppConstants.rememberMeKey);
        await _prefs.remove(AppConstants.savedUsernameKey);
        await _prefs.remove(AppConstants.savedPasswordKey);
        AppLogger.debug('🗑️ Saved credentials cleared', 'AuthRepository');
      }

      AppLogger.info('✅ Login successful! Tokens saved', 'AuthRepository');
      AppLogger.debug('Access token length: ${response.accessToken.length}', 'AuthRepository');
      
      return {
        'accessToken': response.accessToken,
        'refreshToken': response.refreshToken,
      };
    } on DioException catch (e) {
      AppLogger.error('❌ Login failed', e, e.stackTrace, 'AuthRepository');
      AppLogger.debug('Response status: ${e.response?.statusCode}, Message: ${e.response?.statusMessage}', 'AuthRepository');
      if (e.response?.data != null) {
        AppLogger.debug('Error response body: ${e.response?.data}', 'AuthRepository');
      }
      
      // Clear any stored tokens on error
      await _prefs.remove(AppConstants.authTokenKey);
      await _prefs.remove(AppConstants.refreshTokenKey);
      await _prefs.remove(AppConstants.userIdKey);
      // Don't clear remember me credentials on login error
      
      if (e.response?.statusCode == 404) {
        throw Exception('API endpoint not found. Please check the API configuration or contact support.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Invalid username or password.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid request. Please check your credentials.');
      } else if (e.response?.statusCode != null) {
        throw Exception('Server error: ${e.response?.statusCode}. ${e.response?.statusMessage ?? ''}');
      } else {
        throw Exception('Network error: ${e.message ?? 'Unable to connect to server'}');
      }
    } catch (e) {
      AppLogger.error('Login error', e);
      rethrow;
    }
  }

  Future<Map<String, String>> refreshToken() async {
    try {
      AppLogger.info('🔄 Refreshing access token', 'AuthRepository');
      
      final refreshTokenValue = await getRefreshToken();
      if (refreshTokenValue == null) {
        AppLogger.warning('No refresh token available', 'AuthRepository');
        throw Exception('No refresh token available');
      }

      final response = await _apiClient.refreshToken(
        RefreshTokenRequest(refreshToken: refreshTokenValue),
      );

      // Save new tokens
      await _prefs.setString(AppConstants.authTokenKey, response.accessToken);
      await _prefs.setString(AppConstants.refreshTokenKey, response.refreshToken);

      AppLogger.info('✅ Token refresh successful', 'AuthRepository');
      
      return {
        'accessToken': response.accessToken,
        'refreshToken': response.refreshToken,
      };
    } catch (e) {
      AppLogger.error('❌ Token refresh failed', e, null, 'AuthRepository');
      rethrow;
    }
  }

  Future<User> getUserProfile() async {
    try {
      AppLogger.info('📋 Fetching user profile', 'AuthRepository');
      final response = await _apiClient.getUserProfile();
      AppLogger.info('✅ User profile loaded: ${response.user.email ?? response.user.phoneNumber}', 'AuthRepository');
      AppLogger.debug('User ID: ${response.user.id}, Username: ${response.user.username}', 'AuthRepository');
      
      // Ensure userId is saved to SharedPreferences for dynamic access
      if (response.user.id != null && response.user.id!.isNotEmpty) {
        await _prefs.setString(AppConstants.userIdKey, response.user.id!);
        AppLogger.debug('✅ User ID saved to SharedPreferences: ${response.user.id}', 'AuthRepository');
      }
      
      return response.user;
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to get user profile', e, e.stackTrace, 'AuthRepository');
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('User profile not found.');
      } else if (e.response?.statusCode != null) {
        throw Exception('Failed to load profile: ${e.response?.statusMessage ?? 'Server error'}');
      } else {
        throw Exception('Network error: ${e.message ?? 'Unable to connect to server'}');
      }
    } catch (e) {
      AppLogger.error('❌ Failed to get user profile', e, null, 'AuthRepository');
      rethrow;
    }
  }

  Future<User> updateUserProfile(UpdateProfileRequest request) async {
    try {
      AppLogger.info('📝 Updating user profile', 'AuthRepository');
      AppLogger.debug('Update data: firstName=${request.firstName}, lastName=${request.lastName}, email=${request.email}, phone=${request.phoneNumber}', 'AuthRepository');
      
      final response = await _apiClient.updateUserProfile(request);
      
      AppLogger.info('✅ Profile updated successfully', 'AuthRepository');
      return response.user;
    } on DioException catch (e) {
      AppLogger.error('❌ Update profile failed', e, e.stackTrace, 'AuthRepository');
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid data. Please check your information.');
      } else if (e.response?.statusCode == 409) {
        throw Exception('Email or phone number already in use.');
      } else if (e.response?.statusCode != null) {
        throw Exception('Failed to update profile: ${e.response?.statusMessage ?? 'Server error'}');
      } else {
        throw Exception('Network error: ${e.message ?? 'Unable to connect to server'}');
      }
    } catch (e) {
      AppLogger.error('Update user profile error', e);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('🔐 Changing password', 'AuthRepository');
      await _apiClient.changePassword(
        ChangePasswordRequest(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      AppLogger.info('✅ Password changed successfully', 'AuthRepository');
    } on DioException catch (e) {
      AppLogger.error('❌ Change password failed', e, e.stackTrace, 'AuthRepository');
      if (e.response?.statusCode == 401) {
        throw Exception('Current password is incorrect.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid password. Please check your input.');
      } else {
        throw Exception('Failed to change password: ${e.response?.statusMessage ?? e.message}');
      }
    } catch (e) {
      AppLogger.error('Change password error', e);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      AppLogger.info('📧 Sending password reset email to: $email', 'AuthRepository');
      await _apiClient.resetPassword(
        ResetPasswordRequest(email: email),
      );
      AppLogger.info('✅ Password reset email sent successfully', 'AuthRepository');
    } on DioException catch (e) {
      AppLogger.error('❌ Reset password failed', e, e.stackTrace, 'AuthRepository');
      if (e.response?.statusCode == 404) {
        throw Exception('Email not found. Please check your email address.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid email address.');
      } else {
        throw Exception('Failed to send reset email: ${e.response?.statusMessage ?? e.message}');
      }
    } catch (e) {
      AppLogger.error('Reset password error', e);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(AppConstants.authTokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
    await _prefs.remove(AppConstants.userIdKey);
    // Note: We don't clear remember me credentials on logout
    // as the user might want to stay logged in next time
  }
  
  // Remember Me Methods
  Future<bool> isRememberMeEnabled() async {
    return _prefs.getBool(AppConstants.rememberMeKey) ?? false;
  }
  
  Future<String?> getSavedUsername() async {
    return _prefs.getString(AppConstants.savedUsernameKey);
  }
  
  Future<String?> getSavedPassword() async {
    return _prefs.getString(AppConstants.savedPasswordKey);
  }
  
  Future<void> clearSavedCredentials() async {
    await _prefs.remove(AppConstants.rememberMeKey);
    await _prefs.remove(AppConstants.savedUsernameKey);
    await _prefs.remove(AppConstants.savedPasswordKey);
    AppLogger.info('🗑️ Saved credentials cleared', 'AuthRepository');
  }

  Future<String?> getToken() async {
    return _prefs.getString(AppConstants.authTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository provider must be overridden');
});

