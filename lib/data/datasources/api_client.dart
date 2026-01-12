import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/api_models.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: AppConstants.apiBaseUrl)
abstract class ApiClient {
  // NOTE: We intentionally do NOT expose `errorLogger` here.
  // Some retrofit_generator versions emit a 3-arg `logError(...)` call while the
  // runtime `ParseErrorLogger` interface expects 4 args, causing compilation errors.
  // Errors are already logged via Dio interceptors (LoggingInterceptor).
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  // Authentication
  @POST('${AppConstants.apiVersion}/users/register')
  Future<RegisterResponse> register(@Body() RegisterRequest request);

  @POST('${AppConstants.apiVersion}/users/login')
  Future<LoginResponse> login(@Body() LoginRequest request);

  @POST('${AppConstants.apiVersion}/auth/refresh')
  Future<RefreshTokenResponse> refreshToken(@Body() RefreshTokenRequest request);

  // User Profile
  @GET('${AppConstants.apiVersion}/users/profile')
  Future<UserProfileResponse> getUserProfile();

  @PUT('${AppConstants.apiVersion}/users/profile/update')
  Future<UserProfileResponse> updateUserProfile(@Body() UpdateProfileRequest request);

  @POST('${AppConstants.apiVersion}/users/change-password')
  Future<void> changePassword(@Body() ChangePasswordRequest request);

  @POST('${AppConstants.apiVersion}/users/reset-password')
  Future<void> resetPassword(@Body() ResetPasswordRequest request);

  // Wallet
  @GET('${AppConstants.apiVersion}/wallet/balance')
  Future<BalanceResponse> getBalance();

  // Airtime - Reloadly Global
  @POST('${AppConstants.apiVersion}/airtime/reloadly')
  Future<AirtimeResponse> purchaseAirtimeReloadly(@Body() AirtimeRequest request);

  // Airtime - Prymo Ghana
  @POST('${AppConstants.apiVersion}/airtime/prymo')
  Future<AirtimeResponse> purchaseAirtimePrymo(@Body() AirtimeRequest request);

  // Data Bundles - Reloadly Global
  @POST('${AppConstants.apiVersion}/data/reloadly')
  Future<DataResponse> purchaseDataReloadly(@Body() DataRequest request);

  // Data Bundles - Prymo Ghana
  @POST('${AppConstants.apiVersion}/data/prymo')
  Future<DataResponse> purchaseDataPrymo(@Body() DataRequest request);

  // ExpressPay Payment Gateway
  @POST('${AppConstants.apiVersion}/payment/expresspay/initiate')
  Future<PaymentResponse> initiateExpressPayPayment(@Body() PaymentRequest request);

  @POST('${AppConstants.apiVersion}/payment/expresspay/verify')
  Future<PaymentVerificationResponse> verifyExpressPayPayment(@Body() PaymentVerificationRequest request);

  // Payment Methods - ExpressPay
  @GET('${AppConstants.apiVersion}/payment/expresspay/methods')
  Future<ExpressPayMethodsResponse> getExpressPayMethods();

  // Transactions
  @GET('${AppConstants.apiVersion}/transactions')
  Future<TransactionsResponse> getTransactions(@Queries() Map<String, dynamic> queries);

  @GET('${AppConstants.apiVersion}/transactions/user/{userId}')
  Future<TransactionsResponse> getTransactionsByUser(
    @Path('userId') String userId,
    @Queries() Map<String, dynamic> queries,
  );

  @GET('${AppConstants.apiVersion}/transactions/{id}')
  Future<TransactionDetailResponse> getTransactionDetail(@Path('id') String id);

  // Statistics
  @GET('${AppConstants.apiVersion}/statistics')
  Future<StatisticsResponse> getStatistics(@Queries() Map<String, dynamic> queries);

  // Rewards & Points (Loyalty)
  @GET('${AppConstants.apiVersion}/users/points')
  Future<PointsResponse> getUserPoints();

  @GET('${AppConstants.apiVersion}/rewards')
  Future<RewardsResponse> getRewards();

  @GET('${AppConstants.apiVersion}/rewards/{userId}')
  Future<RewardsResponse> getRewardsByUser(@Path('userId') String userId);

  @POST('${AppConstants.apiVersion}/rewards')
  Future<RewardResponse> createReward(@Body() RewardUpsertRequest request);

  @PUT('${AppConstants.apiVersion}/rewards/{userId}')
  Future<RewardResponse> updateReward(
    @Path('userId') String userId,
    @Body() RewardUpsertRequest request,
  );

  @DELETE('${AppConstants.apiVersion}/rewards/{userId}')
  Future<void> deleteReward(@Path('userId') String userId);

  // Payment Methods
  @GET('${AppConstants.apiVersion}/payment-methods')
  Future<PaymentMethodsResponse> getPaymentMethods();

  // Countries & Operators
  @GET('${AppConstants.apiVersion}/reloadly/country-list')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> getCountriesRaw();

