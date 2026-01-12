import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/utils/logger.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  Future<PaymentData> initiatePayment(PaymentRequest request) async {
    try {
      final response = await _apiClient.initiateExpressPayPayment(request);
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('Initiate payment error', e);
      rethrow;
    }
  }

  Future<PaymentVerificationData> verifyPayment({
    required String transactionId,
    required String paymentReference,
  }) async {
    try {
      final response = await _apiClient.verifyExpressPayPayment(
        PaymentVerificationRequest(
          transactionId: transactionId,
          paymentReference: paymentReference,
        ),
      );
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('Verify payment error', e);
      rethrow;
    }
  }

  Future<List<ExpressPayMethod>> getPaymentMethods() async {
    try {
      final response = await _apiClient.getExpressPayMethods();
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('Get payment methods error', e);
      rethrow;
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  throw UnimplementedError('PaymentRepository provider must be overridden');
});

