import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/utils/logger.dart';

class WalletRepository {
  final ApiClient _apiClient;

  WalletRepository(this._apiClient);

  Future<BalanceData> getBalance() async {
    try {
      AppLogger.info('💰 Fetching wallet balance', 'WalletRepository');
      final response = await _apiClient.getBalance();
      if (response.success && response.data != null) {
        AppLogger.info('✅ Balance loaded: ${response.data!.currency} ${response.data!.balance}', 'WalletRepository');
        return response.data!;
      } else {
        AppLogger.error('❌ Balance fetch failed: ${response.message}', null, null, 'WalletRepository');
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('❌ Get balance error', e, null, 'WalletRepository');
      rethrow;
    }
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  throw UnimplementedError('WalletRepository provider must be overridden');
});

