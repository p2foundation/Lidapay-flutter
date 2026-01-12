import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/models/api_models.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'auth_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionRepository(apiClient);
});

// Pagination state
class TransactionsState {
  final List<Transaction> transactions;
  final int currentPage;
  final int total;
  final int pageSize;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? transType; // Filter by transType
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionsState({
    this.transactions = const [],
    this.currentPage = 1,
    this.total = 0,
    this.pageSize = 10,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.transType,
    this.status,
    this.startDate,
    this.endDate,
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    int? currentPage,
    int? total,
    int? pageSize,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? transType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearError = false,
    bool clearTransactions = false,
  }) {
    return TransactionsState(
      transactions: clearTransactions ? const [] : (transactions ?? this.transactions),
      currentPage: currentPage ?? this.currentPage,
      total: total ?? this.total,
      pageSize: pageSize ?? this.pageSize,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      transType: transType ?? this.transType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// StateNotifier for paginated transactions
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionRepository _repository;
  final SharedPreferences _prefs;
  final Ref _ref;
  bool _isLoadingFilter = false; // Guard to prevent multiple simultaneous filter loads

  TransactionsNotifier(this._repository, this._prefs, this._ref) : super(TransactionsState());

  /// Get userId from SharedPreferences or current user profile
  /// This ensures userId is dynamic based on the logged-in user
  Future<String?> _getUserId() async {
    // Try to get from SharedPreferences first (faster)
    // This is set during login in AuthRepository
    var userId = _prefs.getString(AppConstants.userIdKey);
    if (userId != null && userId.isNotEmpty) {
      AppLogger.debug('✅ Retrieved userId from SharedPreferences: $userId', 'TransactionsNotifier');
      return userId;
    }
    
    // Fallback: Try to get from user profile API
    // This ensures we always have the current logged-in user's ID
    AppLogger.info('ℹ️ userId not in SharedPreferences, fetching from user profile...', 'TransactionsNotifier');
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      
      // Get user profile to retrieve userId
      final user = await authRepo.getUserProfile();
      userId = user.id;
      
      if (userId != null && userId.isNotEmpty) {
        // Save to SharedPreferences for future use
        await _prefs.setString(AppConstants.userIdKey, userId);
        AppLogger.info('✅ Retrieved and saved userId from user profile: $userId', 'TransactionsNotifier');
        return userId;
      }
    } catch (e) {
      AppLogger.warning('⚠️ Failed to get userId from user profile: $e', 'TransactionsNotifier');
    }
    
    AppLogger.warning('⚠️ userId not found. User may need to login again.', 'TransactionsNotifier');
    return null;
  }

  Future<void> loadTransactions({
    bool refresh = false,
    String? transType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Get userId - required for the API endpoint
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      AppLogger.warning('⚠️ User ID not found in SharedPreferences. User may need to login again.', 'TransactionsNotifier');
      state = state.copyWith(
        isLoading: false,
        error: 'User ID not found. Please login again.',
      );
      return;
    }
    AppLogger.debug('✅ Using userId from SharedPreferences: $userId', 'TransactionsNotifier');

    // If filtering changed, reset pagination
    if (transType != state.transType || 
        status != state.status || 
        startDate != state.startDate || 
        endDate != state.endDate) {
      state = state.copyWith(
        currentPage: 1,
        transactions: const [],
        hasMore: true,
        transType: transType,
        status: status,
        startDate: startDate,
        endDate: endDate,
        clearError: true,
      );
    }

    // If refreshing, reset to page 1
    if (refresh) {
      state = state.copyWith(
        currentPage: 1,
        transactions: const [],
        hasMore: true,
        clearError: true,
        clearTransactions: true,
      );
    }

    // Don't load if already loading
    // Allow loading if:
    // - refresh is true (explicit refresh)
    // - transactions is empty (first load)
    // - hasMore is true (more pages available)
    // Also prevent loading if total is 0 and we've already checked (to prevent infinite loops)
    if (state.isLoading || 
        (!state.hasMore && !refresh && state.transactions.isNotEmpty) ||
        (state.total == 0 && state.transactions.isEmpty && !refresh && state.currentPage > 1)) {
      AppLogger.debug('⏸️ Skipping load: isLoading=${state.isLoading}, hasMore=${state.hasMore}, refresh=$refresh, transactionsCount=${state.transactions.length}, total=${state.total}, currentPage=${state.currentPage}', 'TransactionsNotifier');
      return;
    }

    final pageToLoad = refresh ? 1 : state.currentPage;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getTransactions(
        userId: userId,
        page: pageToLoad,
        pageSize: state.pageSize,
        type: state.transType ?? transType,
        status: state.status ?? status,
        startDate: state.startDate ?? startDate,
        endDate: state.endDate ?? endDate,
      );

      final newTransactions = refresh
          ? result.transactions
          : [...state.transactions, ...result.transactions];

      // Calculate hasMore: true if there are more transactions to load
      // If total is 0, hasMore should be false
      // If we've loaded all transactions (newTransactions.length >= total), hasMore should be false
      final hasMore = result.total > 0 && newTransactions.length < result.total;
      final effectivePageSize = result.limit ?? result.pageSize ?? state.pageSize;
      
      // Only increment page if there are more pages to load
      // If total is 0, always reset to page 1 to prevent infinite loops
      // If hasMore is false but total > 0, keep current page (we've loaded all available)
      final nextPage = result.total == 0 
          ? 1 
          : (hasMore ? (pageToLoad + 1) : pageToLoad);
      
      AppLogger.info(
        '📊 Loaded ${result.transactions.length} transactions (page $pageToLoad). Total: ${result.total}, Has more: $hasMore, Current count: ${newTransactions.length}, Next page: $nextPage',
        'TransactionsNotifier',
      );

      state = state.copyWith(
        transactions: newTransactions,
        currentPage: nextPage,
        total: result.total,
        pageSize: effectivePageSize,
        isLoading: false,
        hasMore: hasMore,
        transType: state.transType ?? transType,
        status: state.status ?? status,
        startDate: state.startDate ?? startDate,
        endDate: state.endDate ?? endDate,
      );
    } catch (e) {
      AppLogger.error('Error loading transactions', e, null, 'TransactionsNotifier');
      // On error, preserve hasMore state to allow retry
      // Only set hasMore to false if we have no transactions and this was the first load
      final shouldSetHasMoreFalse = state.transactions.isEmpty && state.currentPage == 1;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasMore: shouldSetHasMoreFalse ? false : state.hasMore,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadTransactions();
  }

  Future<void> refresh() async {
    await loadTransactions(refresh: true);
  }

  void setFilter({String? transType, String? status, DateTime? startDate, DateTime? endDate}) {
    // Only update filter if it actually changed
    if (transType == state.transType && 
        status == state.status && 
        startDate == state.startDate && 
        endDate == state.endDate) {
      return; // Filter hasn't changed, don't reload
    }
    
    // Prevent multiple simultaneous filter loads
    if (_isLoadingFilter || state.isLoading) {
      return; // Already loading, don't start another load
    }
    
    _isLoadingFilter = true;
    
    // Reset to page 1 and clear existing transactions when filter changes
    state = state.copyWith(
      currentPage: 1,
      transactions: const [],
      hasMore: true, // Will be set correctly after load
      transType: transType,
      status: status,
      startDate: startDate,
      endDate: endDate,
      clearError: true,
    );
    
    loadTransactions(transType: transType, status: status, startDate: startDate, endDate: endDate).then((_) {
      _isLoadingFilter = false;
    }).catchError((_) {
      _isLoadingFilter = false;
    });
  }
}

// Provider for transactions state
final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return TransactionsNotifier(repository, prefs, ref);
});

// Legacy provider for backward compatibility
final transactionsProvider = FutureProvider.family<TransactionsData, TransactionsParams>((ref, params) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  // Get userId from SharedPreferences
  final userId = prefs.getString(AppConstants.userIdKey);
  if (userId == null || userId.isEmpty) {
    // Return empty data if userId not found
    return TransactionsData(
      transactions: const [],
      total: 0,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
  
  try {
    return await repository.getTransactions(
      userId: userId,
      page: params.page,
      pageSize: params.pageSize,
      type: params.type,
      status: params.status,
      startDate: params.startDate,
      endDate: params.endDate,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        // Return empty data on timeout
        return TransactionsData(
          transactions: const [],
          total: 0,
          page: params.page,
          pageSize: params.pageSize,
        );
      },
    );
  } catch (e) {
    // If repository throws (shouldn't happen now with fallback, but just in case)
    // Return empty data as fallback
    return TransactionsData(
      transactions: const [],
      total: 0,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
});

class TransactionsParams {
  final int page;
  final int pageSize;
  final String? type;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionsParams({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.status,
    this.startDate,
    this.endDate,
  });
}

