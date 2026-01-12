import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/airtime_repository.dart';
import '../../data/models/api_models.dart';
import 'auth_provider.dart';

final airtimeRepositoryProvider = Provider<AirtimeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AirtimeRepository(apiClient);
});

final airtimePurchaseProvider = StateNotifierProvider<AirtimePurchaseNotifier, AsyncValue<AirtimeData?>>((ref) {
  final repository = ref.watch(airtimeRepositoryProvider);
  return AirtimePurchaseNotifier(repository);
});

class AirtimePurchaseNotifier extends StateNotifier<AsyncValue<AirtimeData?>> {
  final AirtimeRepository _repository;

  AirtimePurchaseNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> purchaseAirtime({
    required String recipientPhone,
    required double amount,
    required String countryCode,
    String? operatorId,
    String? note,
    bool isGhana = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.purchaseAirtime(
        recipientPhone: recipientPhone,
        amount: amount,
        countryCode: countryCode,
        operatorId: operatorId,
        note: note,
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

