import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/airtime_wizard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/country_flag_widget.dart';

class ConfirmAirtimeScreen extends ConsumerStatefulWidget {
  const ConfirmAirtimeScreen({super.key});

  @override
  ConsumerState<ConfirmAirtimeScreen> createState() => _ConfirmAirtimeScreenState();
}

class _ConfirmAirtimeScreenState extends ConsumerState<ConfirmAirtimeScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;
  String? _error;
  String _statusMessage = '';
  PaymentFlowState _paymentState = PaymentFlowState.idle;
  bool _isNavigatingToReceipt = false;

  static const _countriesRequiringZero = [
    'CI',
    'SN',
    'ML',
    'BF',
    'NE',
    'TG',
    'BJ',
    'GN',
    'CG',
    'CD',
    'CM',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background (after payment)
    if (state == AppLifecycleState.resumed && _paymentState == PaymentFlowState.awaitingCallback) {
      _checkPaymentStatus();
    }
  }

  Future<void> _checkPaymentStatus() async {
    // When user returns from payment page, we need to check if they completed payment
    // For now, show a dialog asking if payment was completed
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Row(
          children: [
            Icon(Icons.payment_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Payment Status')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Did you complete the payment successfully?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Not receiving a payment prompt?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Follow the steps below to authorize payment requests:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildMomoStep('1', 'Dial *170# and select Option 6, ', 'My Wallet.'),
              _buildMomoStep('2', 'Select Option 3 for ', 'My Approvals.'),
              _buildMomoStep('3', 'Enter PIN to get your Pending Approval List.', null),
              _buildMomoStep('4', 'Select pending transaction to approve.', null),
              _buildMomoStep('5', 'Pay', null),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No, Cancel', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, I Paid'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _verifyPaymentAndCredit();
    } else {
      final reference = await _resolvePaymentReference();
      setState(() {
        _isProcessing = false;
        _paymentState = PaymentFlowState.cancelled;
        _statusMessage = '';
        _error = 'Payment was cancelled.';
      });
      if (mounted) {
        _showFailureReceipt('Payment was cancelled.', transactionId: reference);
      }
      ref.read(paymentServiceProvider).clearPendingPayment();
    }
  }

  Future<String?> _resolvePaymentReference() async {
    final paymentService = ref.read(paymentServiceProvider);
    final paymentInfo = await paymentService.getPaymentInfo();
    if (paymentInfo.orderId != null && paymentInfo.orderId!.isNotEmpty) {
      return paymentInfo.orderId;
    }
    final topupParams = await paymentService.getPendingTopup();
    return topupParams?.payTransRef;
  }

  Future<void> _verifyPaymentAndCredit() async {
    setState(() {
      _statusMessage = 'Verifying payment...';
      _error = null;
      _isProcessing = true;
    });

    final paymentService = ref.read(paymentServiceProvider);
    final paymentInfo = await paymentService.getPaymentInfo();
    final token = paymentInfo.token;

    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'We couldn\'t verify the payment. Please try again.';
        _isProcessing = false;
        _statusMessage = '';
        _paymentState = PaymentFlowState.failed;
      });
      if (mounted) {
        _showFailureReceipt(
          'We couldn\'t verify the payment. Please try again.',
          transactionId: paymentInfo.orderId,
        );
      }
      return;
    }

    const maxAttempts = 3;
    PaymentResult? lastResult;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Verifying payment... ($attempt/$maxAttempts)';
      });

      final result = await paymentService.queryPaymentStatus(
        token,
        maxRetries: 1,
        retryDelaySeconds: 0,
      );
      if (!mounted) return;

      if (result.success) {
        await _creditAirtime();
        return;
      }

      lastResult = result;

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 4));
      }
    }

    final message = (lastResult?.message.isNotEmpty ?? false)
        ? lastResult!.message
        : 'We couldn\'t confirm the payment yet. Please try again shortly.';

    setState(() {
      _error = message;
      _isProcessing = false;
      _statusMessage = '';
      _paymentState = PaymentFlowState.failed;
    });
    if (mounted) {
      _showFailureReceipt(message, transactionId: paymentInfo.orderId);
    }
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<void> _initiatePayment() async {
    final wizardState = ref.read(airtimeWizardProvider);
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    final operatorData = wizardState.operatorData;
    final amount = wizardState.selectedAmount;
    final user = ref.read(currentUserProvider).valueOrNull;

    if (country == null || phoneNumber == null || operatorData == null || amount == null) {
      setState(() {
        _error = 'Missing required information. Please start over.';
      });
      return;
    }

    final normalizedPhone = _normalizePhoneNumber(country, phoneNumber);
    final displayPhone = _formatPhoneForDisplay(country, normalizedPhone);

    setState(() {
      _isProcessing = true;
      _error = null;
      _statusMessage = 'Preparing payment...';
      _paymentState = PaymentFlowState.initiating;
    });

    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User ID not found. Please login again.');
      }

      // Calculate FX converted amount for payment
      final fxRate = operatorData.fx?['rate'] as double?;
      final fxCurrencyCode = operatorData.fx?['currencyCode'] as String?;
      final paymentAmount = fxRate != null ? (amount * fxRate) : amount;
      final paymentCurrency = fxCurrencyCode ?? country.currencyCode ?? 'GHS';
      final senderSymbol = operatorData.senderCurrencySymbol;
      final senderCurrency = operatorData.senderCurrencyCode;

      // Generate unique reference
      final payTransRef = generatePaymentReference();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Prepare topup params for after-payment crediting
      final topupParams = TopupParams(
        operatorId: operatorData.operatorId,
        amount: amount,
        description: 'Top-up: $senderCurrency ${amount.toStringAsFixed(2)} | Pay: $paymentCurrency ${paymentAmount.toStringAsFixed(2)} for $displayPhone (${operatorData.name})',
        recipientEmail: user?.email ?? 'user@example.com',
        recipientNumber: normalizedPhone,
        recipientCountryCode: country.code,
        senderNumber: user?.phoneNumber ?? '',
        senderCountryCode: user?.country ?? 'GH',
        payTransRef: payTransRef,
        transType: 'GLOBALAIRTOPUP',
        customerEmail: user?.email ?? '',
        customIdentifier: 'reloadly-airtime $timestamp',
      );

      setState(() {
        _statusMessage = 'Initiating payment...';
      });

      // Initiate payment with FX converted amount
      final paymentService = ref.read(paymentServiceProvider);
      final result = await paymentService.initiatePayment(
        userId: userId,
        firstName: user?.firstName ?? 'User',
        lastName: user?.lastName ?? '',
        email: user?.email ?? 'user@example.com',
        phoneNumber: normalizedPhone,
        username: user?.username ?? 'user',
        amount: paymentAmount,
        orderDesc: 'Airtime purchase for $displayPhone - ${operatorData.name}: ${senderSymbol}${amount.toStringAsFixed(2)} (≈ ${paymentCurrency}${paymentAmount.toStringAsFixed(2)}) on ${DateTime.now().toString().split(' ')[0]}',
        topupParams: topupParams,
      );

      if (result.success) {
        await paymentService.storePaymentDisplayInfo(
          result.transactionId,
          topupAmount: amount,
          topupCurrency: senderCurrency,
          paymentAmount: paymentAmount,
          paymentCurrency: paymentCurrency,
        );
        setState(() {
          _statusMessage = 'Redirecting to payment page...';
          _paymentState = PaymentFlowState.awaitingCallback;
        });
        // Payment page will open in browser
        // App will detect when user returns via lifecycle observer
      } else {
        setState(() {
          _error = _sanitizePhoneError(result.message, country);
          _isProcessing = false;
          _statusMessage = '';
          _paymentState = PaymentFlowState.failed;
        });
      }
    } catch (e) {
      setState(() {
        _error = _sanitizePhoneError(
          e.toString().replaceAll('Exception: ', ''),
          country,
        );
        _isProcessing = false;
        _statusMessage = '';
        _paymentState = PaymentFlowState.failed;
      });
    }
  }

  Future<void> _creditAirtime() async {
    final wizardState = ref.read(airtimeWizardProvider);
    setState(() {
      _statusMessage = 'Crediting airtime...';
      _paymentState = PaymentFlowState.crediting;
    });

    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User ID not found.');
      }

      final paymentService = ref.read(paymentServiceProvider);
      final topupParams = await paymentService.getPendingTopup();

      if (topupParams == null) {
        throw Exception('Payment data not found. Please try again.');
      }

      final result = await paymentService.creditAirtime(
        userId: userId,
        params: topupParams,
      );

      if (result.success) {
        // Show success dialog
        if (mounted) {
          setState(() {
            _paymentState = PaymentFlowState.success;
          });
          _showSuccessDialog(result);
        }
        // Reset wizard state after navigation to receipt
        ref.read(airtimeWizardProvider.notifier).reset();
      } else {
        setState(() {
          final message = _sanitizePhoneError(result.message, wizardState.selectedCountry);
          _error = message;
          _isProcessing = false;
          _statusMessage = '';
          _paymentState = PaymentFlowState.failed;
        });
        if (mounted) {
          _showFailureReceipt(
            _sanitizePhoneError(result.message, wizardState.selectedCountry),
            transactionId: topupParams.payTransRef,
          );
        }
      }
    } catch (e) {
      final message = _sanitizePhoneError(
        e.toString().replaceAll('Exception: ', ''),
        wizardState.selectedCountry,
      );
      setState(() {
        _error = message;
        _isProcessing = false;
        _statusMessage = '';
        _paymentState = PaymentFlowState.failed;
      });
      if (mounted) {
        final reference = await _resolvePaymentReference();
        _showFailureReceipt(message, transactionId: reference);
      }
    }
  }

  String _normalizePhoneNumber(Country country, String rawPhone) {
    var phone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    final countryCode = _getCountryCode(country);

    if (phone.startsWith(countryCode)) {
      phone = phone.substring(countryCode.length);
    }

    if (!_countriesRequiringZero.contains(country.code) && phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    return '$countryCode$phone';
  }

  String _formatPhoneForDisplay(Country country, String rawPhone) {
    final normalized = _normalizePhoneNumber(country, rawPhone);
    final countryCode = _getCountryCode(country);
    final local = normalized.startsWith(countryCode)
        ? normalized.substring(countryCode.length)
        : normalized;
    return '+$countryCode $local';
  }

  String _sanitizePhoneError(String message, Country? country) {
    if (country == null) return message;
    final lower = message.toLowerCase();
    if (lower.contains('phone number') && lower.contains('country code')) {
      final countryCode = _getCountryCode(country);
      return 'That phone number doesn\'t match ${country.name}. Remove the leading 0 after $countryCode and try again.';
    }
    return message;
  }

  String _getCountryCode(Country country) {
    if (country.callingCodes != null && country.callingCodes!.isNotEmpty) {
      return country.callingCodes!.first.replaceFirst(RegExp(r'^\+'), '');
    }
    const codes = {
      'NG': '234',
      'GH': '233',
      'KE': '254',
      'ZA': '27',
    };
    return codes[country.code] ?? '234';
  }

  Widget _buildMomoStep(String number, String text, String? boldText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ', style: const TextStyle(fontSize: 13)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color),
                children: [
                  TextSpan(text: text),
                  if (boldText != null)
                    TextSpan(
                      text: boldText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(PaymentResult result) {
    final wizardState = ref.read(airtimeWizardProvider);
    final operatorData = wizardState.operatorData;
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    final amount = wizardState.selectedAmount;
    final fxRate = operatorData?.fx?['rate'] as double?;
    final fxCurrencyCode = operatorData?.fx?['currencyCode'] as String?;
    final paymentAmount = amount != null && fxRate != null ? (amount * fxRate) : amount ?? 0.0;
    final paymentCurrency = fxCurrencyCode ?? country?.currencyCode ?? 'GHS';
    final senderCurrency = operatorData?.senderCurrencyCode ?? 'USD';
    
    // Set flag before navigation to prevent redirect to select country
    setState(() {
      _isNavigatingToReceipt = true;
    });
    
    // Navigate to receipt screen with transaction details
    context.go('/payment/receipt', extra: {
      'isSuccess': true,
      'transactionType': 'GLOBALAIRTOPUP',
      'transactionId': result.transactionId,
      'amount': paymentAmount,
      'currency': paymentCurrency,
      'topupAmount': amount ?? 0.0,
      'topupCurrency': senderCurrency,
      'paymentAmount': paymentAmount,
      'paymentCurrency': paymentCurrency,
      'recipientNumber': phoneNumber ?? '',
      'operatorName': operatorData?.name ?? '',
      'countryName': country?.name ?? '',
      'bundleName': null,
      'timestamp': DateTime.now(),
    });
  }

  void _showFailureReceipt(String message, {String? transactionId}) {
    final wizardState = ref.read(airtimeWizardProvider);
    final operatorData = wizardState.operatorData;
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    final amount = wizardState.selectedAmount;
    final fxRate = operatorData?.fx?['rate'] as double?;
    final fxCurrencyCode = operatorData?.fx?['currencyCode'] as String?;
    final paymentAmount = amount != null && fxRate != null ? (amount * fxRate) : amount ?? 0.0;
    final paymentCurrency = fxCurrencyCode ?? country?.currencyCode ?? 'GHS';
    final senderCurrency = operatorData?.senderCurrencyCode ?? 'USD';

    // Set flag before navigation to prevent redirect to select country
    setState(() {
      _isNavigatingToReceipt = true;
    });

    context.go('/payment/receipt', extra: {
      'isSuccess': false,
      'transactionType': 'GLOBALAIRTOPUP',
      'transactionId': transactionId,
      'amount': paymentAmount,
      'currency': paymentCurrency,
      'topupAmount': amount ?? 0.0,
      'topupCurrency': senderCurrency,
      'paymentAmount': paymentAmount,
      'paymentCurrency': paymentCurrency,
      'recipientNumber': phoneNumber ?? '',
      'operatorName': operatorData?.name ?? '',
      'countryName': country?.name ?? '',
      'bundleName': null,
      'errorMessage': message,
      'timestamp': DateTime.now(),
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wizardState = ref.watch(airtimeWizardProvider);
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    final operatorData = wizardState.operatorData;
    final amount = wizardState.selectedAmount;

    // If navigating to receipt, show loading state (check this first)
    if (_isNavigatingToReceipt) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Redirect if missing required data
    if (country == null || phoneNumber == null || operatorData == null || amount == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/airtime/select-country'));
      return const SizedBox.shrink();
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressIndicator(context, 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review and buy airtime',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildConfirmationCard(
                      context,
                      country,
                      operatorData,
                      _formatPhoneForDisplay(country, phoneNumber),
                      amount,
                    ),
                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildStatusIndicator(context),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildError(context),
                    ],
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(context),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AppBackButton(
            onTap: () => context.pop(),
            enabled: !_isProcessing,
            backgroundColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.white,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Buy Airtime',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStep) {
    final steps = ['Country', 'Phone', 'Amount', 'Confirm'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: stepBefore < currentStep
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 2,
                  ),
                  boxShadow: isCurrent ? AppShadows.softGlow(AppColors.primary) : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIndex],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isCurrent
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildConfirmationCard(
    BuildContext context,
    Country country,
    AutodetectData operatorData,
    String phoneNumber,
    double amount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Airtime Purchase',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDetailItemWithFlag('Country', country.name, country),
          const Divider(height: AppSpacing.xl),
          _buildDetailItemWithLogo('Network', operatorData.name, operatorData, country),
          const Divider(height: AppSpacing.xl),
          _buildAmountDetail(operatorData, amount),
          const Divider(height: AppSpacing.xl),
          _buildDetailItem('Phone Number', phoneNumber, Icons.phone_rounded),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItemWithFlag(String label, String value, Country country) {
    return Row(
      children: [
        CountryFlagWidget(
          flagUrl: country.flag,
          countryCode: country.code,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItemWithLogo(String label, String value, AutodetectData operatorData, Country country) {
    return Row(
      children: [
        // Operator Logo or fallback icon
        operatorData.logoUrl != null && operatorData.logoUrl!.isNotEmpty
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: Colors.white,
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    operatorData.logoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to cell tower icon if logo fails
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(Icons.cell_tower_rounded, color: AppColors.primary, size: 20),
                      );
                    },
                  ),
                ),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.cell_tower_rounded, color: AppColors.primary, size: 20),
              ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shimmer(duration: 2.seconds, color: AppColors.primary.withOpacity(0.3));
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('PREVIOUS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _initiatePayment,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.payment_rounded),
              label: Text(_isProcessing ? 'PROCESSING...' : 'BUY AIRTIME'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDetail(AutodetectData operatorData, double amount) {
    final fxRate = operatorData.fx?['rate'] as double?;
    final fxCurrencyCode = operatorData.fx?['currencyCode'] as String?;
    final paymentAmount = fxRate != null ? (amount * fxRate) : amount;
    final paymentCurrency = fxCurrencyCode ?? 'GHS';
    final senderSymbol = operatorData.senderCurrencySymbol;
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Top-up: $senderSymbol${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (fxRate != null && fxCurrencyCode != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Payment: ${paymentCurrency}${paymentAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
