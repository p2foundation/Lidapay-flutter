# API Integration Guide

This document outlines how the Flutter app integrates with your NestJS backend API.

## Base Configuration

- **Base URL**: `https://api.advansistechnologies.com`
- **API Version**: `/api`
- **API Documentation**: https://api.advansistechnologies.com/api-doc

## Authentication

### Login
```dart
POST /api/auth/login
Body: {
  "phone": "string",
  "password": "string"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "token": "string",
    "refreshToken": "string",
    "user": { ... }
  }
}
```

### Verify OTP
```dart
POST /api/auth/verify-otp
Body: {
  "phone": "string",
  "otp": "string"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "token": "string",
    "refreshToken": "string",
    "user": { ... }
  }
}
```

### Refresh Token
```dart
POST /api/auth/refresh
Body: {
  "refreshToken": "string"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "token": "string",
    "refreshToken": "string"
  }
}
```

## Wallet

### Get Balance
```dart
GET /api/wallet/balance
Headers: {
  "Authorization": "Bearer {token}"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "balance": 0.0,
    "currency": "GHS"
  }
}
```

## Airtime Purchase

### Reloadly (Global)
```dart
POST /api/airtime/reloadly
Headers: {
  "Authorization": "Bearer {token}"
}
Body: {
  "recipientPhone": "string",
  "amount": 0.0,
  "countryCode": "string",
  "operatorId": "string (optional)",
  "note": "string (optional)"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "transactionId": "string",
    "recipientPhone": "string",
    "amount": 0.0,
    "status": "string",
    "createdAt": "datetime"
  }
}
```

### Prymo (Ghana)
```dart
POST /api/airtime/prymo
Headers: {
  "Authorization": "Bearer {token}"
}
Body: {
  "recipientPhone": "string",
  "amount": 0.0,
  "countryCode": "GH",
  "operatorId": "string (optional)",
  "note": "string (optional)"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "transactionId": "string",
    "recipientPhone": "string",
    "amount": 0.0,
    "status": "string",
    "createdAt": "datetime"
  }
}
```

**Implementation Note**: The app automatically selects Prymo for Ghana (`countryCode: "GH"`) and Reloadly for other countries.

## Data Purchase

```dart
POST /api/data/purchase
Headers: {
  "Authorization": "Bearer {token}"
}
Body: {
  "recipientPhone": "string",
  "dataAmount": 0.0,
  "countryCode": "string",
  "operatorId": "string (optional)",
  "dataPlanId": "string (optional)"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "transactionId": "string",
    "recipientPhone": "string",
    "dataAmount": 0.0,
    "status": "string",
    "createdAt": "datetime"
  }
}
```

## Transactions

### Get Transactions
```dart
GET /api/transactions?page=1&pageSize=20&type=airtime&status=completed&startDate=2024-01-01&endDate=2024-12-31
Headers: {
  "Authorization": "Bearer {token}"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "transactions": [
      {
        "id": "string",
        "type": "airtime|data|transfer",
        "amount": 0.0,
        "currency": "string",
        "status": "pending|completed|failed",
        "createdAt": "datetime",
        "recipientPhone": "string (optional)",
        "recipientName": "string (optional)",
        "note": "string (optional)",
        "paymentMethod": "string (optional)"
      }
    ],
    "total": 0,
    "page": 1,
    "pageSize": 20
  }
}
```

### Get Transaction Detail
```dart
GET /api/transactions/{id}
Headers: {
  "Authorization": "Bearer {token}"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "id": "string",
    "type": "string",
    "amount": 0.0,
    "currency": "string",
    "status": "string",
    "createdAt": "datetime",
    ...
  }
}
```

## Statistics

```dart
GET /api/statistics?period=month&startDate=2024-01-01&endDate=2024-12-31
Headers: {
  "Authorization": "Bearer {token}"
}
Response: {
  "success": true,
  "message": "string",
  "data": {
    "totalExpenses": 0.0,
    "totalIncome": 0.0,
    "monthlyStats": [
      {
        "month": "Jan",
        "expenses": 0.0,
        "income": 0.0
      }
    ]
  }
}
```

## Payment Methods

```dart
GET /api/payment-methods
Headers: {
  "Authorization": "Bearer {token}"
}
Response: {
  "success": true,
  "message": "string",
  "data": [
    {
      "id": "string",
      "type": "card|bank|mobile_money",
      "name": "string",
      "lastFour": "string (optional)",
      "expiryDate": "string (optional)"
    }
  ]
}
```

## Countries & Operators

### Get Countries
```dart
GET /api/countries
Response: {
  "success": true,
  "message": "string",
  "data": [
    {
      "code": "GH",
      "name": "Ghana",
      "flag": "🇬🇭"
    }
  ]
}
```

### Get Operators
```dart
GET /api/operators?countryCode=GH
Response: {
  "success": true,
  "message": "string",
  "data": [
    {
      "id": "string",
      "name": "MTN",
      "countryCode": "GH",
      "logo": "url (optional)"
    }
  ]
}
```

## Error Handling

All endpoints return errors in this format:
```json
{
  "success": false,
  "message": "Error message",
  "data": null
}
```

Common HTTP status codes:
- `200`: Success
- `400`: Bad Request
- `401`: Unauthorized (token expired/invalid)
- `404`: Not Found
- `500`: Server Error

## Authentication Flow

1. User logs in with phone/password
2. Backend returns `token` and `refreshToken`
3. Token is stored in SharedPreferences
4. Token is automatically added to all API requests via `AuthInterceptor`
5. On 401 error, app attempts token refresh
6. On refresh failure, user is logged out

## Implementation Files

- **API Client**: `lib/data/datasources/api_client.dart`
- **Models**: `lib/data/models/api_models.dart`
- **Repositories**: `lib/data/repositories/*.dart`
- **Providers**: `lib/presentation/providers/*.dart`

## Testing API Integration

1. Use Postman/Insomnia to test endpoints directly
2. Check API documentation: https://api.advansistechnologies.com/api-doc
3. Verify request/response formats match models
4. Test error scenarios (invalid token, network errors)

## Notes

- All monetary amounts are in the currency specified (default: GHS)
- Phone numbers should include country code (e.g., +233241234567)
- Dates are in ISO 8601 format
- The app handles both Reloadly (global) and Prymo (Ghana) automatically based on country code

