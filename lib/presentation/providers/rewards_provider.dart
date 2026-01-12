import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/rewards_repository.dart';
import '../../data/models/api_models.dart';
import 'auth_provider.dart';

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RewardsRepository(apiClient);
});

final userPointsProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(rewardsRepositoryProvider);
  return repo.getUserPoints();
});

final rewardsCatalogProvider = FutureProvider<List<Reward>>((ref) async {
  final repo = ref.watch(rewardsRepositoryProvider);
  return repo.getRewardsCatalog();
});


