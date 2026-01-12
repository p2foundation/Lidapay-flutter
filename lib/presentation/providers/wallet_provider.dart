import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/models/api_models.dart';
import 'auth_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRepository(apiClient);
});

final balanceProvider = FutureProvider<BalanceData>((ref) async {
  final repository = ref.watch(walletRepositoryProvider);
  try {
    return await repository.getBalance().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        // Return default balance on timeout
        return const BalanceData(balance: 0.0, currency: 'GHS');
      },
    );
  } catch (e) {
    // Return default balance on error
    return const BalanceData(balance: 0.0, currency: 'GHS');
  }
});

