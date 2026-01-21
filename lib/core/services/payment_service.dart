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
import '../utils/ghana_network_codes.dart';
import '../utils/logger.dart';
import '../../core/constants/app_constants.dart';

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
const String _paymentDisplayInfoKey = 'payment_display_info';

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

class PaymentDisplayInfo {
  final double topupAmount;
  final String topupCurrency;
  final double paymentAmount;
  final String paymentCurrency;

  PaymentDisplayInfo({
    required this.topupAmount,
    required this.topupCurrency,
    required this.paymentAmount,
    required this.paymentCurrency,
  });

  factory PaymentDisplayInfo.fromJson(Map<String, dynamic> json) {
    return PaymentDisplayInfo(
      topupAmount: (json['topupAmount'] as num?)?.toDouble() ?? 0.0,
      topupCurrency: json['topupCurrency'] as String? ?? 'USD',
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      paymentCurrency: json['paymentCurrency'] as String? ?? 'GHS',
    );
  }

  Map<String, dynamic> toJson() => {
        'topupAmount': topupAmount,
        'topupCurrency': topupCurrency,
        'paymentAmount': paymentAmount,
        'paymentCurrency': paymentCurrency,
      };
}

/// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref);
});

final paymentDisplayInfoProvider = FutureProvider<Map<String, PaymentDisplayInfo>>((ref) {
  return ref.read(paymentServiceProvider).getPaymentDisplayInfoMap();
});

/// Pending payment state provider
final pendingPaymentProvider = StateProvider<TopupParams?>((ref) => null);

/// Payment flow state provider
final paymentFlowStateProvider = StateProvider<PaymentFlowState>((ref) => PaymentFlowState.idle);

class PaymentService {
  final Ref _ref;
  
  PaymentService(this._ref);

  ApiClient get _apiClient => _ref.read(apiClientProvider);
  
  ApiClient get _prymoApiClient {
    final prefs = _ref.read(sharedPreferencesProvider);
    final dio = DioClient.createPrymoDio(
      getToken: () async => prefs.getString(AppConstants.authTokenKey),
    );
    return ApiClient.prymoCredit(dio);
  }

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

