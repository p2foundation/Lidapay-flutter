import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../data/models/api_models.dart';
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
      await _creditData();
    } else {
      setState(() {
        _isProcessing = false;
        _paymentState = PaymentFlowState.cancelled;
        _statusMessage = '';
        _error = 'Payment was cancelled.';
      });
      ref.read(paymentServiceProvider).clearPendingPayment();
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

      // Calculate FX converted amount for payment
      final fxRate = selectedOperator.fx?['rate'] as double?;
      final fxCurrencyCode = selectedOperator.fx?['currencyCode'] as String?;
      final paymentAmount = fxRate != null ? (selectedBundle.amount * fxRate) : selectedBundle.amount;
      final paymentCurrency = fxCurrencyCode ?? 'GHS';

      // Generate unique reference
      final payTransRef = generatePaymentReference();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Prepare topup params for after-payment crediting
      final topupParams = TopupParams(
        operatorId: selectedOperator.operatorId,
        amount: selectedBundle.amount,
        description: 'Data bundle: ${selectedBundle.name} for $phoneNumber (${selectedOperator.name})',
        recipientEmail: user?.email ?? 'user@example.com',
        recipientNumber: phoneNumber,
        recipientCountryCode: country.code,
        senderNumber: user?.phoneNumber ?? '',
        senderCountryCode: user?.country ?? 'GH',
        payTransRef: payTransRef,
        transType: 'GLOBALDATATOPUP',
        customerEmail: user?.email ?? '',
        customIdentifier: 'reloadly-data $timestamp',
        bundleId: selectedBundle.id,
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
        // Reset wizard state
        ref.read(dataWizardProvider.notifier).reset();

        // Show success dialog
        if (mounted) {
          setState(() {
            _paymentState = PaymentFlowState.success;
          });
          _showSuccessDialog(result);
        }
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
    
    // Navigate to receipt screen with transaction details
    context.go('/payment/receipt', extra: {
      'isSuccess': true,
      'transactionType': 'GLOBALDATATOPUP',
      'transactionId': result.transactionId,
      'amount': selectedBundle?.amount ?? 0.0,
      'currency': country?.currencyCode ?? 'GHS',
      'recipientNumber': phoneNumber ?? '',
      'operatorName': selectedOperator?.name ?? '',
      'countryName': country?.name ?? '',
      'bundleName': selectedBundle?.name ?? '',
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
                    _buildConfirmationCard(context, country, selectedOperator, phoneNumber, selectedBundle),
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
          GestureDetector(
            onTap: _isProcessing ? null : () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
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
    DataOperator operator,
    String phoneNumber,
    DataBundle bundle,
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
          _buildDetailItem('Data Bundle', bundle.description, Icons.data_usage_rounded),
          const Divider(height: AppSpacing.xl),
          _buildDetailItem('Validity', bundle.validity ?? 'N/A', Icons.schedule_rounded),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildAmountDetail(DataOperator operator, DataBundle bundle) {
    final fxRate = operator.fx?['rate'] as double?;
    final fxCurrencyCode = operator.fx?['currencyCode'] as String?;
    final paymentAmount = fxRate != null ? (bundle.amount * fxRate) : bundle.amount;
    final paymentCurrency = fxCurrencyCode ?? 'GHS';
    
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
                'Bundle: ${bundle.currency}${bundle.amount.toStringAsFixed(2)}',
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
