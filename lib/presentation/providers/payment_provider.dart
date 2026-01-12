import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/api_models.dart';
import 'auth_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentRepository(apiClient);
});

final paymentMethodsProvider = FutureProvider<List<ExpressPayMethod>>((ref) async {
  final repository = ref.watch(paymentRepositoryProvider);
  return repository.getPaymentMethods();
});

final paymentStateProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<PaymentData?>>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentNotifier(repository);
});

class PaymentNotifier extends StateNotifier<AsyncValue<PaymentData?>> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> initiatePayment(PaymentRequest request) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.initiatePayment(request);
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> verifyPayment({
    required String transactionId,
    required String paymentReference,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.verifyPayment(
        transactionId: transactionId,
        paymentReference: paymentReference,
      );
      // Update state with verification result
      state = AsyncValue.data(null); // Reset after verification
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

