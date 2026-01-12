import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/utils/logger.dart';

class StatisticsRepository {
  final ApiClient _apiClient;

  StatisticsRepository(this._apiClient);

  Future<StatisticsData> getStatistics({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queries = <String, dynamic>{};
      if (period != null) queries['period'] = period;
      if (startDate != null) queries['startDate'] = startDate.toIso8601String();
      if (endDate != null) queries['endDate'] = endDate.toIso8601String();

      final response = await _apiClient.getStatistics(queries);
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('Get statistics error', e);
      rethrow;
    }
  }
}

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  throw UnimplementedError('StatisticsRepository provider must be overridden');
});

