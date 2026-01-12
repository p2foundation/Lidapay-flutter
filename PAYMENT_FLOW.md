# LidaPay Payment Flow

## Overview

The payment flow for airtime and data purchases follows a two-step process:
1. **Payment Authorization** - User authorizes payment via ExpressPay Ghana
2. **Service Crediting** - After successful payment, the service (airtime/data) is credited

## Flow Diagram

```
┌─────────────────────┐
│   Confirm Screen    │
│  (Review Details)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Initiate Payment   │
│ (AdvansiPay API)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Open Checkout     │
│  (ExpressPay URL)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  User Authorizes    │
│  (MoMo PIN/Card)    │
│  ~90 seconds wait   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  App Resumes /      │
│  Deep Link Callback │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Credit Service    │
│ (Airtime or Data)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Success Screen    │
└─────────────────────┘
```

## API Endpoints

### 1. Initiate Payment
- **Endpoint:** `POST /api/v1/advansispay/initiate-payment`
- **Request Body:**
```json
{
  "userId": "673ba0e3f2c001e4dcee976e",
  "firstName": "Hanson",
  "lastName": "Peprah",
  "email": "hanson.pepra@gmail.com",
  "phoneNumber": "0244588584",
  "username": "hanso",
  "amount": 10,
  "orderDesc": "Hanson airtime payment to 0244588584 on 20062025",
  "orderId": "ORDER123456789",
  "orderImgUrl": "https://advansistechnologies.com/assets/img/home-six/featured/icon1.png"
}
```
- **Response:**
```json
{
  "status": 201,
  "message": "Payment initiated successfully.",
  "data": {
    "checkoutUrl": "https://expresspaygh.com/api/checkout.php?token=...",
    "token": "163469534c526ec660...",
    "order-id": "ADV-MJS1W4MW-95FAB923"
  }
}
```

### 2. Recharge Airtime
- **Endpoint:** `POST /api/v1/reload-airtime/recharge`
- **Request Body:**
```json
{
  "userId": "673ba0e3f2c001e4dcee976e",
  "operatorId": 341,
  "amount": 10,
  "customIdentifier": "reloadly-airtime 161124",
  "recipientEmail": "user@example.com",
  "recipientNumber": "2348130678848",
  "recipientCountryCode": "NG",
  "senderNumber": "0244588584",
  "senderCountryCode": "GH"
}
```

### 3. Buy Data
- **Endpoint:** `POST /api/v1/reloadly-data/buy-data`
- **Request Body:**
```json
{
  "userId": "673ba0e3f2c001e4dcee976e",
  "operatorId": 643,
  "amount": 50,
  "customIdentifier": "reloadly-data bundle 0925",
  "recipientEmail": "user@example.com",
  "recipientNumber": "0244588584",
  "recipientCountryCode": "GH",
  "senderNumber": "0244588584",
  "senderCountryCode": "GH"
}
```

## Transaction Types

| Type | TransType Value | Description |
|------|-----------------|-------------|
| Airtime | `GLOBALAIRTOPUP` | International airtime recharge |
| Data | `GLOBALDATATOPUP` | International data bundle purchase |

## Deep Linking Configuration

### Android (AndroidManifest.xml)
```xml
<!-- Custom scheme: lidapay:// -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="lidapay"/>
</intent-filter>

<!-- HTTPS deep links: https://lidapay.app -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data 
        android:scheme="https"
        android:host="lidapay.app"/>
</intent-filter>
```

### Callback URL Format
```
lidapay://payment/callback?status=success&token=xxx&order-id=xxx
https://lidapay.app/payment/callback?status=success&token=xxx&order-id=xxx
```

## Payment States

| State | Description |
|-------|-------------|
| `idle` | Initial state, no payment in progress |
| `initiating` | Calling AdvansiPay initiate API |
| `redirecting` | Opening checkout URL in browser |
| `awaitingCallback` | Waiting for user to complete payment |
| `crediting` | Payment confirmed, crediting service |
| `success` | Transaction complete |
| `failed` | Transaction failed |
| `cancelled` | User cancelled payment |

## Files Modified

- `lib/data/models/api_models.dart` - Added AdvansiPay models
- `lib/data/datasources/api_client.dart` - Added initiateAdvansiPay endpoint
- `lib/core/services/payment_service.dart` - Created payment flow service
- `lib/presentation/features/airtime/screens/confirm_airtime_screen.dart` - Integrated payment flow
- `lib/presentation/features/data/screens/confirm_data_screen.dart` - Integrated payment flow
- `lib/presentation/features/payment/screens/payment_callback_screen.dart` - Created callback screen
- `lib/core/routes/app_router.dart` - Added payment callback route
- `lib/main.dart` - Added deep link handling
- `android/app/src/main/AndroidManifest.xml` - Added deep link intent filters
- `pubspec.yaml` - Added app_links package

