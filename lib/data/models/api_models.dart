import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_models.freezed.dart';
part 'api_models.g.dart';

// Authentication Models
@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username, // Phone number as username
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String firstName,
    required String lastName,
    required String password,
    required String roles, // API expects string like "AGENT", "USER", "MERCHANT"
    required String email,
    required String phoneNumber,
    required String country, // Full country name like "GHANA"
    String? referrerClientId,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
class OtpRequest with _$OtpRequest {
  const factory OtpRequest({
    required String phone,
    required String otp,
  }) = _OtpRequest;

  factory OtpRequest.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestFromJson(json);
}

@freezed
class RefreshTokenRequest with _$RefreshTokenRequest {
  const factory RefreshTokenRequest({
    required String refreshToken,
  }) = _RefreshTokenRequest;

  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);
}

// Login Response - Direct tokens (no wrapper)
@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    User? user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

// Register Response
@freezed
class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({
    @Default('Registration successful') String message,
    User? user,
  }) = _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // Handle case where API returns user object directly (not wrapped)
    if (json.containsKey('_id') || json.containsKey('username')) {
      // This is a user object, wrap it
      return RegisterResponse(
        message: 'Registration successful',
        user: User.fromJson(json),
      );
    }
    // Normal response with message and user fields
    return RegisterResponse(
      message: json['message'] as String? ?? 'Registration successful',
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>) 
          : null,
    );
  }
}

// Refresh Token Response
@freezed
class RefreshTokenResponse with _$RefreshTokenResponse {
  const factory RefreshTokenResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _RefreshTokenResponse;

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenResponseFromJson(json);
}

