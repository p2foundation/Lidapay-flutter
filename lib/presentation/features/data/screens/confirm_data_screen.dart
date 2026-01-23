import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../data/models/api_models.dart';
import '../../../../core/utils/ghana_network_codes.dart';
import '../../../providers/data_wizard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/country_flag_widget.dart';

class ConfirmDataScreen extends ConsumerStatefulWidget {
  const ConfirmDataScreen({super.key});

  @override
  ConsumerState<ConfirmDataScreen> createState() => _ConfirmDataScreenState();
}

class _ConfirmDataScreenState extends ConsumerState<ConfirmDataScreen> with WidgetsBindingObserver {
  bool _isProcessing = false;
  String? _error;
  String _statusMessage = '';
  PaymentFlowState _paymentState = PaymentFlowState.idle;
  bool _isNavigatingToReceipt = false;

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

  String normalizeLocalNumber(String? fullNumber, Country country) {
    if (fullNumber == null || fullNumber.isEmpty) return '';
    final digitsOnly = fullNumber.replaceAll(RegExp(r'[^\d]'), '');
    final fallbackCallingCodes = {
      'NG': '234',
      'GH': '233',
      'KE': '254',
      'ZA': '27',
      'UG': '256',
      'TZ': '255',
      'ET': '251',
      'RW': '250',
      'ZM': '260',
      'ZW': '263',
    };
    final callingCode = (country.callingCodes?.isNotEmpty == true)
        ? country.callingCodes!.first.replaceFirst(RegExp(r'^\+'), '')
        : (fallbackCallingCodes[country.code] ?? '234');
    var localNumber = digitsOnly;
    if (localNumber.startsWith(callingCode)) {
      localNumber = localNumber.substring(callingCode.length);
    }
    if (country.code == 'GH' && localNumber.isNotEmpty && !localNumber.startsWith('0')) {
      localNumber = '0$localNumber';
    }
    return localNumber;
  }

