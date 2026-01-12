import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/data_repository.dart';
import '../../data/models/api_models.dart';
import 'auth_provider.dart';

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DataRepository(apiClient);
});

final dataPurchaseProvider = StateNotifierProvider<DataPurchaseNotifier, AsyncValue<DataData?>>((ref) {
  final repository = ref.watch(dataRepositoryProvider);
  return DataPurchaseNotifier(repository);
});

class DataPurchaseNotifier extends StateNotifier<AsyncValue<DataData?>> {
  final DataRepository _repository;

  DataPurchaseNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> purchaseData({
    required String recipientPhone,
    required double dataAmount,
    required String countryCode,
    String? operatorId,
    String? dataPlanId,
    bool isGhana = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.purchaseData(
        recipientPhone: recipientPhone,
        dataAmount: dataAmount,
        countryCode: countryCode,
        operatorId: operatorId,
        dataPlanId: dataPlanId,
        isGhana: isGhana,
      );
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