@freezed
class User with _$User {
  const factory User({
    @JsonKey(name: '_id') required String id,
    String? username,
    @JsonKey(name: 'phoneNumber') String? phoneNumber,
    String? email,
    @JsonKey(name: 'firstName') String? firstName,
    @JsonKey(name: 'lastName') String? lastName,
    String? avatar,
    String? gravatar,
    String? country,
    List<String>? roles,
    String? password, // API returns this but shouldn't be used
    @Default(false) bool isVerified,
    @Default(false) bool emailVerified,
    @Default(false) bool phoneVerified,
    @Default(0) int points,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// User Profile Update Request
@freezed
class UpdateProfileRequest with _$UpdateProfileRequest {
  const factory UpdateProfileRequest({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? referrerClientId,
    int? points,
    bool? emailVerified,
    bool? phoneVerified,
    String? status,
    List<String>? roles,
  }) = _UpdateProfileRequest;

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);
}

// User Profile Response
@freezed
class UserProfileResponse with _$UserProfileResponse {
  const factory UserProfileResponse({
    required User user,
  }) = _UserProfileResponse;

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    // Handle case where API returns user object directly (not wrapped)
    if (json.containsKey('_id') || json.containsKey('username')) {
      // This is a user object directly, wrap it
      return UserProfileResponse(
        user: User.fromJson(json),
      );
    }
    // Normal response with user field
    return UserProfileResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

// Change Password Request
@freezed
class ChangePasswordRequest with _$ChangePasswordRequest {
  const factory ChangePasswordRequest({
    required String currentPassword,
    required String newPassword,
  }) = _ChangePasswordRequest;

  factory ChangePasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestFromJson(json);
}

// Reset Password Request (Forgot Password)
@freezed
class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    required String email,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}

// Email Verification Request
@freezed
class EmailVerificationRequest with _$EmailVerificationRequest {
  const factory EmailVerificationRequest({
    required String email,
  }) = _EmailVerificationRequest;

  factory EmailVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailVerificationRequestFromJson(json);
}

// Email Verification Confirmation
@freezed
class EmailVerificationConfirmRequest with _$EmailVerificationConfirmRequest {
  const factory EmailVerificationConfirmRequest({
    required String email,
    required String code,
  }) = _EmailVerificationConfirmRequest;

  factory EmailVerificationConfirmRequest.fromJson(Map<String, dynamic> json) =>
      _$EmailVerificationConfirmRequestFromJson(json);
}

// Phone Verification Request
@freezed
class PhoneVerificationRequest with _$PhoneVerificationRequest {
  const factory PhoneVerificationRequest({
    required String phoneNumber,
  }) = _PhoneVerificationRequest;

  factory PhoneVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$PhoneVerificationRequestFromJson(json);
}

// Phone Verification Confirmation
@freezed
class PhoneVerificationConfirmRequest with _$PhoneVerificationConfirmRequest {
  const factory PhoneVerificationConfirmRequest({
    required String phoneNumber,
    required String code,
  }) = _PhoneVerificationConfirmRequest;

  factory PhoneVerificationConfirmRequest.fromJson(Map<String, dynamic> json) =>
      _$PhoneVerificationConfirmRequestFromJson(json);
}

// Verification Response
@freezed
class VerificationResponse with _$VerificationResponse {
  const factory VerificationResponse({
    required bool success,
    required String message,
    int? pointsAwarded,
  }) = _VerificationResponse;

  factory VerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$VerificationResponseFromJson(json);
}

// Wallet Models
@freezed
class BalanceResponse with _$BalanceResponse {
  const factory BalanceResponse({
    required bool success,
    required String message,
    BalanceData? data,
  }) = _BalanceResponse;

  factory BalanceResponse.fromJson(Map<String, dynamic> json) =>
      _$BalanceResponseFromJson(json);
}

@freezed
class BalanceData with _$BalanceData {
  const factory BalanceData({
    required double balance,
    required String currency,
  }) = _BalanceData;

  factory BalanceData.fromJson(Map<String, dynamic> json) =>
      _$BalanceDataFromJson(json);
}

// Airtime Models
@freezed
class AirtimeRequest with _$AirtimeRequest {
  const factory AirtimeRequest({
    required String recipientPhone,
    required double amount,
    required String countryCode,
    String? operatorId,
    String? note,
  }) = _AirtimeRequest;

  factory AirtimeRequest.fromJson(Map<String, dynamic> json) =>
      _$AirtimeRequestFromJson(json);
}

@freezed
class AirtimeResponse with _$AirtimeResponse {
  const factory AirtimeResponse({
    required bool success,
    required String message,
    AirtimeData? data,
  }) = _AirtimeResponse;

  factory AirtimeResponse.fromJson(Map<String, dynamic> json) =>
      _$AirtimeResponseFromJson(json);
}

@freezed
class AirtimeData with _$AirtimeData {
  const factory AirtimeData({
    required String transactionId,
    required String recipientPhone,
    required double amount,
    required String status,
    required DateTime createdAt,
  }) = _AirtimeData;

  factory AirtimeData.fromJson(Map<String, dynamic> json) =>
      _$AirtimeDataFromJson(json);
}

// Data Models
@freezed
class DataRequest with _$DataRequest {
  const factory DataRequest({
    required String recipientPhone,
    required double dataAmount,
    required String countryCode,
    String? operatorId,
    String? dataPlanId,
  }) = _DataRequest;

  factory DataRequest.fromJson(Map<String, dynamic> json) =>
      _$DataRequestFromJson(json);
}

@freezed
class DataResponse with _$DataResponse {
  const factory DataResponse({
    required bool success,
    required String message,
    DataData? data,
  }) = _DataResponse;

  factory DataResponse.fromJson(Map<String, dynamic> json) =>
      _$DataResponseFromJson(json);
}

@freezed
class DataData with _$DataData {
  const factory DataData({
    required String transactionId,
    required String recipientPhone,
    required double dataAmount,
    required String status,
    required DateTime createdAt,
  }) = _DataData;

  factory DataData.fromJson(Map<String, dynamic> json) =>
      _$DataDataFromJson(json);
}

// Transaction Models
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    @JsonKey(name: '_id') String? apiId, // API uses _id
    @JsonKey(name: 'id', fromJson: _idFromJson) required String id,
    @JsonKey(name: 'transType') String? transType, // API uses transType
    String? type, // Derived type for backward compatibility
    @JsonKey(fromJson: _amountFromJson) required double amount,
    @JsonKey(fromJson: _currencyFromJson) required String currency,
    @JsonKey(fromJson: _statusFromJson) required String status,
    @JsonKey(name: 'createdAt', fromJson: _createdAtFromJson) required DateTime createdAt,
    String? recipientPhone,
    String? recipientName,
    String? note,
    String? paymentMethod,
    // Additional fields from API response
    String? userId,
    String? userName,
    String? transId,
    String? trxn,
    String? operator,
    String? network,
    String? retailer,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Transform API response to Transaction model
    // Handle both regular transaction structure and metadata structure (from transactions/user endpoint)
    final apiId = json['_id'] as String?;
    final id = _idFromJson(json);
    
    // Handle metadata structure (from transactions/user endpoint)
    // Metadata has: provider, result-text (status), initiatedAt, token, accountNumber, etc.
    final transType = json['transType'] as String? ?? 
                      (json['provider'] as String?); // Use provider as transType if available
    final type = _typeFromJson(json, transType);
    final amount = _amountFromJson(json);
    final currency = _currencyFromJson(json);
    
    // Status: use helper function which handles status.transaction structure
    final status = _statusFromJson(json);
    
    // Date from metadata: initiatedAt or createdAt
    final createdAt = json['initiatedAt'] != null 
        ? DateTime.tryParse(json['initiatedAt'] as String) ?? _createdAtFromJson(json)
        : _createdAtFromJson(json);

    String? metadataToken;
    String? metadataOrderId;
    if (json['metadata'] is List && (json['metadata'] as List).isNotEmpty) {
      final firstMeta = (json['metadata'] as List).first;
      if (firstMeta is Map) {
        metadataToken = firstMeta['token'] as String?;
        metadataOrderId = firstMeta['order-id'] as String?;
      }
    }
    final expressToken = json['expressToken'] as String?;
    final paymentToken = expressToken ?? metadataToken;
    
    // Also check for token in other possible fields
    final advansiPayToken = json['advansiPayToken'] as String?;
    final paymentReference = json['paymentReference'] as String?;
    final finalToken = paymentToken ?? advansiPayToken ?? paymentReference;

    final operatorName = json['operator'] ?? json['operatorName'] ?? json['operator_name'];
    final networkName = json['network'] ?? json['networkName'] ?? json['network_name'];
    
    return Transaction(
      apiId: apiId,
      id: id,
      transType: transType,
      type: type,
      amount: amount,
      currency: currency,
      status: status,
      createdAt: createdAt,
      recipientPhone: json['recipientPhone'] as String? ?? 
                      json['recipientNumber'] as String? ??
                      json['accountNumber'] as String?,
      recipientName: json['recipientName'] as String? ?? 
          (json['firstName'] != null && json['lastName'] != null
              ? '${json['firstName']} ${json['lastName']}'
              : null),
      note: json['note'] as String?,
      paymentMethod: (json['payment'] != null && json['payment'] is Map)
          ? (json['payment'] as Map)['type'] as String?
          : json['paymentMethod'] as String? ??
            json['provider'] as String?, // Use provider as payment method
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      transId: json['transId'] as String? ?? metadataOrderId ?? json['token'] as String?,
      trxn: json['trxn'] as String? ?? finalToken,
      operator: operatorName?.toString(),
      network: networkName?.toString(),
      retailer: json['retailer'] as String? ?? json['provider'] as String?,
    );
  }
}

// Extension to provide toJson for Transaction
extension TransactionToJson on Transaction {
  Map<String, dynamic> toJson() {
    return {
      '_id': apiId,
      'id': id,
      'transType': transType,
      'type': type,
      'amount': amount,
      'currency': currency,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'recipientPhone': recipientPhone,
      'recipientName': recipientName,
      'note': note,
      'paymentMethod': paymentMethod,
      'userId': userId,
      'userName': userName,
      'transId': transId,
      'trxn': trxn,
      'operator': operator,
      'network': network,
      'retailer': retailer,
    };
  }
}

// Helper functions for JSON parsing
String _idFromJson(Map<String, dynamic> json) {
  return json['_id'] as String? ?? json['id'] as String? ?? '';
}

