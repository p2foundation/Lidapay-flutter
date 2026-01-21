# Prymo API Endpoint Fix

## Problem
The Ghana airtime purchase was failing with a 404 error when trying to credit airtime via the Prymo API. The error showed that the app was trying to POST to an incorrect endpoint.

## Root Causes
1. **Incorrect Endpoint Path**: The airtime credit endpoint was using the wrong path
2. **Missing Authentication Headers**: The Prymo credit endpoints require ApiKey and ApiSecret headers, but they were not being passed

## Solution

### 1. Fixed Endpoint Path
Updated the API client to use the correct Prymo airtime credit endpoint:
- Airtime credit: Changed to `/api/v1/reload-airtime/recharge` (the correct Prymo crediting endpoint)
- Data credit: Uses `/TopUpApi/dataCredit`

### 2. Added Authentication Headers
Updated both credit endpoints to require ApiKey and ApiSecret headers:
```dart
@POST('/api/v1/reload-airtime/recharge')
Future<HttpResponse<dynamic>> prymoCreditAirtime(
  @Body() Map<String, dynamic> request,
  @Header('ApiKey') String apiKey,
  @Header('ApiSecret') String apiSecret,
);

@POST('/TopUpApi/dataCredit')
Future<HttpResponse<dynamic>> prymoCreditData(
  @Body() Map<String, dynamic> request,
  @Header('ApiKey') String apiKey,
  @Header('ApiSecret') String apiSecret,
);
```

### 3. Updated Payment Service
Modified the payment service to pass the API credentials when calling the credit endpoints:
```dart
final response = await _prymoApiClient.prymoCreditAirtime(
  request,
  AppConstants.prymoApiKey,
  AppConstants.prymoApiSecret,
);
```

## Important Note
The Prymo API credentials in `AppConstants` are currently placeholders:
```dart
static const String prymoApiKey = 'YOUR_API_KEY'; // Replace with actual API key
static const String prymoApiSecret = 'YOUR_API_SECRET'; // Replace with actual API secret
```

These need to be replaced with the actual credentials provided by Prymo.

## Testing
After these changes:
1. The app builds successfully
2. The airtime credit endpoint now uses the correct `/api/v1/reload-airtime/recharge` path
3. Authentication headers are properly included
4. Both airtime and data credit flows should work with the Prymo API

## Next Steps
1. Replace the placeholder API credentials with actual ones
2. Test the Ghana airtime and data purchase flows end-to-end
3. Verify that the crediting works after successful payment
