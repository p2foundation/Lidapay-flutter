# ExpressPay Payment Flow Guide

## Current Implementation Overview

The LidaPay app uses ExpressPay for payment processing. Here's how the flow works:

### 1. Payment Initiation
- User confirms airtime/data purchase
- App calls `paymentService.initiatePayment()`
- API returns ExpressPay checkout URL
- Browser opens with ExpressPay payment page

### 2. Payment Processing
- User selects payment method on ExpressPay
- ExpressPay processes the payment
- Upon completion, ExpressPay redirects back to app

### 3. Payment Callback
- Deep link callback is triggered
- App queries transaction status
- If successful, airtime/data is credited
- Receipt screen is shown

## Best Practices for ExpressPay Integration

### 1. **Browser Launch Strategy**
```dart
// Current implementation uses external browser
final launched = await launchUrl(
  uri,
  mode: LaunchMode.externalApplication,
);
```

**Recommendations:**
- ✅ Use `externalApplication` mode for better security
- ✅ Ensures payment page opens in full browser (not WebView)
- ✅ Reduces risk of payment interception

### 2. **Payment State Management**
```dart
// Store payment info before redirect
await paymentService.storePendingTopup(params);

// Update payment flow state
_ref.read(paymentFlowStateProvider.notifier).state = PaymentFlowState.redirecting;
```

**Best Practices:**
- ✅ Store transaction details locally
- ✅ Track payment state throughout flow
- ✅ Handle app backgrounding/foregrounding

### 3. **Deep Link Handling**
```dart
// AndroidManifest.xml configuration
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="lidapay"/>
</intent-filter>
```

**Important:**
- ✅ Multiple deep link schemes configured
- ✅ Handles ExpressPay redirect URLs
- ✅ Fallback mechanisms in place

### 4. **Error Handling**
```dart
try {
    final result = await paymentService.initiatePayment(...);
    if (result.success) {
        // Handle success
    } else {
        // Show error message
    }
} catch (e) {
    // Handle exceptions
}
```

## Testing the Payment Flow

### 1. **Sandbox Testing**
- Use ExpressPay sandbox environment
- Test with small amounts (GHS 1.00)
- Verify all payment methods work

### 2. **Test Scenarios**
- ✅ Successful payment
- ✅ Failed payment
- ✅ Cancelled payment
- ✅ Network interruptions
- ✅ App backgrounding during payment

### 3. **Real Device Testing**
```bash
# Build release APK for testing
flutter build apk --release

# Install on device
adb install app-release.apk
```

## Payment Flow Optimization

### 1. **Pre-Payment Checks**
```dart
// Check network connectivity
if (!await hasNetworkConnection()) {
    showError('No internet connection');
    return;
}

// Validate user session
if (!isUserLoggedIn()) {
    navigateToLogin();
    return;
}

// Check minimum amount
if (amount < 1.0) {
    showError('Minimum amount is GHS 1.00');
    return;
}
```

### 2. **User Experience Improvements**
- Show loading indicators during payment initiation
- Display clear payment status messages
- Provide option to retry failed payments
- Send payment confirmations via email/SMS

### 3. **Security Considerations**
- Never store card details
- Use HTTPS for all API calls
- Validate payment responses
- Implement rate limiting

## Troubleshooting Common Issues

### 1. **Browser Not Opening**
```dart
// Ensure URL launcher is configured
if (!await launchUrl(uri)) {
    // Show manual payment option
    showPaymentInstructions();
}
```

### 2. **Deep Link Not Working**
- Verify AndroidManifest configuration
- Test deep link with ADB:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "lidapay://test" com.advansistechnologies.lidapay
```

### 3. **Payment Not Credited**
- Check API response status
- Verify webhook configuration
- Review transaction logs

## Production Checklist

### Before Going Live:
- [ ] Test with real payment methods
- [ ] Verify all error scenarios
- [ ] Set up monitoring and alerts
- [ ] Configure webhooks properly
- [ ] Test on multiple devices
- [ ] Verify receipt generation
- [ ] Check customer support process

### Monitoring:
- Track success rates
- Monitor API response times
- Set alerts for failures
- Review transaction logs daily

## API Response Handling

### Success Response:
```json
{
    "status": 201,
    "message": "Payment initiated successfully.",
    "data": {
        "checkoutUrl": "https://expresspaygh.com/api/checkout.php?token=...",
        "token": "432069583af2cb0115...",
        "order-id": "ADV-MJXEC4FA-7800A448"
    }
}
```

### Query Transaction Response:
```json
{
    "transactionId": 29235758,
    "status": "SUCCESSFUL",
    "operatorTransactionId": null,
    "customIdentifier": "TXN-MJXEENVW-7ECF1422",
    "recipientPhone": "233244588584",
    "operatorName": "MTN Ghana",
    "deliveredAmount": 9.15201,
    "deliveredAmountCurrencyCode": "GHS"
}
```

## Best Practices Summary

1. **Always use external browser** for security
2. **Store payment state** before redirecting
3. **Handle all edge cases** (network errors, cancellations)
4. **Provide clear feedback** to users
5. **Test thoroughly** before production
6. **Monitor transactions** in real-time
7. **Have fallback options** ready
8. **Keep users informed** throughout the process

## Code Example: Complete Payment Flow

```dart
Future<void> processPayment() async {
    try {
        // 1. Show loading
        setLoading(true);
        
        // 2. Validate inputs
        if (!validateInputs()) return;
        
        // 3. Store pending transaction
        await storePendingPayment();
        
        // 4. Initiate payment
        final result = await paymentService.initiatePayment();
        
        // 5. Launch browser
        if (result.success) {
            await launchUrl(result.checkoutUrl);
            navigateToWaitingScreen();
        } else {
            showError(result.message);
        }
    } catch (e) {
        handleError(e);
    } finally {
        setLoading(false);
    }
}
```

This approach ensures a smooth, secure, and reliable payment experience for your users.