String? _typeFromJson(Map<String, dynamic> json, String? transType) {
  // Use transType if available, otherwise try payment.type, then type
  if (transType != null) {
    final lower = transType.toLowerCase();
    if (lower.contains('airtime')) return 'airtime';
    if (lower.contains('data')) return 'data';
    if (lower.contains('transfer')) return 'transfer';
    return transType;
  }
  if (json['payment'] != null && json['payment'] is Map) {
    return (json['payment'] as Map)['type'] as String?;
  }
  return json['type'] as String?;
}

double _amountFromJson(Map<String, dynamic> json) {
  // Try monetary.amount first, then amount
  if (json['monetary'] != null && json['monetary'] is Map) {
    final monetary = json['monetary'] as Map;
    if (monetary['amount'] != null) {
      return (monetary['amount'] as num).toDouble();
    }
    if (monetary['originalAmount'] != null) {
      return double.tryParse(monetary['originalAmount'].toString()) ?? 0.0;
    }
  }
  return (json['amount'] as num?)?.toDouble() ?? 0.0;
}

String _currencyFromJson(Map<String, dynamic> json) {
  // Try monetary.currency first, then currency
  if (json['monetary'] != null && json['monetary'] is Map) {
    final monetary = json['monetary'] as Map;
    return monetary['currency'] as String? ?? 'GHS';
  }
  return json['currency'] as String? ?? 'GHS';
}

String _statusFromJson(Map<String, dynamic> json) {
  // Try status.transaction first (actual API structure)
  if (json['status'] != null && json['status'] is Map) {
    final statusObj = json['status'] as Map;
    final transactionStatus = statusObj['transaction'] as String?;
    if (transactionStatus != null) {
      // Normalize status values
      final lower = transactionStatus.toLowerCase();
      if (lower == 'successful' || lower == 'completed' || lower == 'success') {
        return 'completed';
      }
      if (lower == 'pending' || lower == 'processing') {
        return 'pending';
      }
      if (lower == 'failed' || lower == 'error') {
        return 'failed';
      }
      return transactionStatus;
    }
    return statusObj['service'] as String? ?? 'completed';
  }
  // Try result-text from metadata
  if (json['result-text'] != null) {
    final resultText = json['result-text'] as String;
    final lower = resultText.toLowerCase();
    if (lower == 'pending') return 'pending';
    if (lower == 'successful' || lower == 'completed') return 'completed';
    return resultText;
  }
  return json['status'] as String? ?? 'completed';
}

DateTime _createdAtFromJson(Map<String, dynamic> json) {
  if (json['createdAt'] != null) {
    try {
      return DateTime.parse(json['createdAt'] as String);
    } catch (e) {
      return DateTime.now();
    }
  }
  // Try other date fields
  if (json['date'] != null) {
    try {
      return DateTime.parse(json['date'] as String);
    } catch (e) {
      return DateTime.now();
    }
  }
  return DateTime.now(); // Fallback to current time
}

@freezed
class TransactionsResponse with _$TransactionsResponse {
  const factory TransactionsResponse({
    @Default(true) bool success,
    @Default('') String message,
    @JsonKey(toJson: _transactionsDataToJson, fromJson: _transactionsDataFromJson) TransactionsData? data,
  }) = _TransactionsResponse;

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Handle actual API response structure:
      // - Has 'transactions' array at root level
      // - Has 'total' and 'totalPages' at root
      // - No 'success'/'message' wrapper
      if (json.containsKey('transactions') && json['transactions'] is List) {
        final data = TransactionsData.fromJson(json);
        return TransactionsResponse(
          success: true,
          message: json['serviceMessage'] as String? ?? json['message'] as String? ?? '',
          data: data,
        );
      }
      // Handle case with data wrapper
      if (json.containsKey('data') && json['data'] is Map) {
        return TransactionsResponse(
          success: json['success'] as bool? ?? true,
          message: json['message'] as String? ?? '',
          data: _transactionsDataFromJson(json['data'] as Map<String, dynamic>?),
        );
      }
      // Fallback: try to parse as TransactionsData directly
      final data = TransactionsData.fromJson(json);
      return TransactionsResponse(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String? ?? '',
        data: data,
      );
    } catch (e) {
      // If parsing fails, return response with null data but log the error
      // This allows the repository to handle the error gracefully
      return TransactionsResponse(
        success: false,
        message: 'Failed to parse transactions: $e',
        data: null,
      );
    }
  }
}

// Helper functions for TransactionsData serialization
TransactionsData? _transactionsDataFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return TransactionsData.fromJson(json);
}

Map<String, dynamic>? _transactionsDataToJson(TransactionsData? data) {
  return data?.toJson();
}

@freezed
class TransactionsData with _$TransactionsData {
  const factory TransactionsData({
    required List<Transaction> transactions,
    required int total,
    required int page,
    @JsonKey(name: 'limit') int? limit, // API uses 'limit'
    @JsonKey(name: 'pageSize') int? pageSize, // Keep for backward compatibility
  }) = _TransactionsData;

