import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/payment_service.dart';

class PaymentCallbackScreen extends ConsumerStatefulWidget {
  final String status;
  final String? token;
  final String? orderId;

  const PaymentCallbackScreen({
    super.key,
    required this.status,
    this.token,
    this.orderId,
  });

  @override
  ConsumerState<PaymentCallbackScreen> createState() => _PaymentCallbackScreenState();
}

class _PaymentCallbackScreenState extends ConsumerState<PaymentCallbackScreen> {
  bool _isProcessing = true;
  String _message = 'Processing your payment...';
  bool _isSuccess = false;
  String? _transactionId;
  PaymentResult? _paymentResult;

  @override
  void initState() {
    super.initState();
    _processPaymentCallback();
  }

  Future<void> _processPaymentCallback() async {
    final paymentService = ref.read(paymentServiceProvider);

    setState(() {
      _message = 'Verifying payment status...';
    });

    final result = await paymentService.handlePaymentCallback(
      status: widget.status,
      token: widget.token,
      orderId: widget.orderId,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isSuccess = result.success;
        _message = result.message;
        _transactionId = result.transactionId;
        _paymentResult = result;
      });

      // Navigate to receipt screen after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _navigateToReceipt();
        }
      });
    }
  }

  Future<void> _navigateToReceipt() async {
    // Get pending topup params for receipt details
    final pendingPayment = ref.read(pendingPaymentProvider);
    final paymentService = ref.read(paymentServiceProvider);
    final displayInfo = await paymentService.getPaymentDisplayInfo(_transactionId ?? pendingPayment?.payTransRef);
    
    // Extract operator name and bundle name from payment result data if available
    String? operatorName;
    String? bundleName;
    if (_paymentResult?.data != null && _isSuccess) {
      final data = _paymentResult!.data as dynamic;
      operatorName = data['operatorName'] as String?;
      bundleName = data['bundleName'] as String? ?? pendingPayment?.description;
    }
    
    context.go('/payment/receipt', extra: {
      'isSuccess': _isSuccess,
      'transactionType': pendingPayment?.transType ?? 'AIRTIME',
      'transactionId': _transactionId,
      'amount': displayInfo?.paymentAmount ?? pendingPayment?.amount ?? 0.0,
      'currency': displayInfo?.paymentCurrency ?? 'GHS',
      'topupAmount': displayInfo?.topupAmount ?? pendingPayment?.amount,
      'topupCurrency': displayInfo?.topupCurrency,
      'paymentAmount': displayInfo?.paymentAmount,
      'paymentCurrency': displayInfo?.paymentCurrency,
      'recipientNumber': pendingPayment?.recipientNumber ?? '',
      'operatorName': operatorName,
      'countryName': 'Ghana', // Default country
      'bundleName': bundleName,
      'errorMessage': _isSuccess ? null : _message,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _isProcessing
              ? AppColors.heroGradient
              : (_isSuccess
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.success,
                        AppColors.success.withOpacity(0.7),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.error,
                        AppColors.error.withOpacity(0.7),
                      ],
                    )),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildMessage(),
                  if (_transactionId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildTransactionId(),
                  ],
                  if (!_isProcessing) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _buildActionButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_isProcessing) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack);
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        _isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
        size: 80,
        color: _isSuccess ? AppColors.success : AppColors.error,
      ),
    )
        .animate()
        .scale(duration: 500.ms, curve: Curves.easeOutBack)
        .then()
        .shake(duration: 300.ms, hz: 3);
  }

  Widget _buildMessage() {
    return Column(
      children: [
        Text(
          _isProcessing
              ? 'Processing...'
              : (_isSuccess ? 'Success!' : 'Payment Failed'),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.md),
        Text(
          _message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildTransactionId() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'ID: $_transactionId',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      onPressed: () => context.go('/dashboard'),
      icon: const Icon(Icons.home_rounded),
      label: const Text('Go to Dashboard'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _isSuccess ? AppColors.success : AppColors.error,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0);
  }
}