  @GET('${AppConstants.apiVersion}/operators')
  Future<OperatorsResponse> getOperators(@Queries() Map<String, dynamic> queries);

  // Reloadly Autodetect
  @POST('${AppConstants.apiVersion}/reloadly/operator/autodetect')
  Future<AutodetectResponse> autodetectOperator(@Body() AutodetectRequest request);

  // Reloadly Airtime Recharge
  @POST('${AppConstants.apiVersion}/reload-airtime/recharge')
  Future<AirtimeRechargeResponse> rechargeAirtime(@Body() AirtimeRechargeRequest request);

  // Reloadly Data - List Operators (returns raw array)
  @POST('${AppConstants.apiVersion}/reloadly-data/list-operators')
  @DioResponseType(ResponseType.json)
  Future<HttpResponse<dynamic>> listDataOperatorsRaw(@Body() DataOperatorsRequest request);

  // Reloadly Data - Buy Data
  @POST('${AppConstants.apiVersion}/reloadly-data/buy-data')
  Future<DataPurchaseResponse> buyData(@Body() DataPurchaseRequest request);

  // AdvansiPay - Initiate Payment
  @POST('${AppConstants.apiVersion}/advansispay/initiate-payment')
  Future<AdvansiPayInitResponse> initiateAdvansiPay(@Body() AdvansiPayInitRequest request);

  // AdvansiPay - Query Transaction Status
  @POST('${AppConstants.apiVersion}/advansispay/query-transaction')
  Future<AdvansiPayQueryResponse> queryAdvansiPayTransaction(@Body() AdvansiPayQueryRequest request);
}

class DioClient {
  static Dio createDio({Future<String?> Function()? getToken}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15), // Reduced from 30s
        receiveTimeout: const Duration(seconds: 15), // Reduced from 30s
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    if (getToken != null) {
      dio.interceptors.add(AuthInterceptor(getToken));
    }
    dio.interceptors.add(LoggingInterceptor());
    dio.interceptors.add(RetryInterceptor());

    return dio;
  }
}

class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getToken;

  AuthInterceptor(this.getToken);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.info('📤 REQUEST[${options.method}] => ${options.baseUrl}${options.path}', 'API');
    if (options.data != null) {
      AppLogger.debug('Request body: ${options.data}', 'API');
    }
    if (options.queryParameters.isNotEmpty) {
      AppLogger.debug('Query params: ${options.queryParameters}', 'API');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.info(
      '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.path}',
      'API',
    );
    // Log response structure for debugging
    if (response.data is Map) {
      final data = response.data as Map;
      
      // Log transactions array if present
      if (data.containsKey('transactions')) {
        final transactions = data['transactions'];
        if (transactions is List) {
          AppLogger.info('📊 Response has transactions: ${transactions.length} items', 'API');
          if (transactions.isNotEmpty) {
            AppLogger.debug('First transaction sample: ${transactions.first}', 'API');
          }
        } else {
          AppLogger.warning('⚠️ Response has "transactions" but it is not a List (type: ${transactions.runtimeType})', 'API');
        }
      } else {
        AppLogger.debug('ℹ️ Response does not contain "transactions" key', 'API');
      }
      
      // Log metadata array if present (for backward compatibility)
      if (data.containsKey('metadata')) {
        final metadata = data['metadata'];
        AppLogger.debug('Response has metadata: ${metadata is List ? (metadata as List).length : 'not a list'} items', 'API');
      }
      
      // Log pagination info
      if (data.containsKey('total')) {
        AppLogger.info('📄 Total transactions: ${data['total']}', 'API');
      }
      if (data.containsKey('totalPages')) {
        AppLogger.debug('📄 Total pages: ${data['totalPages']}', 'API');
      }
      
      AppLogger.debug('Response keys: ${data.keys.toList()}', 'API');
      
      // Log full response data (truncated if too large)
      final responseStr = response.data.toString();
      if (responseStr.length > 1000) {
        AppLogger.debug('Response data (truncated): ${responseStr.substring(0, 1000)}...', 'API');
      } else {
        AppLogger.debug('Response data: ${response.data}', 'API');
      }
    } else {
      AppLogger.warning('⚠️ Response data is not a Map (type: ${response.data.runtimeType})', 'API');
      AppLogger.debug('Response data: ${response.data}', 'API');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '❌ ERROR[${err.response?.statusCode ?? 'NO_STATUS'}] => ${err.requestOptions.path}',
      err,
      err.stackTrace,
      'API',
    );
    if (err.response != null) {
      AppLogger.debug('Error response: ${err.response?.data}', 'API');
    }
    super.onError(err, handler);
  }
}

class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
      if (retryCount < 3) {
        err.requestOptions.extra['retryCount'] = retryCount + 1;
        await Future.delayed(Duration(seconds: retryCount + 1));
        try {
          final response = await DioClient.createDio().fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          handler.next(err);
          return;
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}