  factory TransactionsData.fromJson(Map<String, dynamic> json) {
    try {
      // Handle actual API response structure:
      // - Transactions are in 'transactions' array at root level
      // - 'total' and 'totalPages' are at root level
      // - Calculate 'page' from query params or totalPages
      final limit = (json['limit'] as num?)?.toInt();
      final pageSize = (json['pageSize'] as num?)?.toInt();
      final total = (json['total'] as num?)?.toInt() ?? 0;
      final totalPages = (json['totalPages'] as num?)?.toInt();
      final page = (json['page'] as num?)?.toInt() ?? 1;
      
      // Get transactions from 'transactions' array (actual API structure)
      // Fallback to 'metadata' array if transactions not found
      final transactionsList = json['transactions'] as List<dynamic>?;
      final metadataList = json['metadata'] as List<dynamic>?;
      final transactionsListToUse = transactionsList ?? metadataList;
      
      // Parse transactions with error handling
      final parsedTransactions = <Transaction>[];
      if (transactionsListToUse != null && transactionsListToUse.isNotEmpty) {
        int successCount = 0;
        int errorCount = 0;
        String? firstError;
        Object? firstErrorObject;
        
        for (int i = 0; i < transactionsListToUse.length; i++) {
          final item = transactionsListToUse[i];
          try {
            if (item is Map<String, dynamic>) {
              final transaction = Transaction.fromJson(item);
              parsedTransactions.add(transaction);
              successCount++;
            } else {
              errorCount++;
              if (firstError == null) {
                firstError = 'Transaction at index $i is not a Map, type: ${item.runtimeType}';
                firstErrorObject = item;
              }
            }
          } catch (e, stackTrace) {
            // Log parsing error but continue with other transactions
            // This prevents one bad transaction from breaking the entire list
            errorCount++;
            if (firstError == null) {
              firstError = 'Error parsing transaction at index $i: $e';
              firstErrorObject = e;
            }
            // Log first few errors for debugging
            if (errorCount <= 3) {
              // Note: We can't use AppLogger here as this is in a model file
              // Errors will be logged at repository level
            }
            continue;
          }
        }
        
        // If we have errors but also some successes, we should still return the successful ones
        // Only log if ALL transactions failed to parse
        if (successCount == 0 && errorCount > 0 && firstError != null) {
          // This will be caught and logged at repository level
          throw Exception('Failed to parse any transactions. First error: $firstError');
        }
      } else {
        // If transactions list is null or empty, but total > 0, this is unexpected
        if (total > 0 && transactionsList == null && metadataList == null) {
          throw Exception('API returned total=$total but no transactions array found in response');
        }
      }
      
      return TransactionsData(
        transactions: parsedTransactions,
        total: total,
        page: page,
        limit: limit,
        pageSize: pageSize ?? limit ?? 10,
      );
    } catch (e) {
      // Re-throw with more context
      throw Exception('Error parsing TransactionsData: $e. JSON keys: ${json.keys.toList()}');
    }
  }
}

// Extension to provide toJson for TransactionsData
extension TransactionsDataToJson on TransactionsData {
  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
      'pageSize': pageSize,
    };
  }
}

@freezed
class TransactionDetailResponse with _$TransactionDetailResponse {
  const factory TransactionDetailResponse({
    required bool success,
    required String message,
    @JsonKey(toJson: _transactionToJson, fromJson: _transactionFromJson) Transaction? data,
  }) = _TransactionDetailResponse;

  factory TransactionDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionDetailResponseFromJson(json);
}

// Helper functions for Transaction serialization
Transaction? _transactionFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return Transaction.fromJson(json);
}

Map<String, dynamic>? _transactionToJson(Transaction? data) {
  return data?.toJson();
}

// Statistics Models
@freezed
class StatisticsResponse with _$StatisticsResponse {
  const factory StatisticsResponse({
    required bool success,
    required String message,
    StatisticsData? data,
  }) = _StatisticsResponse;

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$StatisticsResponseFromJson(json);
}

@freezed
class StatisticsData with _$StatisticsData {
  const factory StatisticsData({
    required double totalExpenses,
    required double totalIncome,
    required List<MonthlyStat> monthlyStats,
  }) = _StatisticsData;

  factory StatisticsData.fromJson(Map<String, dynamic> json) =>
      _$StatisticsDataFromJson(json);
}

@freezed
class MonthlyStat with _$MonthlyStat {
  const factory MonthlyStat({
    required String month,
    required double expenses,
    required double income,
  }) = _MonthlyStat;

  factory MonthlyStat.fromJson(Map<String, dynamic> json) =>
      _$MonthlyStatFromJson(json);
}

// Payment Methods
@freezed
class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod({
    required String id,
    required String type,
    required String name,
    String? lastFour,
    String? expiryDate,
  }) = _PaymentMethod;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}

@freezed
class PaymentMethodsResponse with _$PaymentMethodsResponse {
  const factory PaymentMethodsResponse({
    required bool success,
    required String message,
    List<PaymentMethod>? data,
  }) = _PaymentMethodsResponse;

  factory PaymentMethodsResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodsResponseFromJson(json);
}

// Countries & Operators
@freezed
class Country with _$Country {
  const factory Country({
    @JsonKey(name: 'isoName') required String code,
    required String name,
    required String flag,
    String? continent,
    @JsonKey(name: 'currencyCode') String? currencyCode,
    @JsonKey(name: 'currencyName') String? currencyName,
    @JsonKey(name: 'currencySymbol') String? currencySymbol,
    @JsonKey(name: 'callingCodes', fromJson: _callingCodesFromJson) List<String>? callingCodes,
  }) = _Country;

  factory Country.fromJson(Map<String, dynamic> json) =>
      _$CountryFromJson(json);
}

/// Helper function to convert callingCodes from dynamic list to List<String>
List<String>? _callingCodesFromJson(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return null;
}

@freezed
class CountriesResponse with _$CountriesResponse {
  const factory CountriesResponse({
    required bool success,
    required String message,
    List<Country>? data,
  }) = _CountriesResponse;

  factory CountriesResponse.fromJson(dynamic json) {
    // Handle case where API returns a List directly
    if (json is List) {
      final countries = <Country>[];
      for (var item in json) {
        try {
          if (item is Map<String, dynamic>) {
            final country = Country.fromJson(item);
            countries.add(country);
          }
        } catch (e) {
          // Skip invalid country entries but continue parsing others
          print('⚠️ Failed to parse country: $e');
        }
      }
      return CountriesResponse(
        success: true,
        message: 'Countries loaded successfully',
        data: countries,
      );
    }
    // Handle case where API returns a wrapped response
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      List<Country>? countries;
      if (data is List) {
        countries = <Country>[];
        for (var item in data) {
          try {
            if (item is Map<String, dynamic>) {
              final country = Country.fromJson(item);
              countries.add(country);
            }
          } catch (e) {
            // Skip invalid country entries but continue parsing others
            print('⚠️ Failed to parse country: $e');
          }
        }
      }
      return CountriesResponse(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String? ?? '',
        data: countries,
      );
    }
    throw Exception('Invalid JSON format for CountriesResponse');
  }
}

