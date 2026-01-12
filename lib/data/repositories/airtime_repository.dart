import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/utils/logger.dart';

class AirtimeRepository {
  final ApiClient _apiClient;

  AirtimeRepository(this._apiClient);

  Future<AirtimeData> purchaseAirtimeReloadly(AirtimeRequest request) async {
    try {
      AppLogger.info('📱 Purchasing airtime via Reloadly: ${request.recipientPhone}, Amount: ${request.amount}', 'AirtimeRepository');
      final response = await _apiClient.purchaseAirtimeReloadly(request);
      if (response.success && response.data != null) {
        AppLogger.info('✅ Airtime purchase successful: ${response.data!.transactionId}', 'AirtimeRepository');
        return response.data!;
      } else {
        AppLogger.error('❌ Airtime purchase failed: ${response.message}', null, null, 'AirtimeRepository');
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('❌ Purchase airtime (Reloadly) error', e, null, 'AirtimeRepository');
      rethrow;
    }
  }

  Future<AirtimeData> purchaseAirtimePrymo(AirtimeRequest request) async {
    try {
      AppLogger.info('📱 Purchasing airtime via Prymo: ${request.recipientPhone}, Amount: ${request.amount}', 'AirtimeRepository');
      final response = await _apiClient.purchaseAirtimePrymo(request);
      if (response.success && response.data != null) {
        AppLogger.info('✅ Airtime purchase successful: ${response.data!.transactionId}', 'AirtimeRepository');
        return response.data!;
      } else {
        AppLogger.error('❌ Airtime purchase failed: ${response.message}', null, null, 'AirtimeRepository');
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('❌ Purchase airtime (Prymo) error', e, null, 'AirtimeRepository');
      rethrow;
    }
  }

  Future<AirtimeData> purchaseAirtime({
    required String recipientPhone,
    required double amount,
    required String countryCode,
    String? operatorId,
    String? note,
    bool isGhana = false,
  }) async {
    final request = AirtimeRequest(
      recipientPhone: recipientPhone,
      amount: amount,
      countryCode: countryCode,
      operatorId: operatorId,
      note: note,
    );

    if (isGhana) {
      return purchaseAirtimePrymo(request);
    } else {
      return purchaseAirtimeReloadly(request);
    }
  }
}

final airtimeRepositoryProvider = Provider<AirtimeRepository>((ref) {
  throw UnimplementedError('AirtimeRepository provider must be overridden');
});