  Future<void> storePaymentDisplayInfo(
    String? reference, {
    required double topupAmount,
    required String topupCurrency,
    required double paymentAmount,
    required String paymentCurrency,
  }) async {
    if (reference == null || reference.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_paymentDisplayInfoKey);
    Map<String, dynamic> store = {};
    if (raw != null) {
      try {
        store = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    store[reference] = PaymentDisplayInfo(
      topupAmount: topupAmount,
      topupCurrency: topupCurrency,
      paymentAmount: paymentAmount,
      paymentCurrency: paymentCurrency,
    ).toJson();
    await prefs.setString(_paymentDisplayInfoKey, jsonEncode(store));
  }

  Future<Map<String, PaymentDisplayInfo>> getPaymentDisplayInfoMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_paymentDisplayInfoKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          PaymentDisplayInfo.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<PaymentDisplayInfo?> getPaymentDisplayInfo(String? reference) async {
    if (reference == null || reference.isEmpty) return null;
    final map = await getPaymentDisplayInfoMap();
    return map[reference];
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

    const maxAttempts = 3;

    // Check if this is a Ghana transaction and use prymo credit endpoint if enabled
    if (params.recipientCountryCode == 'GH' && AppConstants.usePrymoForGhanaAirtime) {
      return await _creditAirtimeGhana(params, maxAttempts);
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final customIdentifier =
            (params.customIdentifier?.isNotEmpty ?? false) ? params.customIdentifier! : params.payTransRef;
        AppLogger.info(
          '📱 Crediting airtime for ${params.recipientNumber} (attempt $attempt/$maxAttempts)',
          'PaymentService',
        );

        final response = await _apiClient.rechargeAirtime(
          AirtimeRechargeRequest(
            userId: userId,
            operatorId: params.operatorId,
            amount: params.amount,
            customIdentifier: customIdentifier,
            recipientEmail: params.recipientEmail,
            recipientNumber: params.recipientNumber,
            recipientCountryCode: params.recipientCountryCode,
            senderNumber: params.senderNumber,
            senderCountryCode: params.senderCountryCode,
          ),
        );

        final status = response.status.toUpperCase();

        // Check if status is SUCCESSFUL (not using .success field as it doesn't exist)
        if (status == 'SUCCESSFUL') {
          await clearPendingPayment();
          _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.success;
          return PaymentResult(
            success: true,
            message: 'Airtime top-up successful.',
            data: response,
            transactionId: response.transactionId.toString(),
          );
        }

        if ((status == 'PENDING' || status == 'PROCESSING') && attempt < maxAttempts) {
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }

        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: 'Airtime top-up failed. Please check your balance or try again.',
          errorCode: 'CREDIT_FAILED',
        );
      } catch (e) {
        final rawMessage = _extractErrorMessage(e);
        final shouldRetry = attempt < maxAttempts && _isRetryableTopupError(rawMessage);
        if (shouldRetry) {
          AppLogger.warning(
            '⏳ Airtime crediting retry $attempt/$maxAttempts: $rawMessage',
            'PaymentService',
          );
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }
        AppLogger.error('Airtime crediting failed', e, null, 'PaymentService');
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: _sanitizeTopupMessage(rawMessage),
          errorCode: 'EXCEPTION',
        );
      }
    }

    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
    return PaymentResult(
      success: false,
      message: _sanitizeTopupMessage('Top-up failed. Please try again later.'),
      errorCode: 'MAX_RETRIES_EXCEEDED',
    );
  }

  /// Credit airtime for Ghana using prymo credit endpoint
  Future<PaymentResult> _creditAirtimeGhana(TopupParams params, int maxAttempts) async {
    // Use the network code from the operator data (from auto-detection)
    final network = GhanaNetworkCodes.fromOperatorId(params.operatorId);
    
    AppLogger.info('📱 Using network code: $network (${GhanaNetworkCodes.getNetworkName(network)}) for airtime credit', 'PaymentService');
    
    // Remove country code from recipient number for Ghana
    String recipientNumber = params.recipientNumber;
    if (recipientNumber.startsWith('233')) {
      recipientNumber = '0' + recipientNumber.substring(3);
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        AppLogger.info(
          '📱 Crediting airtime for Ghana via prymo credit (attempt $attempt/$maxAttempts)',
          'PaymentService',
        );

        // Prepare request for prymo credit endpoint
        final request = {
          'recipientNumber': recipientNumber,
          'amount': params.amount, // Send as number
          'network': network,
        };

        final requestUrl = '${AppConstants.apiBaseUrl}/api/v1/airtime/topup';
        AppLogger.info(
          '📤 Ghana airtime topup POST => $requestUrl',
          'PaymentService',
        );
        AppLogger.info('📦 Ghana airtime topup body: $request', 'PaymentService');

        final response = await _prymoApiClient.prymoCreditAirtime(
          request,
        );
        
        // Log response
        AppLogger.info('📥 Ghana airtime topup RESPONSE[${response.response.statusCode}]', 'PaymentService');
        AppLogger.info('📊 Response data: ${response.data}', 'PaymentService');
        
        if (response.response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>?;
          final status = data?['status']?.toString().toUpperCase() ?? '';
          final statusCode = data?['status-code']?.toString();
          
          // Check for success based on status or status-code
          if (status == 'OK' || status == 'SUCCESS' || statusCode == '00') {
            await clearPendingPayment();
            _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.success;
            return PaymentResult(
              success: true,
              message: 'Airtime top-up successful.',
              data: data,
              transactionId: data?['local-trxn-code']?.toString() ?? data?['trxn']?.toString(),
            );
          } else {
            // Handle failure response from prymo
            final message = data?['message']?.toString() ?? 'Airtime top-up failed';
            final errorDetails = data?.toString();
            AppLogger.warning('⚠️ Prymo credit failed: $message', 'PaymentService');
            AppLogger.warning('⚠️ Full error response: $errorDetails', 'PaymentService');
            
            if (attempt < maxAttempts && (status == 'PENDING' || status == 'PROCESSING')) {
              await Future.delayed(const Duration(seconds: 4));
              continue;
            }
            
            _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
            return PaymentResult(
              success: false,
              message: message,
              errorCode: statusCode ?? data?['status-code']?.toString() ?? 'CREDIT_FAILED',
              data: data, // Include error data for debugging
            );
          }
        } else {
          throw Exception('HTTP ${response.response.statusCode}: ${response.response.statusMessage}');
        }
      } catch (e) {
        final rawMessage = _extractErrorMessage(e);
        final shouldRetry = attempt < maxAttempts && _isRetryableTopupError(rawMessage);
        if (shouldRetry) {
          AppLogger.warning(
            '⏳ Ghana airtime crediting retry $attempt/$maxAttempts: $rawMessage',
            'PaymentService',
          );
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }
        AppLogger.error('Ghana airtime crediting failed', e, null, 'PaymentService');
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: _sanitizeTopupMessage(rawMessage),
          errorCode: 'EXCEPTION',
        );
      }
    }

    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
    return PaymentResult(
      success: false,
      message: _sanitizeTopupMessage('Top-up failed. Please try again later.'),
      errorCode: 'MAX_RETRIES_EXCEEDED',
    );
  }

  /// Credit data bundle for Ghana using prymo credit endpoint
  Future<PaymentResult> _creditDataGhana(TopupParams params, int maxAttempts) async {
    // Use the network code from the operator data (from auto-detection)
    final network = GhanaNetworkCodes.fromOperatorId(params.operatorId);
    
    AppLogger.info('📶 Using network code: $network (${GhanaNetworkCodes.getNetworkName(network)}) for data credit', 'PaymentService');
    
    // Remove country code from recipient number for Ghana
    String recipientNumber = params.recipientNumber;
    if (recipientNumber.startsWith('233')) {
      recipientNumber = '0' + recipientNumber.substring(3);
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        AppLogger.info(
          '📶 Crediting data for Ghana via prymo credit (attempt $attempt/$maxAttempts)',
          'PaymentService',
        );

        // Prepare request for prymo data credit endpoint
        final request = {
          'recipientNumber': recipientNumber,
          'dataCode': params.dataCode ?? params.bundleId ?? '', // Use dataCode (plan_id) from bundle list
          'network': network,
          'amount': params.amount, // Send amount as number
        };
        
        final requestUrl = '${AppConstants.apiBaseUrl}/api/v1/internet/buydata';
        AppLogger.info(
          '📶 Ghana data bundle POST => $requestUrl',
          'PaymentService',
        );
        AppLogger.info('📦 Ghana data bundle body: $request', 'PaymentService');

        final response = await _prymoApiClient.prymoCreditData(
          request,
        );
        
        // Log response
        AppLogger.info('📥 Ghana data bundle RESPONSE[${response.response.statusCode}]', 'PaymentService');
        AppLogger.info('📊 Response data: ${response.data}', 'PaymentService');
        
        if (response.response.statusCode == 201) {
          final data = response.data as Map<String, dynamic>?;
          final status = data?['status']?.toString().toUpperCase() ?? '';
          final statusCode = data?['status-code']?.toString();
          
          // Check for success based on status or status-code
          if (status == 'OK' || status == 'SUCCESS' || statusCode == '00') {
            await clearPendingPayment();
            _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.success;
            return PaymentResult(
              success: true,
              message: 'Data bundle purchase successful.',
              data: data,
              transactionId: data?['local-trxn-code']?.toString() ?? data?['trxn']?.toString(),
            );
          } else {
            // Handle failure response from prymo
            final message = data?['message']?.toString() ?? 'Data bundle purchase failed';
            AppLogger.warning('⚠️ Prymo data credit failed: $message', 'PaymentService');
            
            if (attempt < maxAttempts && (status == 'PENDING' || status == 'PROCESSING')) {
              await Future.delayed(const Duration(seconds: 4));
              continue;
            }
            
            _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
            return PaymentResult(
              success: false,
              message: message,
              errorCode: statusCode ?? data?['status-code']?.toString() ?? 'CREDIT_FAILED',
            );
          }
        } else {
          throw Exception('HTTP ${response.response.statusCode}: ${response.response.statusMessage}');
        }
      } catch (e) {
        final rawMessage = _extractErrorMessage(e);
        final shouldRetry = attempt < maxAttempts && _isRetryableTopupError(rawMessage);
        if (shouldRetry) {
          AppLogger.warning(
            '⏳ Ghana data crediting retry $attempt/$maxAttempts: $rawMessage',
            'PaymentService',
          );
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }
        AppLogger.error('Ghana data crediting failed', e, null, 'PaymentService');
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: _sanitizeTopupMessage(rawMessage),
          errorCode: 'EXCEPTION',
        );
      }
    }

    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
    return PaymentResult(
      success: false,
      message: _sanitizeTopupMessage('Data purchase failed. Please try again later.'),
      errorCode: 'MAX_RETRIES_EXCEEDED',
    );
  }

  /// Credit data bundle after successful payment
  Future<PaymentResult> creditData({
    required String userId,
    required TopupParams params,
  }) async {
    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.crediting;

    const maxAttempts = 3;

    // Check if this is a Ghana transaction and use prymo credit endpoint if enabled
    if (params.recipientCountryCode == 'GH' && AppConstants.usePrymoForGhanaData) {
      return await _creditDataGhana(params, maxAttempts);
    }

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final customIdentifier =
            (params.customIdentifier?.isNotEmpty ?? false) ? params.customIdentifier! : params.payTransRef;
        AppLogger.info(
          '📶 Crediting data for ${params.recipientNumber} (attempt $attempt/$maxAttempts)',
          'PaymentService',
        );

        final response = await _apiClient.buyData(
          DataPurchaseRequest(
            userId: userId,
            operatorId: params.operatorId,
            recipientNumber: params.recipientNumber,
            recipientCountryCode: params.recipientCountryCode,
            senderNumber: params.senderNumber,
            senderCountryCode: params.senderCountryCode,
            recipientEmail: params.recipientEmail,
            customIdentifier: customIdentifier,
            bundleId: int.tryParse(params.bundleId ?? '0') ?? 0,
            amount: params.amount,
            userName: params.senderNumber, // Required by API - user's phone number
          ),
        );

        final status = response.status.toUpperCase();

        // Check if status is SUCCESSFUL (not using .success field as it doesn't exist)
        if (status == 'SUCCESSFUL') {
          await clearPendingPayment();
          _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.success;
          return PaymentResult(
            success: true,
            message: 'Data bundle purchase successful.',
            data: response,
            transactionId: response.transactionId.toString(),
          );
        }

        if ((status == 'PENDING' || status == 'PROCESSING') && attempt < maxAttempts) {
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }

        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: 'Data bundle purchase failed. Please check your balance or try again.',
          errorCode: 'CREDIT_FAILED',
        );
      } catch (e) {
        final rawMessage = _extractErrorMessage(e);
        final shouldRetry = attempt < maxAttempts && _isRetryableTopupError(rawMessage);
        if (shouldRetry) {
          AppLogger.warning(
            '⏳ Data crediting retry $attempt/$maxAttempts: $rawMessage',
            'PaymentService',
          );
          await Future.delayed(const Duration(seconds: 4));
          continue;
        }
        AppLogger.error('Data crediting failed', e, null, 'PaymentService');
        _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
        return PaymentResult(
          success: false,
          message: _sanitizeTopupMessage(rawMessage),
          errorCode: 'EXCEPTION',
        );
      }
    }

    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
    return PaymentResult(
      success: false,
      message: _sanitizeTopupMessage('Top-up failed. Please try again later.'),
      errorCode: 'MAX_RETRIES_EXCEEDED',
    );
  }

  /// Fetch data bundles for Ghana using Prymo API
  Future<List<Map<String, dynamic>>> fetchGhanaDataBundles(int networkCode) async {
    try {
      AppLogger.info('📶 Fetching Ghana data bundles for network: $networkCode (${GhanaNetworkCodes.getNetworkName(networkCode)})', 'PaymentService');
      
      // Prepare request with network parameter
      final request = {
        'network': networkCode,
      };
      
      final requestUrl = '${AppConstants.apiBaseUrl}/api/v1/internet/bundlelist';
      AppLogger.info('📶 Ghana data bundle list POST => $requestUrl', 'PaymentService');
      AppLogger.info('📦 Ghana bundle list body: $request', 'PaymentService');
      
      final response = await _prymoApiClient.prymoDataBundleList(
        request,
      );
      
      // Log response
      AppLogger.info('📥 Ghana bundle list RESPONSE[${response.response.statusCode}]', 'PaymentService');
      AppLogger.info('📊 Response data keys: ${response.data?.keys.toList()}', 'PaymentService');
      
      if (response.response.statusCode == 200 || response.response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>?;
        final bundles = data?['bundles'] as List<dynamic>? ?? [];
        
        // Convert to list of maps
        final bundleList = bundles.map((bundle) => bundle as Map<String, dynamic>).toList();
        
        AppLogger.info('✅ Retrieved ${bundleList.length} data bundles for Ghana', 'PaymentService');
        
        // Log first few bundles for debugging
        if (bundleList.isNotEmpty) {
          AppLogger.info('📦 Sample bundles: ${bundleList.take(3).map((b) => '${b['plan_name']} - GHS${b['price']}').toList()}', 'PaymentService');
        }
        
        return bundleList;
      } else {
        throw Exception('Failed to fetch data bundles: HTTP ${response.response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Failed to fetch Ghana data bundles', e, null, 'PaymentService');
      throw Exception('Failed to fetch data bundles: ${e.toString()}');
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
        final safeToken = token.length > 10 ? token.substring(0, 10) : token;
        AppLogger.info('🔍 Querying payment status (attempt $attempt/$maxRetries) with token: $safeToken...', 'PaymentService');
        
        final response = await _apiClient.queryAdvansiPayTransaction(
          AdvansiPayQueryRequest(token: token),
        );

        // Check for successful response (status 200/201 with data)
        if ((response.status == 200 || response.status == 201) && response.data != null) {
          final paymentStatus = response.data!.status?.toUpperCase() ?? 'UNKNOWN';
          final resultText = response.data!.resultText?.toLowerCase() ?? '';
          final originalResultText = response.data!.originalResponse?.resultText?.toLowerCase() ?? '';
          final originalResult = response.data!.originalResponse?.result;
          final hasSuccessText = (resultText.contains('success') && !resultText.contains('unsuccess')) ||
              (originalResultText.contains('success') && !originalResultText.contains('unsuccess'));
          
          AppLogger.info(
            '✅ Payment query result: status=$paymentStatus, resultText=$resultText, originalResultText=$originalResultText, result=$originalResult',
            'PaymentService',
          );
          
          // Check for COMPLETED status or Success resultText
          final isSuccess = paymentStatus == 'COMPLETED' ||
              paymentStatus == 'APPROVED' ||
              paymentStatus == 'SUCCESS' ||
              paymentStatus == 'SUCCESSFUL' ||
              paymentStatus == 'PAID' ||
              hasSuccessText ||
              originalResult == 1;
          
          if (isSuccess) {
            // Payment confirmed - return immediately
            return PaymentResult(
              success: true,
              message: 'Payment verified. Preparing your top-up now.',
              data: response.data,
              transactionId: response.data!.transactionId ?? response.data!.orderId,
            );
          }
          
          // Payment not yet completed - store result and maybe retry
          lastResult = PaymentResult(
            success: false,
            message: 'Payment is still processing. Please wait a moment.',
            data: response.data,
            transactionId: response.data!.transactionId ?? response.data!.orderId,
          );
        }

        // Check for QUERY_FAILED in message (error case)
        if (response.message.contains('QUERY_FAILED')) {
          AppLogger.warning('⚠️ Payment query failed (attempt $attempt): ${response.message}', 'PaymentService');
          lastResult = PaymentResult(
            success: false,
            message: _sanitizeTopupMessage('Payment verification failed. Please try again or contact support.'),
            errorCode: 'QUERY_FAILED',
          );
        }
        
      } catch (e) {
        AppLogger.error('Payment status query failed (attempt $attempt)', e, null, 'PaymentService');
        
        final errorMessage = _extractErrorMessage(e);
        lastResult = PaymentResult(
          success: false,
          message: _sanitizeTopupMessage(errorMessage),
          errorCode: 'QUERY_EXCEPTION',
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
      message: _sanitizeTopupMessage('We couldn\'t confirm the payment yet. Please try again shortly.'),
      errorCode: 'MAX_RETRIES_EXCEEDED',
    );
  }

  String? _resolveTransactionToken(Transaction transaction) {
    if (transaction.trxn != null &&
        transaction.trxn!.isNotEmpty &&
        !transaction.trxn!.startsWith('TXN-')) {
      return transaction.trxn;
    }

    if (transaction.transId != null &&
        transaction.transId!.isNotEmpty &&
        !transaction.transId!.startsWith('TXN-')) {
      return transaction.transId;
    }

    AppLogger.warning(
      '⚠️ No valid payment token found for transaction ${transaction.id}. Found transaction ID instead of payment token.',
      'PaymentService',
    );
    return null;
  }

  bool _matchesPendingTopup(TopupParams params, Transaction transaction) {
    final amountMatches = params.amount == transaction.amount.abs();
    final recipientMatches = params.recipientNumber == transaction.recipientPhone;
    final typeMatches = (transaction.transType ?? transaction.type ?? '')
        .toLowerCase()
        .contains(params.transType.toLowerCase().replaceAll('global', ''));
    return amountMatches && recipientMatches && typeMatches;
  }

  bool _isVerifiablePaymentTransaction(Transaction transaction) {
    final status = transaction.status.toLowerCase();
    final isPending = status == 'pending' || status == 'processing';
    final hasValidToken = (transaction.trxn != null && !transaction.trxn!.startsWith('TXN-')) ||
        (transaction.transId != null && !transaction.transId!.startsWith('TXN-'));
    final transType = (transaction.transType ?? '').toLowerCase();
    final isPaymentType = transType.contains('topup') ||
        transType.contains('payment') ||
        transType.contains('momo');
    return isPending && (hasValidToken || isPaymentType);
  }

  Future<PaymentResult> verifyPendingTransaction(Transaction transaction) async {
    if (!_isVerifiablePaymentTransaction(transaction)) {
      return PaymentResult(
        success: false,
        message: 'This transaction cannot be verified. Only pending payment transactions can be verified.',
        errorCode: 'NOT_VERIFIABLE',
      );
    }

    final token = _resolveTransactionToken(transaction);
    if (token == null) {
      return PaymentResult(
        success: false,
        message: 'Unable to verify payment: No valid payment token found. This transaction may not be a payment transaction.',
        errorCode: 'NO_TOKEN',
      );
    }

    final queryResult = await queryPaymentStatus(token);
    if (!queryResult.success) {
      return queryResult;
    }

    final pendingTopup = await getPendingTopup();
    if (pendingTopup == null || !_matchesPendingTopup(pendingTopup, transaction)) {
      return PaymentResult(
        success: true,
        message: 'Payment verified, but no pending top-up was found for this transaction.',
        data: queryResult.data,
        transactionId: queryResult.transactionId,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    if (pendingTopup.transType == 'GLOBALAIRTOPUP') {
      return creditAirtime(userId: userId, params: pendingTopup);
    } else if (pendingTopup.transType == 'GLOBALDATATOPUP') {
      return creditData(userId: userId, params: pendingTopup);
    }

    return PaymentResult(
      success: false,
      message: 'Payment verified, but this transaction type is not supported for auto-crediting.',
      errorCode: 'UNKNOWN_TYPE',
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
        message: _sanitizeTopupMessage('No pending payment found.'),
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
          message: _sanitizeTopupMessage(queryResult.message.isNotEmpty 
              ? queryResult.message 
              : 'Payment verification failed. Please try again.'),
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
          message: _sanitizeTopupMessage('Payment verified, but this transaction type is not supported for auto-crediting.'),
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
          message: _sanitizeTopupMessage('Unknown transaction type: ${topupParams.transType}'),
          errorCode: 'UNKNOWN_TYPE',
        );
      }
    } else if (status.toLowerCase() == 'cancelled') {
      await clearPendingPayment();
      _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.cancelled;
      return PaymentResult(
        success: false,
        message: _sanitizeTopupMessage('Payment was cancelled. No charge was made.'),
        errorCode: 'CANCELLED',
      );
    } else if (status.toLowerCase() == 'pending') {
      // For pending status without token, we can't verify
      return PaymentResult(
        success: false,
        message: 'Payment is still pending. Please wait a moment and try again.',
        errorCode: 'PENDING',
      );
    } else {
      await clearPendingPayment();
      _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.failed;
      return PaymentResult(
        success: false,
        message: 'Payment failed. Please try again or use another payment method.',
        errorCode: 'FAILED',
      );
    }
  }

  /// Reset payment flow state
  void resetState() {
    _ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.idle;
  }

  String _sanitizeTopupMessage(String message) {
    final cleaned = message.replaceAll('Exception: ', '').trim();
    final lower = cleaned.toLowerCase();
    if (lower.contains('try again later') || lower.contains('asynchronous top-up failed')) {
      return cleaned;
    }
    if (lower.contains('processing') || lower.contains('pending')) {
      return 'Top-up is still processing. Please try again shortly.';
    }
    if (lower.contains('insufficient') && lower.contains('fund')) {
      return 'Top-up failed due to insufficient wallet balance. Please fund your wallet and try again.';
    }
    if (lower.contains('cancelled') || lower.contains('canceled')) {
      return 'Payment was cancelled. No charge was made.';
    }
    if (lower.contains('failed') || lower.contains('error')) {
      return 'Top-up failed. Please try again or contact support.';
    }
    if (cleaned.isEmpty) {
      return 'Top-up failed. Please try again.';
    }
    return cleaned;
  }

  bool _isRetryableTopupError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('try again later') ||
        lower.contains('asynchronous top-up failed') ||
        lower.contains('temporarily unavailable') ||
        lower.contains('timeout') ||
        lower.contains('network error') ||
        lower.contains('connection') ||
        lower.contains('please try again') ||
        lower.contains('service unavailable') ||
        lower.contains('rate limit');
  }
}