@freezed
class Operator with _$Operator {
  const factory Operator({
    required String id,
    required String name,
    required String countryCode,
    String? logo,
  }) = _Operator;

  factory Operator.fromJson(Map<String, dynamic> json) =>
      _$OperatorFromJson(json);
}

@freezed
class OperatorsResponse with _$OperatorsResponse {
  const factory OperatorsResponse({
    required bool success,
    required String message,
    List<Operator>? data,
  }) = _OperatorsResponse;

  factory OperatorsResponse.fromJson(Map<String, dynamic> json) =>
      _$OperatorsResponseFromJson(json);
}

// Autodetect Models
@freezed
class AutodetectRequest with _$AutodetectRequest {
  const factory AutodetectRequest({
    required String phone,
    required String countryIsoCode,
  }) = _AutodetectRequest;

  factory AutodetectRequest.fromJson(Map<String, dynamic> json) =>
      _$AutodetectRequestFromJson(json);
}

@freezed
class AutodetectResponse with _$AutodetectResponse {
  const factory AutodetectResponse({
    required bool success,
    required String message,
    AutodetectData? data,
  }) = _AutodetectResponse;

  factory AutodetectResponse.fromJson(dynamic json) {
    // Handle case where API returns operator data directly (not wrapped)
    if (json is Map<String, dynamic>) {
      // Check if this is a direct operator response (has operatorId, name, etc.)
      if (json.containsKey('operatorId') || json.containsKey('id')) {
        try {
          final operatorData = AutodetectData.fromJson(json);
          return AutodetectResponse(
            success: true,
            message: 'Operator detected successfully',
            data: operatorData,
          );
        } catch (e) {
          // If parsing fails, try wrapped format
          return AutodetectResponse(
            success: json['success'] as bool? ?? false,
            message: json['message'] as String? ?? '',
            data: json['data'] != null ? AutodetectData.fromJson(json['data'] as Map<String, dynamic>) : null,
          );
        }
      }
      // Handle wrapped response format
      return AutodetectResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        data: json['data'] != null ? AutodetectData.fromJson(json['data'] as Map<String, dynamic>) : null,
      );
    }
    throw Exception('Invalid JSON format for AutodetectResponse');
  }
}

@freezed
class AutodetectData with _$AutodetectData {
  const factory AutodetectData({
    required int id,
    required int operatorId,
    required String name,
    required String countryIsoCode,
    required String countryName,
    required double minAmount,
    required double maxAmount,
    double? localMinAmount,
    double? localMaxAmount,
    required String senderCurrencyCode,
    required String senderCurrencySymbol,
    required String destinationCurrencyCode,
    required String destinationCurrencySymbol,
    double? mostPopularAmount,
    double? mostPopularLocalAmount,
    Map<String, dynamic>? fx,
    List<double>? suggestedAmounts,
    List<double>? suggestedAmountsMap,
    String? logoUrl,
  }) = _AutodetectData;

  factory AutodetectData.fromJson(Map<String, dynamic> json) {
    // Handle nested country object - extract country info
    final countryData = json['country'];
    String countryIsoCode = '';
    String countryName = '';
    
    if (countryData is Map<String, dynamic>) {
      countryIsoCode = countryData['isoName'] as String? ?? 
                       countryData['code'] as String? ?? 
                       '';
      countryName = countryData['name'] as String? ?? '';
    } else if (json.containsKey('countryIsoCode')) {
      countryIsoCode = json['countryIsoCode'] as String? ?? '';
    }
    
    if (json.containsKey('countryName')) {
      countryName = json['countryName'] as String? ?? '';
    }
    
    // Parse suggestedAmounts from API response
    List<double>? suggestedAmounts;
    if (json['suggestedAmounts'] != null) {
      final rawAmounts = json['suggestedAmounts'] as List<dynamic>;
      suggestedAmounts = rawAmounts.map((e) => (e as num).toDouble()).toList();
    }
    
    // Parse suggestedAmountsMap (alternative field name)
    List<double>? suggestedAmountsMap;
    if (json['suggestedAmountsMap'] != null) {
      final rawMap = json['suggestedAmountsMap'];
      if (rawMap is List) {
        suggestedAmountsMap = rawMap.map((e) => (e as num).toDouble()).toList();
      } else if (rawMap is Map) {
        suggestedAmountsMap = rawMap.values.map((e) => (e as num).toDouble()).toList();
      }
    }
    
    // Manually construct the object
    return AutodetectData(
      id: json['id'] as int? ?? json['operatorId'] as int? ?? 0,
      operatorId: json['operatorId'] as int? ?? json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      countryIsoCode: countryIsoCode,
      countryName: countryName,
      minAmount: (json['minAmount'] as num?)?.toDouble() ?? 0.0,
      maxAmount: (json['maxAmount'] as num?)?.toDouble() ?? 0.0,
      localMinAmount: (json['localMinAmount'] as num?)?.toDouble(),
      localMaxAmount: (json['localMaxAmount'] as num?)?.toDouble(),
      senderCurrencyCode: json['senderCurrencyCode'] as String? ?? '',
      senderCurrencySymbol: json['senderCurrencySymbol'] as String? ?? '',
      destinationCurrencyCode: json['destinationCurrencyCode'] as String? ?? '',
      destinationCurrencySymbol: json['destinationCurrencySymbol'] as String? ?? '',
      mostPopularAmount: (json['mostPopularAmount'] as num?)?.toDouble(),
      mostPopularLocalAmount: (json['mostPopularLocalAmount'] as num?)?.toDouble(),
      fx: json['fx'] as Map<String, dynamic>?,
      suggestedAmounts: suggestedAmounts,
      suggestedAmountsMap: suggestedAmountsMap,
      logoUrl: json['logoUrl'] as String? ?? json['logo'] as String?,
    );
  }
}

