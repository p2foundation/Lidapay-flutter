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

      if (response.data != null) {
        return response.data!.points;
      }

      // Fallback: some APIs may return points in user profile shape
      AppLogger.warning('PointsResponse.data was null. Returning 0.', 'RewardsRepository');
      return 0;
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
}


