import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/statistics_repository.dart';
import '../../data/models/api_models.dart';
import 'auth_provider.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatisticsRepository(apiClient);
});

final statisticsProvider = FutureProvider<StatisticsData>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getStatistics();
});