// Airtime Recharge Models
@freezed
class AirtimeRechargeRequest with _$AirtimeRechargeRequest {
  const factory AirtimeRechargeRequest({
    required String userId,
    required int operatorId,
    required double amount,
    required String customIdentifier,
    required String recipientEmail,
    required String recipientNumber,
    required String recipientCountryCode,
    required String senderNumber,
    required String senderCountryCode,
  }) = _AirtimeRechargeRequest;

  factory AirtimeRechargeRequest.fromJson(Map<String, dynamic> json) =>
      _$AirtimeRechargeRequestFromJson(json);
}

@freezed
class AirtimeRechargeResponse with _$AirtimeRechargeResponse {
  const factory AirtimeRechargeResponse({
    required int transactionId,
    required String status,
    String? operatorTransactionId,
    String? customIdentifier,
    String? recipientPhone,
    String? recipientEmail,
    String? senderPhone,
    String? countryCode,
    int? operatorId,
    String? operatorName,
    double? discount,
    String? discountCurrencyCode,
    double? requestedAmount,
    String? requestedAmountCurrencyCode,
    double? deliveredAmount,
    String? deliveredAmountCurrencyCode,
    String? transactionDate,
    dynamic pinDetail,
    double? fee,
    BalanceInfo? balanceInfo,
  }) = _AirtimeRechargeResponse;

  factory AirtimeRechargeResponse.fromJson(Map<String, dynamic> json) =>
      _$AirtimeRechargeResponseFromJson(json);
}

@freezed
class BalanceInfo with _$BalanceInfo {
  const factory BalanceInfo({
    required double oldBalance,
    required double newBalance,
    required double cost,
    required String currencyCode,
    required String currencyName,
    required DateTime updatedAt,
  }) = _BalanceInfo;

  factory BalanceInfo.fromJson(Map<String, dynamic> json) =>
      _$BalanceInfoFromJson(json);
}

// Keeping AirtimeRechargeData for backward compatibility
@freezed
class AirtimeRechargeData with _$AirtimeRechargeData {
  const factory AirtimeRechargeData({
    required String transactionId,
    required String status,
    required double amount,
    required String currency,
    required String recipientNumber,
    required DateTime createdAt,
  }) = _AirtimeRechargeData;

  factory AirtimeRechargeData.fromJson(Map<String, dynamic> json) =>
      _$AirtimeRechargeDataFromJson(json);
}

// Data Bundle Models
@freezed
class DataOperatorsRequest with _$DataOperatorsRequest {
  const factory DataOperatorsRequest({
    required String countryCode,
  }) = _DataOperatorsRequest;

  factory DataOperatorsRequest.fromJson(Map<String, dynamic> json) =>
      _$DataOperatorsRequestFromJson(json);
}

@freezed
class DataOperatorsResponse with _$DataOperatorsResponse {
  const factory DataOperatorsResponse({
    required bool success,
    required String message,
    List<DataOperator>? data,
  }) = _DataOperatorsResponse;

  factory DataOperatorsResponse.fromJson(Map<String, dynamic> json) =>
      _$DataOperatorsResponseFromJson(json);
}

@freezed
class DataOperator with _$DataOperator {
  const factory DataOperator({
    required int id,
    required int operatorId,
    required String name,
    required bool bundle,
    required bool data,
    String? countryIsoCode,
    String? countryName,
    Map<String, dynamic>? fx,
    String? logoUrl,
  }) = _DataOperator;

  factory DataOperator.fromJson(Map<String, dynamic> json) =>
      _$DataOperatorFromJson(json);
}

@freezed
class DataBundle with _$DataBundle {
  const factory DataBundle({
    required int id,
    required String name,
    required String description,
    required double amount,
    required String currency,
    String? validity,
    double? dataAmount,
    Map<String, dynamic>? metadata,
    String? planId, // Add planId for Ghana data bundles
  }) = _DataBundle;

  factory DataBundle.fromJson(Map<String, dynamic> json) =>
      _$DataBundleFromJson(json);
}

@freezed
class DataPurchaseRequest with _$DataPurchaseRequest {
  const factory DataPurchaseRequest({
    required String userId,
    required int operatorId,
    required String recipientNumber,
    required String recipientCountryCode,
    required String senderNumber,
    required String senderCountryCode,
    required String recipientEmail,
    required String customIdentifier,
    required int bundleId,
    double? amount,
    String? userName, // Required by API - user's phone number/username
  }) = _DataPurchaseRequest;

  factory DataPurchaseRequest.fromJson(Map<String, dynamic> json) =>
      _$DataPurchaseRequestFromJson(json);
}

@freezed
class DataPurchaseResponse with _$DataPurchaseResponse {
  const factory DataPurchaseResponse({
    required int transactionId,
    required String status,
    String? operatorTransactionId,
    String? customIdentifier,
    String? recipientPhone,
    String? recipientEmail,
    String? senderPhone,
    String? countryCode,
    int? operatorId,
    String? operatorName,
    String? bundleName,
    double? discount,
    String? discountCurrencyCode,
    double? requestedAmount,
    String? requestedAmountCurrencyCode,
    double? deliveredAmount,
    String? deliveredAmountCurrencyCode,
    String? transactionDate,
    dynamic pinDetail,
    double? fee,
    BalanceInfo? balanceInfo,
  }) = _DataPurchaseResponse;

  factory DataPurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$DataPurchaseResponseFromJson(json);
}

@freezed
class DataPurchaseData with _$DataPurchaseData {
  const factory DataPurchaseData({
    required String transactionId,
    required String status,
    required double amount,
    required String currency,
    required String recipientNumber,
    required String bundleName,
    required DateTime createdAt,
  }) = _DataPurchaseData;

  factory DataPurchaseData.fromJson(Map<String, dynamic> json) =>
      _$DataPurchaseDataFromJson(json);
}

// AdvansiPay Initiate Payment Models
@freezed
class AdvansiPayInitRequest with _$AdvansiPayInitRequest {
  const factory AdvansiPayInitRequest({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String username,
    required double amount,
    required String orderDesc,
    required String orderId,
    @Default('https://advansistechnologies.com/assets/img/home-six/featured/icon1.png')
    String orderImgUrl,
  }) = _AdvansiPayInitRequest;

