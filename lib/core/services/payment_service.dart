import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/api_models.dart';
import '../../data/datasources/api_client.dart';
import '../../presentation/providers/auth_provider.dart';
import '../utils/logger.dart';

/// Extract user-friendly error message from DioException
String _extractErrorMessage(dynamic error) {
  if (error is DioException) {
    final response = error.response;
    if (response?.data != null) {
      final data = response!.data;
      if (data is Map<String, dynamic>) {
        // Check for nested message structure
        if (data['message'] is Map) {
          final msg = data['message'] as Map;
          if (msg['message'] != null) {
            return msg['message'].toString();
          }
        }
        // Direct message field
        if (data['message'] is String) {
          return data['message'];
        }
        // Error field
        if (data['error'] is String) {
          return data['error'];
        }
      }
    }
    // Fallback to DioException message
    return error.message ?? 'Network error occurred';
  }
  // Generic error
  return error.toString().replaceAll('Exception: ', '');
}

// Keys for storing pending transaction
const String _pendingTopupKey = 'pending_topup_params';
const String _pendingPaymentTokenKey = 'pending_payment_token';
const String _pendingOrderIdKey = 'pending_order_id';

/// Generates a unique payment reference
String generatePaymentReference() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final uuid = const Uuid().v4().split('-').first.toUpperCase();
  return 'LDP-$timestamp-$uuid';
}

/// Payment flow states
enum PaymentFlowState {
  idle,
  initiating,
  redirecting,
  awaitingCallback,
  crediting,
  success,
  failed,
  cancelled,
}

/// Payment flow result
class PaymentResult {
  final bool success;
  final String message;
  final dynamic data;
  final String? transactionId;
  final String? errorCode;

  PaymentResult({
    required this.success,
    required this.message,
    this.data,
    this.transactionId,
    this.errorCode,
  });
}

/// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref);
});

/// Pending payment state provider
final pendingPaymentProvider = StateProvider<TopupParams?>((ref) => null);

/// Payment flow state provider
final paymentFlowStateProvider = StateProvider<PaymentFlowState>((ref) => PaymentFlowState.idle);

class PaymentService {
  final Ref _ref;
  
  PaymentService(this._ref);

  ApiClient get _apiClient => _ref.read(apiClientProvider);

  /// Store topup params for after-payment crediting
  Future<void> storePendingTopup(TopupParams params) async {
    final prefs = await SharedPreferences.getInstance();
    final paramsJson = jsonEncode(params.toJson());
    await prefs.setString(_pendingTopupKey, paramsJson);
    _ref.read(pendingPaymentProvider.notifier).state = params;
    AppLogger.info('📦 Stored pending topup: ${params.transType}', 'PaymentService');
  }

  /// Retrieve pending topup params
  Future<TopupParams?> getPendingTopup() async {
    final prefs = await SharedPreferences.getInstance();
    final paramsJson = prefs.getString(_pendingTopupKey);
    if (paramsJson != null) {
      try {
        final json = jsonDecode(paramsJson) as Map<String, dynamic>;
        return TopupParams.fromJson(json);
      } catch (e) {
        AppLogger.error('Failed to parse pending topup', e, null, 'PaymentService');
      }
    }
    return null;
  }

