import 'dart:async';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/utils/logger.dart';

class RewardsRepository {
  final ApiClient _apiClient;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  RewardsRepository(this._apiClient);

  Future<int> getUserPoints() async {
    try {
      final response = await _apiClient.getUserPoints().timeout(
        _timeoutDuration,
        onTimeout: () => throw TimeoutException('Points request timed out'),
      );

      return response.points;
    } on TimeoutException catch (e) {
      AppLogger.warning('Points request timeout: $e', 'RewardsRepository');
      return 0;
    } catch (e) {
      AppLogger.error('Get points error', e, null, 'RewardsRepository');
      return 0;
    }
  }

  Future<List<Reward>> getRewardsCatalog() async {
    try {
      final response = await _apiClient.getRewards().timeout(
        _timeoutDuration,
        onTimeout: () => throw TimeoutException('Rewards request timed out'),
      );

      final rewards = response.data?.rewards ?? const <Reward>[];
      return rewards;
    } on TimeoutException catch (e) {
      AppLogger.warning('Rewards request timeout: $e', 'RewardsRepository');
      return const <Reward>[];
    } catch (e) {
      AppLogger.error('Get rewards error', e, null, 'RewardsRepository');
      return const <Reward>[];
    }
  }

  Future<VerificationResponse> requestEmailVerification(String email) async {
    try {
      final request = EmailVerificationRequest(email: email);
      final response = await _apiClient.requestEmailVerification(request).timeout(
        _timeoutDuration,
        onTimeout: () => throw TimeoutException('Email verification request timed out'),
      );

      return response;
    } on TimeoutException catch (e) {
      AppLogger.warning('Email verification request timeout: $e', 'RewardsRepository');
      return VerificationResponse(success: false, message: 'Request timed out');
    } catch (e) {
      AppLogger.error('Request email verification error', e, null, 'RewardsRepository');
      return VerificationResponse(success: false, message: e.toString());
    }
  }

  Future<VerificationResponse> confirmEmailVerification(String email, String code) async {
    try {
      final request = EmailVerificationConfirmRequest(email: email, code: code);
      final response = await _apiClient.confirmEmailVerification(request).timeout(
        _timeoutDuration,
        onTimeout: () => throw TimeoutException('Email verification confirmation timed out'),
      );

      return response;
    } on TimeoutException catch (e) {
      AppLogger.warning('Email verification confirmation timeout: $e', 'RewardsRepository');
      return VerificationResponse(success: false, message: 'Confirmation timed out');
    } catch (e) {
      AppLogger.error('Confirm email verification error', e, null, 'RewardsRepository');
      return VerificationResponse(success: false, message: e.toString());
    }
  }

  Future<VerificationResponse> requestPhoneVerification(String phoneNumber) async {
    try {
      final request = PhoneVerificationRequest(phoneNumber: phoneNumber);
      final response = await _apiClient.requestPhoneVerification(request).timeout(
        _timeoutDuration,
        onTimeout: () => throw TimeoutException('Phone verification request timed out'),
      );

      return response;
    } on TimeoutException catch (e) {
      AppLogger.warning('Phone verification request timeout: $e', 'RewardsRepository');
      return VerificationResponse(success: false, message: 'Request timed out');
    } catch (e) {
      AppLogger.error('Request phone verification error', e, null, 'RewardsRepository');
      return VerificationResponse(success: false, message: e.toString());
    }
  }

  Future<VerificationResponse> confirmPhoneVerification(String phoneNumber, String code) async {
    try {
      final request = PhoneVerificationConfirmRequest(phoneNumber: phoneNumber, code: code);
      final response = await _apiClient.confirmPhoneVerification(request).timeout(
        _timeoutDuration,
        onTimeout: () => throw TimeoutException('Phone verification confirmation timed out'),
      );

      return response;
    } on TimeoutException catch (e) {
      AppLogger.warning('Phone verification confirmation timeout: $e', 'RewardsRepository');
      return VerificationResponse(success: false, message: 'Confirmation timed out');
    } catch (e) {
      AppLogger.error('Confirm phone verification error', e, null, 'RewardsRepository');
      return VerificationResponse(success: false, message: e.toString());
    }
  }

  Future<PointsResponse> awardVerificationPoints(String verificationType) async {
    try {
      final request = {
        'verificationType': verificationType,
        'points': verificationType == 'email' ? 50 : 75, // Email: 50 points, Phone: 75 points
      };
      final response = await _apiClient.awardVerificationPoints(request).timeout(
        _timeoutDuration,
        onTimeout: () => throw TimeoutException('Award points request timed out'),
      );

      return response;
    } on TimeoutException catch (e) {
      AppLogger.warning('Award points request timeout: $e', 'RewardsRepository');
      return PointsResponse(success: false, message: 'Request timed out');
    } catch (e) {
      AppLogger.error('Award verification points error', e, null, 'RewardsRepository');
      return PointsResponse(success: false, message: e.toString());
    }
  }
}