  factory AdvansiPayInitRequest.fromJson(Map<String, dynamic> json) =>
      _$AdvansiPayInitRequestFromJson(json);
}

@freezed
class AdvansiPayInitResponse with _$AdvansiPayInitResponse {
  const factory AdvansiPayInitResponse({
    required int status,
    required String message,
    AdvansiPayInitData? data,
  }) = _AdvansiPayInitResponse;

  factory AdvansiPayInitResponse.fromJson(Map<String, dynamic> json) =>
      _$AdvansiPayInitResponseFromJson(json);
}

@freezed
class AdvansiPayInitData with _$AdvansiPayInitData {
  const factory AdvansiPayInitData({
    required String checkoutUrl,
    required String token,
    @JsonKey(name: 'order-id') required String orderId,
  }) = _AdvansiPayInitData;

  factory AdvansiPayInitData.fromJson(Map<String, dynamic> json) =>
      _$AdvansiPayInitDataFromJson(json);
}

// AdvansiPay Query Transaction Models
@freezed
class AdvansiPayQueryRequest with _$AdvansiPayQueryRequest {
  const factory AdvansiPayQueryRequest({
    required String token,
  }) = _AdvansiPayQueryRequest;

  factory AdvansiPayQueryRequest.fromJson(Map<String, dynamic> json) =>
      _$AdvansiPayQueryRequestFromJson(json);
}

@freezed
class AdvansiPayQueryResponse with _$AdvansiPayQueryResponse {
  const factory AdvansiPayQueryResponse({
    required int status,
    required String message,
    AdvansiPayQueryData? data,
  }) = _AdvansiPayQueryResponse;

  factory AdvansiPayQueryResponse.fromJson(Map<String, dynamic> json) =>
      _$AdvansiPayQueryResponseFromJson(json);
}

@freezed
class AdvansiPayQueryData with _$AdvansiPayQueryData {
  const factory AdvansiPayQueryData({
    String? orderId,
    String? transactionId,
    String? status, // 'COMPLETED', 'PENDING', 'FAILED', 'CANCELLED'
    String? amount,
    String? currency,
    String? resultText, // 'Success' or error message
    @JsonKey(name: 'auth-code') String? authCode,
    @JsonKey(name: 'date-processed') String? dateProcessed,
    AdvansiPayOriginalResponse? originalResponse,
  }) = _AdvansiPayQueryData;

  factory AdvansiPayQueryData.fromJson(Map<String, dynamic> json) =>
      _$AdvansiPayQueryDataFromJson(json);
}

@freezed
class AdvansiPayOriginalResponse with _$AdvansiPayOriginalResponse {
  const factory AdvansiPayOriginalResponse({
    int? result,
    @JsonKey(name: 'result-text') String? resultText,
    @JsonKey(name: 'order-id') String? orderId,
    String? token,
    String? currency,
    String? amount,
    @JsonKey(name: 'auth-code') String? authCode,
    @JsonKey(name: 'transaction-id') String? transactionId,
    @JsonKey(name: 'date-processed') String? dateProcessed,
  }) = _AdvansiPayOriginalResponse;

  factory AdvansiPayOriginalResponse.fromJson(Map<String, dynamic> json) =>
      _$AdvansiPayOriginalResponseFromJson(json);
}

// Topup Parameters (stored locally for after-payment crediting)
@freezed
class TopupParams with _$TopupParams {
  const factory TopupParams({
    required int operatorId,
    required double amount,
    required String description,
    required String recipientEmail,
    required String recipientNumber,
    required String recipientCountryCode,
    required String senderNumber,
    required String senderCountryCode,
    required String payTransRef,
    required String transType, // 'GLOBALAIRTOPUP' or 'GLOBALDATATOPUP'
    required String customerEmail,
    String? customIdentifier,
    String? bundleId, // For data bundles (as plan_id string)
    String? dataCode, // For Ghana data bundles - plan_id from bundle list
    int? ghanaNetworkCode, // For Ghana network selection
  }) = _TopupParams;

  factory TopupParams.fromJson(Map<String, dynamic> json) =>
      _$TopupParamsFromJson(json);
}

// ExpressPay Payment Models
@freezed
class PaymentRequest with _$PaymentRequest {
  const factory PaymentRequest({
    required double amount,
    required String currency,
    required String paymentMethod, // 'card', 'mobile_money'
    String? cardNumber,
    String? cardExpiry,
    String? cardCvv,
    String? mobileMoneyProvider,
    String? phoneNumber,
    String? description,
    Map<String, dynamic>? metadata,
  }) = _PaymentRequest;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);
}

@freezed
class PaymentResponse with _$PaymentResponse {
  const factory PaymentResponse({
    required bool success,
    required String message,
    PaymentData? data,
  }) = _PaymentResponse;

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);
}

@freezed
class PaymentData with _$PaymentData {
  const factory PaymentData({
    required String transactionId,
    required String paymentReference,
    required String status,
    String? redirectUrl,
    String? qrCode,
    Map<String, dynamic>? paymentDetails,
    required DateTime createdAt,
  }) = _PaymentData;

  factory PaymentData.fromJson(Map<String, dynamic> json) =>
      _$PaymentDataFromJson(json);
}

@freezed
class PaymentVerificationRequest with _$PaymentVerificationRequest {
  const factory PaymentVerificationRequest({
    required String transactionId,
    required String paymentReference,
  }) = _PaymentVerificationRequest;

  factory PaymentVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentVerificationRequestFromJson(json);
}

@freezed
class PaymentVerificationResponse with _$PaymentVerificationResponse {
  const factory PaymentVerificationResponse({
    required bool success,
    required String message,
    PaymentVerificationData? data,
  }) = _PaymentVerificationResponse;

  factory PaymentVerificationResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentVerificationResponseFromJson(json);
}

@freezed
class PaymentVerificationData with _$PaymentVerificationData {
  const factory PaymentVerificationData({
    required String transactionId,
    required String status,
    required double amount,
    required String currency,
    DateTime? completedAt,
  }) = _PaymentVerificationData;