  /// Store payment token and order ID for verification
  Future<void> storePaymentInfo(String token, String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPaymentTokenKey, token);
    await prefs.setString(_pendingOrderIdKey, orderId);
    AppLogger.info('🔑 Stored payment info: orderId=$orderId', 'PaymentService');
  }

  /// Get stored payment info
  Future<({String? token, String? orderId})> getPaymentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      token: prefs.getString(_pendingPaymentTokenKey),
      orderId: prefs.getString(_pendingOrderIdKey),
    );
  }

  /// Clear pending payment data
  Future<void> clearPendingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingTopupKey);
    await prefs.remove(_pendingPaymentTokenKey);
    await prefs.remove(_pendingOrderIdKey);
    _ref.read(pendingPaymentProvider.notifier).state = null;
    AppLogger.info('🧹 Cleared pending payment data', 'PaymentService');
  }

  /// Initiate payment with AdvansiPay and open checkout URL
  Future<PaymentResult> initiatePayment({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String username,
    required double amount,
    required String orderDesc,
    required TopupParams topupParams,
  }) async {
    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.initiating;
    
    try {
      // Generate unique order ID
      final orderId = generatePaymentReference();
      
      // Store topup params for after-payment crediting
      await storePendingTopup(topupParams);

      AppLogger.info('💳 Initiating payment: $orderId, amount: $amount', 'PaymentService');

      // Call AdvansiPay initiate-payment API
      final response = await _apiClient.initiateAdvansiPay(
        AdvansiPayInitRequest(
          userId: userId,
          firstName: firstName,
          lastName: lastName,
          email: email,
          phoneNumber: phoneNumber,
          username: username,
          amount: amount,
          orderDesc: orderDesc,
          orderId: orderId,
        ),
      );

      if (response.status == 201 && response.data != null) {
        final checkoutUrl = response.data!.checkoutUrl;
        final token = response.data!.token;
        final serverOrderId = response.data!.orderId;

        // Store payment info
        await storePaymentInfo(token, serverOrderId);

        AppLogger.info('✅ Payment initiated, checkoutUrl: $checkoutUrl', 'PaymentService');

        // Update state
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.redirecting;

        // Launch checkout URL
        final uri = Uri.parse(checkoutUrl);
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.awaitingCallback;
          return PaymentResult(
            success: true,
            message: 'Payment initiated. Please complete payment in the browser.',
            data: response.data,
            transactionId: serverOrderId,
          );
        } else {
          _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
          return PaymentResult(
            success: false,
            message: 'Could not open payment page. Please try again.',
            errorCode: 'LAUNCH_FAILED',
          );
        }
      } else {
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: response.message,
          errorCode: 'INIT_FAILED',
        );
      }
    } catch (e) {
      AppLogger.error('Payment initiation failed', e, null, 'PaymentService');
      _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
      return PaymentResult(
        success: false,
        message: _extractErrorMessage(e),
        errorCode: 'EXCEPTION',
      );
    }
  }

  /// Credit airtime after successful payment
  Future<PaymentResult> creditAirtime({
    required String userId,
    required TopupParams params,
  }) async {
    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.crediting;

    try {
      AppLogger.info('📱 Crediting airtime for ${params.recipientNumber}', 'PaymentService');

      final response = await _apiClient.rechargeAirtime(
        AirtimeRechargeRequest(
          userId: userId,
          operatorId: params.operatorId,
          amount: params.amount,
          customIdentifier: params.customIdentifier ?? 'reloadly-airtime ${DateTime.now().millisecondsSinceEpoch}',
          recipientEmail: params.recipientEmail,
          recipientNumber: params.recipientNumber,
          recipientCountryCode: params.recipientCountryCode,
          senderNumber: params.senderNumber,
          senderCountryCode: params.senderCountryCode,
        ),
      );

      // Check if status is SUCCESSFUL (not using .success field as it doesn't exist)
      if (response.status.toUpperCase() == 'SUCCESSFUL') {
        await clearPendingPayment();
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.success;
        return PaymentResult(
          success: true,
          message: 'Airtime credited successfully!',
          data: response,
          transactionId: response.transactionId.toString(),
        );
      } else {
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: 'Airtime credit failed: ${response.status}',
          errorCode: 'CREDIT_FAILED',
        );
      }
    } catch (e) {
      AppLogger.error('Airtime crediting failed', e, null, 'PaymentService');
      _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
      return PaymentResult(
        success: false,
        message: _extractErrorMessage(e),
        errorCode: 'EXCEPTION',
      );
    }
  }

  /// Credit data bundle after successful payment
  Future<PaymentResult> creditData({
    required String userId,
    required TopupParams params,
  }) async {
    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.crediting;

    try {
      AppLogger.info('📶 Crediting data for ${params.recipientNumber}', 'PaymentService');

      final response = await _apiClient.buyData(
        DataPurchaseRequest(
          userId: userId,
          operatorId: params.operatorId,
          recipientNumber: params.recipientNumber,
          recipientCountryCode: params.recipientCountryCode,
          senderNumber: params.senderNumber,
          senderCountryCode: params.senderCountryCode,
          recipientEmail: params.recipientEmail,
          customIdentifier: params.customIdentifier ?? 'reloadly-data ${DateTime.now().millisecondsSinceEpoch}',
          bundleId: params.bundleId ?? 0,
          amount: params.amount,
          userName: params.senderNumber, // Required by API - user's phone number
        ),
      );

      // Check if status is SUCCESSFUL (not using .success field as it doesn't exist)
      if (response.status.toUpperCase() == 'SUCCESSFUL') {
        await clearPendingPayment();
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.success;
        return PaymentResult(
          success: true,
          message: 'Data bundle credited successfully!',
          data: response,
          transactionId: response.transactionId.toString(),
        );
      } else {
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: 'Data bundle credit failed: ${response.status}',
          errorCode: 'CREDIT_FAILED',
        );
      }
    } catch (e) {
      AppLogger.error('Data crediting failed', e, null, 'PaymentService');
      _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
      return PaymentResult(
        success: false,
        message: _extractErrorMessage(e),
        errorCode: 'EXCEPTION',
      );
    }
  }

  /// Query payment transaction status using token with retry support
  /// Retries up to [maxRetries] times with [retryDelaySeconds] delay between attempts
  /// This handles USSD payment delays from Telcos
  Future<PaymentResult> queryPaymentStatus(
    String token, {
    int maxRetries = 3,
    int retryDelaySeconds = 3,
  }) async {
    PaymentResult? lastResult;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.info('🔍 Querying payment status (attempt $attempt/$maxRetries) with token: ${token.substring(0, 10)}...', 'PaymentService');
        
        final response = await _apiClient.queryAdvansiPayTransaction(
          AdvansiPayQueryRequest(token: token),
        );

        // Check for successful response (status 200/201 with data)
        if ((response.status == 200 || response.status == 201) && response.data != null) {
          final paymentStatus = response.data!.status?.toUpperCase() ?? 'UNKNOWN';
          final resultText = response.data!.resultText?.toLowerCase() ?? '';
          
          AppLogger.info('✅ Payment query result: status=$paymentStatus, resultText=$resultText', 'PaymentService');
          
          // Check for COMPLETED status or Success resultText
          final isSuccess = paymentStatus == 'COMPLETED' || 
                            paymentStatus == 'APPROVED' || 
                            paymentStatus == 'SUCCESS' ||
                            resultText == 'success';
          
          if (isSuccess) {
            // Payment confirmed - return immediately
            return PaymentResult(
              success: true,
              message: 'Payment verified successfully!',
              data: response.data,
              transactionId: response.data!.transactionId ?? response.data!.orderId,
            );
          }
          
          // Payment not yet completed - store result and maybe retry
          lastResult = PaymentResult(
            success: false,
            message: 'Payment status: $paymentStatus',
            data: response.data,
            transactionId: response.data!.transactionId ?? response.data!.orderId,
          );
        }

        // Check for QUERY_FAILED in message (error case)
        if (response.message.contains('QUERY_FAILED')) {
          AppLogger.warning('⚠️ Payment query failed (attempt $attempt): ${response.message}', 'PaymentService');
          lastResult = PaymentResult(
            success: false,
            message: 'Payment verification failed. Please try again or contact support.',
            errorCode: 'QUERY_FAILED',
          );
        }
        
      } catch (e) {
        AppLogger.error('Payment status query failed (attempt $attempt)', e, null, 'PaymentService');
        
        final errorMessage = _extractErrorMessage(e);
        lastResult = PaymentResult(
          success: false,
          message: errorMessage.contains('QUERY_FAILED') 
              ? 'Payment verification failed. Please try again.'
              : errorMessage,
          errorCode: errorMessage.contains('QUERY_FAILED') ? 'QUERY_FAILED' : 'QUERY_EXCEPTION',
        );
      }
      
      // If not the last attempt and payment not confirmed, wait and retry
      if (attempt < maxRetries) {
        AppLogger.info('⏳ Waiting ${retryDelaySeconds}s before retry (USSD may be processing)...', 'PaymentService');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
      }
    }
    
    // All retries exhausted - return last result
    AppLogger.warning('⚠️ Payment verification failed after $maxRetries attempts', 'PaymentService');
    return lastResult ?? PaymentResult(
      success: false,
      message: 'Payment verification failed after multiple attempts.',
      errorCode: 'MAX_RETRIES_EXCEEDED',
    );
  }

  /// Handle payment callback from deep link
  Future<PaymentResult> handlePaymentCallback({
    required String status,
    String? token,
    String? orderId,
  }) async {
    AppLogger.info('🔙 Payment callback: status=$status, orderId=$orderId, hasToken=${token != null}', 'PaymentService');

    // Get pending topup params
    final topupParams = await getPendingTopup();
    if (topupParams == null) {
      return PaymentResult(
        success: false,
        message: 'No pending payment found.',
        errorCode: 'NO_PENDING',
      );
    }

    // If we have a token, verify payment status via API first
    if (token != null && token.isNotEmpty) {
      AppLogger.info('🔐 Verifying payment with token...', 'PaymentService');
      
      final queryResult = await queryPaymentStatus(token);
      
      if (!queryResult.success) {
        // Payment verification failed
        await clearPendingPayment();
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: queryResult.message.isNotEmpty 
              ? queryResult.message 
              : 'Payment verification failed. Please try again.',
          errorCode: queryResult.errorCode ?? 'VERIFICATION_FAILED',
        );
      }
      
      // Payment verified successfully - proceed to credit
      AppLogger.info('✅ Payment verified successfully, proceeding to credit...', 'PaymentService');
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (topupParams.transType == 'GLOBALAIRTOPUP') {
        return creditAirtime(userId: userId, params: topupParams);
      } else if (topupParams.transType == 'GLOBALDATATOPUP') {
        return creditData(userId: userId, params: topupParams);
      } else {
        return PaymentResult(
          success: false,
          message: 'Unknown transaction type: ${topupParams.transType}',
          errorCode: 'UNKNOWN_TYPE',
        );
      }
    }

    // Fallback: Check payment status from callback parameter
    if (status.toLowerCase() == 'success' || status.toLowerCase() == 'approved') {
      // Credit based on transaction type
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';

      if (topupParams.transType == 'GLOBALAIRTOPUP') {
        return creditAirtime(userId: userId, params: topupParams);
      } else if (topupParams.transType == 'GLOBALDATATOPUP') {
        return creditData(userId: userId, params: topupParams);
      } else {
        return PaymentResult(
          success: false,
          message: 'Unknown transaction type: ${topupParams.transType}',
          errorCode: 'UNKNOWN_TYPE',
        );
      }
    } else if (status.toLowerCase() == 'cancelled') {
      await clearPendingPayment();
      _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.cancelled;
      return PaymentResult(
        success: false,
        message: 'Payment was cancelled.',
        errorCode: 'CANCELLED',
      );
    } else if (status.toLowerCase() == 'pending') {
      // For pending status without token, we can't verify
      return PaymentResult(
        success: false,
        message: 'Payment verification pending. Please wait...',
        errorCode: 'PENDING',
      );
    } else {
      await clearPendingPayment();
      _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
      return PaymentResult(
        success: false,
        message: 'Payment failed: $status',
        errorCode: 'FAILED',
      );
    }
  }

  /// Reset payment flow state
  void resetState() {
    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.idle;
  }
}

