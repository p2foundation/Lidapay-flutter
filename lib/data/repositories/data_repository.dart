import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/utils/logger.dart';

class DataRepository {
  final ApiClient _apiClient;

  DataRepository(this._apiClient);

  Future<DataData> purchaseDataReloadly(DataRequest request) async {
    try {
      final response = await _apiClient.purchaseDataReloadly(request);
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('Purchase data (Reloadly) error', e);
      rethrow;
    }
  }

  Future<DataData> purchaseDataPrymo(DataRequest request) async {
    try {
      final response = await _apiClient.purchaseDataPrymo(request);
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('Purchase data (Prymo) error', e);
      rethrow;
    }
  }

  Future<DataData> purchaseData({
    required String recipientPhone,
    required double dataAmount,
    required String countryCode,
    String? operatorId,
    String? dataPlanId,
    bool isGhana = false,
  }) async {
    final request = DataRequest(
      recipientPhone: recipientPhone,
      dataAmount: dataAmount,
      countryCode: countryCode,
      operatorId: operatorId,
      dataPlanId: dataPlanId,
    );

    if (isGhana) {
      return purchaseDataPrymo(request);
    } else {
      return purchaseDataReloadly(request);
    }
  }
}

final dataRepositoryProvider = Provider<DataRepository>((ref) {
  throw UnimplementedError('DataRepository provider must be overridden');
});