  Future<void> _checkPaymentStatus() async {
    // When user returns from payment page, ask if they completed payment
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

    // Enhanced: Try query status 3 times with better delay
    const maxAttempts = 3;
    PaymentResult? lastResult;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Verifying payment... ($attempt/$maxAttempts)';
      });

      final result = await paymentService.queryPaymentStatus(
        token,
        maxRetries: 1, // Each query attempt has 1 retry
        retryDelaySeconds: 2, // Shorter delay between retries
      );
      if (!mounted) return;

      // Check if payment is COMPLETED or SUCCESSFUL
      if (result.success) {
        AppLogger.info('✅ Data payment verified successfully on attempt $attempt', 'ConfirmDataScreen');
        await _creditData();
        return;
      }

      lastResult = result;

      // If not last attempt, wait longer before trying again
      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 3));
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
    final wizardState = ref.read(dataWizardProvider);
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    final selectedOperator = wizardState.selectedOperator;
    final selectedBundle = wizardState.selectedBundle;
    final user = ref.read(currentUserProvider).valueOrNull;
    final selectedGhanaNetwork = wizardState.selectedGhanaNetworkCode;

    if (country == null || phoneNumber == null || selectedOperator == null || selectedBundle == null) {
      setState(() {
        _error = 'Missing required information. Please start over.';
      });
      return;
    }

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

      // Use Prymo only when a specific Ghana network is selected
      if (country.code == 'GH' &&
          AppConstants.usePrymoForGhanaData &&
          selectedGhanaNetwork != null &&
          selectedGhanaNetwork != GhanaNetworkCodes.unknown) {
        await _initiateGhanaPayment(userId, user, country, selectedOperator, selectedBundle, phoneNumber);
        return;
      }

      // Continue with Reloadly/ExpressPay flow for other countries
      await _initiateInternationalPayment(userId, user, country, selectedOperator, selectedBundle, phoneNumber);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
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

  Future<void> _initiateGhanaPayment(
    String userId,
    User? user,
    Country country,
    DataOperator selectedOperator,
    DataBundle selectedBundle,
    String phoneNumber,
  ) async {
    final network = GhanaNetworkCodes.fromOperatorId(selectedOperator.operatorId);

    // Generate unique reference
    final payTransRef = generatePaymentReference();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Prepare topup params for after-payment crediting
    final bundleLabel = selectedBundle.description.isNotEmpty
        ? selectedBundle.description
        : selectedBundle.name;
    final localRecipientNumber = normalizeLocalNumber(phoneNumber, country);
    final localSenderNumber = normalizeLocalNumber(user?.phoneNumber, country);

    final topupParams = TopupParams(
      operatorId: selectedOperator.operatorId,
      amount: selectedBundle.amount,
      description: 'Data bundle: $bundleLabel for $phoneNumber (${selectedOperator.name})',
      recipientEmail: user?.email ?? 'user@example.com',
      recipientNumber: localRecipientNumber.isNotEmpty ? localRecipientNumber : phoneNumber,
      recipientCountryCode: country.code,
      senderNumber: localSenderNumber.isNotEmpty ? localSenderNumber : (user?.phoneNumber ?? ''),
      senderCountryCode: country.code,
      payTransRef: payTransRef,
      transType: 'PRYMODATA', // Use Prymo transaction type
      customerEmail: user?.email ?? '',
      customIdentifier: 'prymo-data $timestamp',
      bundleId: selectedBundle.id.toString(), // Keep as string for compatibility
      dataCode: selectedBundle.planId, // Use planId for Ghana data bundles
    );

    setState(() {
      _statusMessage = 'Initiating payment...';
    });

    // Initiate payment with ExpressPay (still needed for Ghana)
    final paymentService = ref.read(paymentServiceProvider);
    final result = await paymentService.initiatePayment(
      userId: userId,
      firstName: user?.firstName ?? 'User',
      lastName: user?.lastName ?? '',
      email: user?.email ?? 'user@example.com',
      phoneNumber: phoneNumber,
      username: user?.username ?? 'user',
      amount: selectedBundle.amount, // Use amount directly for Ghana (GHS)
      orderDesc: 'Data purchase: ${selectedBundle.name} for $phoneNumber - GHS${selectedBundle.amount.toStringAsFixed(2)} on ${DateTime.now().toString().split(' ')[0]}',
      topupParams: topupParams,
    );

    if (result.success) {
      await paymentService.storePaymentDisplayInfo(
        result.transactionId,
        topupAmount: selectedBundle.amount,
        topupCurrency: 'GHS',
        paymentAmount: selectedBundle.amount,
        paymentCurrency: 'GHS',
      );
      setState(() {
        _statusMessage = 'Redirecting to payment page...';
        _paymentState = PaymentFlowState.awaitingCallback;
      });
    } else {
      setState(() {
        _error = result.message;
        _isProcessing = false;
        _statusMessage = '';
        _paymentState = PaymentFlowState.failed;
      });
      if (mounted) {
        _showFailureReceipt(result.message, transactionId: topupParams.payTransRef);
      }
    }
  }

  Future<void> _initiateInternationalPayment(
    String userId,
    User? user,
    Country country,
    DataOperator selectedOperator,
    DataBundle selectedBundle,
    String phoneNumber,
  ) async {
    // Calculate FX converted amount for payment
    final fxRate = selectedOperator.fx?['rate'] as double?;
    final fxCurrencyCode = selectedOperator.fx?['currencyCode'] as String?;
    final paymentAmount = fxRate != null ? (selectedBundle.amount * fxRate) : selectedBundle.amount;
    final paymentCurrency = fxCurrencyCode ?? 'GHS';

    // Generate unique reference
    final payTransRef = generatePaymentReference();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Prepare topup params for after-payment crediting
    final bundleLabel = selectedBundle.description.isNotEmpty
        ? selectedBundle.description
        : selectedBundle.name;
    final localRecipientNumber = normalizeLocalNumber(phoneNumber, country);
    final localSenderNumber = normalizeLocalNumber(user?.phoneNumber, country);

    final topupParams = TopupParams(
      operatorId: selectedOperator.operatorId,
      amount: selectedBundle.amount,
      description: 'Data bundle: $bundleLabel for $phoneNumber (${selectedOperator.name})',
      recipientEmail: user?.email ?? 'user@example.com',
      recipientNumber: localRecipientNumber.isNotEmpty ? localRecipientNumber : phoneNumber,
      recipientCountryCode: country.code,
      senderNumber: localSenderNumber.isNotEmpty ? localSenderNumber : (user?.phoneNumber ?? ''),
      senderCountryCode: country.code,
      payTransRef: payTransRef,
      transType: 'GLOBALDATATOPUP',
      customerEmail: user?.email ?? '',
      customIdentifier: 'global-data $timestamp',
      bundleId: selectedBundle.id.toString(),
      dataCode: selectedBundle.planId, // Include planId for consistency
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
      phoneNumber: phoneNumber,
      username: user?.username ?? 'user',
      amount: paymentAmount,
      orderDesc: 'Data purchase: ${selectedBundle.name} for $phoneNumber - ${selectedBundle.currency}${selectedBundle.amount.toStringAsFixed(2)} (≈ ${paymentCurrency}${paymentAmount.toStringAsFixed(2)}) on ${DateTime.now().toString().split(' ')[0]}',
      topupParams: topupParams,
    );

    if (result.success) {
      await paymentService.storePaymentDisplayInfo(
        result.transactionId,
        topupAmount: selectedBundle.amount,
        topupCurrency: selectedBundle.currency,
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
        _error = result.message;
        _isProcessing = false;
        _statusMessage = '';
        _paymentState = PaymentFlowState.failed;
      });
      if (mounted) {
        _showFailureReceipt(result.message, transactionId: topupParams.payTransRef);
      }
    }
  }

  Future<void> _creditData() async {
    setState(() {
      _statusMessage = 'Crediting data bundle...';
      _paymentState = PaymentFlowState.crediting;
    });

    try {
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User ID not found.');
      }

      final wizardState = ref.read(dataWizardProvider);
      final selectedBundle = wizardState.selectedBundle;
      final selectedOperator = wizardState.selectedOperator;
      final country = wizardState.selectedCountry;
      final phoneNumber = wizardState.phoneNumber;
      final fxRate = selectedOperator?.fx?['rate'] as double?;
      final fxCurrencyCode = selectedOperator?.fx?['currencyCode'] as String?;
      final paymentAmount = selectedBundle != null && fxRate != null
          ? (selectedBundle.amount * fxRate)
          : selectedBundle?.amount ?? 0.0;
      final paymentCurrency = fxCurrencyCode ?? country?.currencyCode ?? 'GHS';

      final paymentService = ref.read(paymentServiceProvider);
      final topupParams = await paymentService.getPendingTopup();

      if (topupParams == null) {
        throw Exception('Payment data not found. Please try again.');
      }

      final result = await paymentService.creditData(
        userId: userId,
        params: topupParams,
      );

      if (result.success) {
        if (mounted) {
          setState(() {
            _paymentState = PaymentFlowState.success;
          });
          context.go('/payment/receipt', extra: {
            'isSuccess': true,
            'transactionType': 'GLOBALDATATOPUP',
            'transactionId': result.transactionId,
            'amount': paymentAmount,
            'currency': paymentCurrency,
            'topupAmount': selectedBundle?.amount ?? 0.0,
            'topupCurrency': selectedBundle?.currency ?? 'USD',
            'paymentAmount': paymentAmount,
            'paymentCurrency': paymentCurrency,
            'recipientNumber': phoneNumber ?? '',
            'operatorName': selectedOperator?.name ?? '',
            'countryName': country?.name ?? '',
            'bundleName': selectedBundle?.description ?? selectedBundle?.name ?? '',
            'timestamp': DateTime.now(),
          });
        }
        ref.read(dataWizardProvider.notifier).reset();
      } else {
        setState(() {
          _error = result.message;
          _isProcessing = false;
          _statusMessage = '';
          _paymentState = PaymentFlowState.failed;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isProcessing = false;
        _statusMessage = '';
        _paymentState = PaymentFlowState.failed;
      });
    }
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
    final wizardState = ref.read(dataWizardProvider);
    final selectedBundle = wizardState.selectedBundle;
    final selectedOperator = wizardState.selectedOperator;
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    
    // Check if this is Ghana transaction
    final isGhana = country?.code == 'GH';
    
    final fxRate = selectedOperator?.fx?['rate'] as double?;
    final fxCurrencyCode = selectedOperator?.fx?['currencyCode'] as String?;
    final paymentAmount = selectedBundle != null && fxRate != null
        ? (selectedBundle.amount * fxRate)
        : selectedBundle?.amount ?? 0.0;
    final paymentCurrency = isGhana ? 'GHS' : (fxCurrencyCode ?? country?.currencyCode ?? 'GHS');
    final topupCurrency = isGhana ? 'GHS' : (selectedBundle?.currency ?? 'USD');
    
    // Set flag before navigation to prevent redirect to select country
    setState(() {
      _isNavigatingToReceipt = true;
    });
    
    // Navigate to receipt screen with transaction details
    context.go('/payment/receipt', extra: {
      'isSuccess': true,
      'transactionType': isGhana ? 'PRYMODATA' : 'GLOBALDATATOPUP',
      'transactionId': result.transactionId,
      'amount': paymentAmount,
      'currency': paymentCurrency,
      'topupAmount': selectedBundle?.amount ?? 0.0,
      'topupCurrency': topupCurrency,
      'paymentAmount': paymentAmount,
      'paymentCurrency': paymentCurrency,
      'recipientNumber': phoneNumber ?? '',
      'operatorName': selectedOperator?.name ?? '',
      'countryName': country?.name ?? '',
      'bundleName': selectedBundle?.description ?? selectedBundle?.name ?? '',
      'timestamp': DateTime.now(),
    });
  }

  void _showFailureReceipt(String message, {String? transactionId}) {
    final wizardState = ref.read(dataWizardProvider);
    final selectedBundle = wizardState.selectedBundle;
    final selectedOperator = wizardState.selectedOperator;
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    
    // Check if this is Ghana transaction
    final isGhana = country?.code == 'GH';
    
    final fxRate = selectedOperator?.fx?['rate'] as double?;
    final fxCurrencyCode = selectedOperator?.fx?['currencyCode'] as String?;
    final paymentAmount = selectedBundle != null && fxRate != null
        ? (selectedBundle.amount * fxRate)
        : selectedBundle?.amount ?? 0.0;
    final paymentCurrency = isGhana ? 'GHS' : (fxCurrencyCode ?? country?.currencyCode ?? 'GHS');
    final topupCurrency = isGhana ? 'GHS' : (selectedBundle?.currency ?? 'USD');

    // Set flag before navigation to prevent redirect to select country
    setState(() {
      _isNavigatingToReceipt = true;
    });

    context.go('/payment/receipt', extra: {
      'isSuccess': false,
      'transactionType': isGhana ? 'PRYMODATA' : 'GLOBALDATATOPUP',
      'transactionId': transactionId,
      'amount': paymentAmount,
      'currency': paymentCurrency,
      'topupAmount': selectedBundle?.amount ?? 0.0,
      'topupCurrency': topupCurrency,
      'paymentAmount': paymentAmount,
      'paymentCurrency': paymentCurrency,
      'recipientNumber': phoneNumber ?? '',
      'operatorName': selectedOperator?.name ?? '',
      'countryName': country?.name ?? '',
      'bundleName': selectedBundle?.description ?? selectedBundle?.name ?? '',
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
    final wizardState = ref.watch(dataWizardProvider);
    final country = wizardState.selectedCountry;
    final phoneNumber = wizardState.phoneNumber;
    final selectedOperator = wizardState.selectedOperator;
    final selectedBundle = wizardState.selectedBundle;

    // If navigating to receipt, show loading state (check this first)
    if (_isNavigatingToReceipt) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Redirect if missing required data
    if (country == null || phoneNumber == null || selectedOperator == null || selectedBundle == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/data/select-country'));
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
                      'Review and buy data',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildConfirmationCard(context, country, phoneNumber, selectedOperator, selectedBundle),
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
              'Buy Data',
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
    final steps = ['Country', 'Phone', 'Bundle', 'Confirm'];
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
    String phoneNumber,
    DataOperator operator,
    DataBundle bundle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGhana = country.code == 'GH';
    
    // Extract bundle info from metadata for Ghana bundles
    String bundleName = bundle.name; // This is now the user-friendly name
    String bundleVolume = bundle.description;
    String bundleValidity = bundle.validity ?? 'N/A';
    
    if (isGhana && bundle.metadata != null) {
      final metadata = bundle.metadata as Map<String, dynamic>;
      // For Ghana bundles, the volume is stored in metadata
      if (metadata['volume'] != null) {
        bundleVolume = metadata['volume'];
      }
      bundleValidity = metadata['validity'] ?? 'No expiry';
    }

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
                child: Icon(Icons.wifi_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Data Bundle Purchase',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDetailItemWithFlag('Country', country.name, country),
          const Divider(height: AppSpacing.xl),
          _buildDetailItemWithLogo('Network', operator.name, operator),
          const Divider(height: AppSpacing.xl),
          _buildAmountDetail(operator, bundle),
          const Divider(height: AppSpacing.xl),
          _buildDetailItem('Phone Number', phoneNumber, Icons.phone_rounded),
          const Divider(height: AppSpacing.xl),
          _buildDetailItem('Data Bundle', bundleName, Icons.data_usage_rounded),
          const Divider(height: AppSpacing.xl),
          if (bundleVolume.isNotEmpty) ...[
            _buildDetailItem('Data Volume', bundleVolume, Icons.storage_rounded),
            const Divider(height: AppSpacing.xl),
          ],
          _buildDetailItem('Validity', bundleValidity, Icons.schedule_rounded),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAmountDetail(DataOperator operator, DataBundle bundle) {
    final wizardState = ref.read(dataWizardProvider);
    final country = wizardState.selectedCountry;
    
    // Check if this is Ghana transaction
    final isGhana = country?.code == 'GH';
    
    final fxRate = operator.fx?['rate'] as double?;
    final fxCurrencyCode = operator.fx?['currencyCode'] as String?;
    final paymentAmount = fxRate != null ? (bundle.amount * fxRate) : bundle.amount;
    final paymentCurrency = fxCurrencyCode ?? country?.currencyCode ?? 'GHS';
    
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
                'Total Amount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                isGhana 
                    ? 'Bundle: GHS${bundle.amount.toStringAsFixed(2)}'
                    : 'Bundle: ${bundle.currency}${bundle.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (!isGhana && fxRate != null && fxCurrencyCode != null) ...[
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

  Widget _buildDetailItemWithLogo(String label, String value, DataOperator operator) {
    return Row(
      children: [
        // Operator Logo or fallback icon
        operator.logoUrl != null && operator.logoUrl!.isNotEmpty
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
                    operator.logoUrl!,
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
              label: Text(_isProcessing ? 'PROCESSING...' : 'BUY DATA'),
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
}