  factory PaymentVerificationData.fromJson(Map<String, dynamic> json) =>
      _$PaymentVerificationDataFromJson(json);
}

@freezed
class ExpressPayMethodsResponse with _$ExpressPayMethodsResponse {
  const factory ExpressPayMethodsResponse({
    required bool success,
    required String message,
    List<ExpressPayMethod>? data,
  }) = _ExpressPayMethodsResponse;

  factory ExpressPayMethodsResponse.fromJson(Map<String, dynamic> json) =>
      _$ExpressPayMethodsResponseFromJson(json);
}

@freezed
class ExpressPayMethod with _$ExpressPayMethod {
  const factory ExpressPayMethod({
    required String id,
    required String name,
    required String type, // 'card', 'mobile_money'
    required bool isAvailable,
    String? icon,
    List<String>? supportedProviders,
  }) = _ExpressPayMethod;

  factory ExpressPayMethod.fromJson(Map<String, dynamic> json) =>
      _$ExpressPayMethodFromJson(json);
}

// ============================================================================
// Rewards & Points (Loyalty)
// ============================================================================

@freezed
class PointsData with _$PointsData {
  const factory PointsData({
    required int points,
  }) = _PointsData;

  factory PointsData.fromJson(Map<String, dynamic> json) {
    final pointsVal = json['points'];
    return PointsData(points: (pointsVal is num) ? pointsVal.toInt() : 0);
  }
}

@freezed
class Reward with _$Reward {
  const factory Reward({
    @JsonKey(name: '_id') String? id,
    String? title,
    String? name,
    String? description,
    @JsonKey(name: 'points') int? pointsRequired,
    @JsonKey(name: 'pointsRequired') int? pointsRequiredAlt,
    String? category,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Reward;

  factory Reward.fromJson(Map<String, dynamic> json) => _$RewardFromJson(json);
}

int _rewardPointsFromReward(Reward r) => r.pointsRequired ?? r.pointsRequiredAlt ?? 0;

@freezed
class RewardsResponse with _$RewardsResponse {
  const factory RewardsResponse({
    @Default(true) bool success,
    @Default('') String message,
    RewardsData? data,
  }) = _RewardsResponse;

  factory RewardsResponse.fromJson(Map<String, dynamic> json) {
    try {
      // 1) { "rewards": [ ... ] }
      if (json['rewards'] is List) {
        return RewardsResponse(
          success: json['success'] as bool? ?? true,
          message: json['message'] as String? ?? '',
          data: RewardsData.fromJson(json),
        );
      }

      // 2) { "data": [ ... ] } or { "data": { "rewards": [ ... ] } }
      final data = json['data'];
      if (data is List) {
        return RewardsResponse(
          success: json['success'] as bool? ?? true,
          message: json['message'] as String? ?? '',
          data: RewardsData(
            rewards: data.whereType<Map<String, dynamic>>().map(Reward.fromJson).toList(),
          ),
        );
      }
      if (data is Map<String, dynamic> && data['rewards'] is List) {
        return RewardsResponse(
          success: json['success'] as bool? ?? true,
          message: json['message'] as String? ?? '',
          data: RewardsData.fromJson(data),
        );
      }

      // 3) Fallback: attempt to parse root as RewardsData
      return RewardsResponse(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String? ?? '',
        data: RewardsData.fromJson(json),
      );
    } catch (e) {
      return RewardsResponse(
        success: false,
        message: 'Failed to parse rewards: $e',
        data: const RewardsData(rewards: []),
      );
    }
  }
}

@freezed
class RewardsData with _$RewardsData {
  const factory RewardsData({
    required List<Reward> rewards,
  }) = _RewardsData;

  factory RewardsData.fromJson(Map<String, dynamic> json) {
    final rawList = (json['rewards'] as List?) ?? (json['data'] as List?) ?? const [];
    final rewards = rawList.whereType<Map<String, dynamic>>().map((r) {
      final reward = Reward.fromJson(r);
      final points = _rewardPointsFromReward(reward);
      // Ensure we have a pointsRequired value populated even if API uses an alternate field
      return reward.copyWith(pointsRequired: reward.pointsRequired ?? points);
    }).toList();
    return RewardsData(rewards: rewards);
  }
}

@freezed
class RewardUpsertRequest with _$RewardUpsertRequest {
  const factory RewardUpsertRequest({
    String? title,
    String? description,
    @JsonKey(name: 'points') int? pointsRequired,
    String? category,
    String? imageUrl,
    bool? isActive,
  }) = _RewardUpsertRequest;

  factory RewardUpsertRequest.fromJson(Map<String, dynamic> json) =>
      _$RewardUpsertRequestFromJson(json);
}

@freezed
class RewardResponse with _$RewardResponse {
  const factory RewardResponse({
    @Default(true) bool success,
    @Default('') String message,
    Reward? data,
  }) = _RewardResponse;

  factory RewardResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json['data'] is Map<String, dynamic>) {
        return RewardResponse(
          success: json['success'] as bool? ?? true,
          message: json['message'] as String? ?? '',
          data: Reward.fromJson(json['data'] as Map<String, dynamic>),
        );
      }
      // Some APIs return the object directly (no wrapper)
      if (json.containsKey('_id') || json.containsKey('title') || json.containsKey('name')) {
        return RewardResponse(success: true, message: '', data: Reward.fromJson(json));
      }
      return RewardResponse(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String? ?? '',
        data: null,
      );
    } catch (e) {
      return RewardResponse(success: false, message: 'Failed to parse reward: $e', data: null);
    }
  }
}

@freezed
class PointsResponse with _$PointsResponse {
  const factory PointsResponse({
    @Default(true) bool success,
    @Default('') String message,
    @Default(0) int points,
    int? pointsAwarded,
  }) = _PointsResponse;

  factory PointsResponse.fromJson(Map<String, dynamic> json) {
    return PointsResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      points: json['points'] as int? ?? json['data']?['points'] as int? ?? 0,
      pointsAwarded: json['pointsAwarded'] as int?,
    );
  }
}

