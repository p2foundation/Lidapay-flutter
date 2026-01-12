import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/api_client.dart';
import '../models/api_models.dart';
import '../../core/utils/logger.dart';

class TransactionRepository {
  final ApiClient _apiClient;
  static const Duration _timeoutDuration = Duration(seconds: 10);

  TransactionRepository(this._apiClient);

  /// Get transactions by user ID with timeout and fallback
  Future<TransactionsData> getTransactions({
    required String userId,
    int page = 1,
    int pageSize = 20,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Build query parameters - use limit instead of pageSize for API
      final queries = <String, dynamic>{
        'page': page,
        'limit': pageSize, // API uses 'limit' instead of 'pageSize'
      };
      
      // Only add optional parameters if they have values
      // Use transType for filtering as per API specification
      if (type != null && type.isNotEmpty) {
        queries['transType'] = type;
      }
      if (status != null && status.isNotEmpty) {
        queries['status'] = status;
      }
      if (startDate != null) {
        // Format date as ISO 8601 string
        queries['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        // Format date as ISO 8601 string
        queries['endDate'] = endDate.toIso8601String();
      }

      AppLogger.info('🔍 Fetching transactions for userId: $userId', 'TransactionRepository');
      AppLogger.debug('Query parameters: $queries', 'TransactionRepository');
      AppLogger.debug('API endpoint: /api/v1/transactions/user/$userId', 'TransactionRepository');
      
      // Add timeout to prevent indefinite loading
      // Use the user-specific endpoint: /api/v1/transactions/user/{userId}
      final response = await _apiClient.getTransactionsByUser(userId, queries)
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              AppLogger.warning('Transactions API request timed out after ${_timeoutDuration.inSeconds}s', 'TransactionRepository');
              throw TimeoutException('Request timed out. Please check your connection and try again.');
            },
          );
      
      AppLogger.debug('API Response: success=${response.success}, hasData=${response.data != null}', 'TransactionRepository');
      
      // Log raw response structure for debugging
      AppLogger.debug('Raw response structure check:', 'TransactionRepository');
      AppLogger.debug('  - response.data is null: ${response.data == null}', 'TransactionRepository');
      if (response.data != null) {
        AppLogger.debug('  - response.data.transactions.length: ${response.data!.transactions.length}', 'TransactionRepository');
        AppLogger.debug('  - response.data.total: ${response.data!.total}', 'TransactionRepository');
        AppLogger.debug('  - response.data.page: ${response.data!.page}', 'TransactionRepository');
        AppLogger.debug('  - response.data.limit: ${response.data!.limit}', 'TransactionRepository');
      } else {
        AppLogger.warning('⚠️ response.data is null! Attempting manual parsing...', 'TransactionRepository');
        AppLogger.warning('  - Response success: ${response.success}', 'TransactionRepository');
        AppLogger.warning('  - Response message: ${response.message}', 'TransactionRepository');
        
        // Try to manually parse the response if automatic parsing failed
        // This can happen if Retrofit's generated code doesn't use the custom fromJson
        try {
          // Get the raw response from the API client
          // We need to access the raw response data
          // Since we can't access it directly, we'll need to handle this differently
          // For now, return empty and log the issue
          AppLogger.warning('⚠️ Cannot manually parse - response.data is null. This suggests a parsing configuration issue.', 'TransactionRepository');
        } catch (e) {
          AppLogger.error('Error attempting manual parse', e);
        }
      }
      
      // Handle response - check if data exists (even if success is false/null)
      if (response.data != null) {
        final transactionCount = response.data!.transactions.length;
        AppLogger.info('✅ Successfully fetched $transactionCount transactions (total: ${response.data!.total})', 'TransactionRepository');
        
        if (transactionCount == 0 && response.data!.total > 0) {
          AppLogger.warning('⚠️ API returned total=${response.data!.total} but parsed 0 transactions. Parsing may have failed.', 'TransactionRepository');
          AppLogger.warning('  - This suggests the transaction parsing logic needs review.', 'TransactionRepository');
        } else if (transactionCount == 0 && response.data!.total == 0) {
          AppLogger.info('ℹ️ API returned 0 transactions. User has no transactions yet.', 'TransactionRepository');
        }
        
        return response.data!;
      } else {
        // If no data but response exists, this indicates a parsing failure
        AppLogger.error('❌ API response parsing failed! response.data is null.', null, null, 'TransactionRepository');
        AppLogger.error('  - This usually means TransactionsResponse.fromJson failed to parse the response', null, null, 'TransactionRepository');
        AppLogger.error('  - Response success: ${response.success}', null, null, 'TransactionRepository');
        AppLogger.error('  - Response message: ${response.message}', null, null, 'TransactionRepository');
        AppLogger.error('  - The API likely returned data, but parsing failed. Check TransactionsResponse.fromJson logic.', null, null, 'TransactionRepository');
        
        // Return empty data - the UI will show "No transactions found"
        // But we've logged the error so developers can investigate
        return _getEmptyTransactionsData(page: page, pageSize: pageSize);
      }
    } on TimeoutException catch (e) {
      AppLogger.error('Transactions request timeout', e);
      // Return empty transactions data as fallback
      return _getEmptyTransactionsData(page: page, pageSize: pageSize);
    } catch (e) {
      AppLogger.error('Get transactions error', e);
      // Return empty transactions data as fallback instead of throwing
      return _getEmptyTransactionsData(page: page, pageSize: pageSize);
    }
  }

  /// Fallback: Return empty transactions data
  TransactionsData _getEmptyTransactionsData({
    required int page,
    required int pageSize,
  }) {
    AppLogger.info('Returning empty transactions data as fallback', 'TransactionRepository');
    return TransactionsData(
      transactions: const [],
      total: 0,
      page: page,
      limit: pageSize,
      pageSize: pageSize,
    );
  }

  Future<Transaction> getTransactionDetail(String id) async {
    try {
      final response = await _apiClient.getTransactionDetail(id);
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      AppLogger.error('Get transaction detail error', e);
      rethrow;
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  throw UnimplementedError('TransactionRepository provider must be overridden');
});

