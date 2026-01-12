import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../data/models/api_models.dart';
import '../../../../presentation/providers/auth_provider.dart';

class ConfirmTransactionScreen extends ConsumerStatefulWidget {
  final String recipientPhone;
  final String recipientName;
  final double amount;
  final String note;

  const ConfirmTransactionScreen({
    super.key,
    required this.recipientPhone,
    required this.recipientName,
    required this.amount,
    required this.note,
  });

  @override
  ConsumerState<ConfirmTransactionScreen> createState() => _ConfirmTransactionScreenState();
}

class _ConfirmTransactionScreenState extends ConsumerState<ConfirmTransactionScreen> {
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'wallet';

  Future<void> _confirmTransaction() async {
    setState(() => _isProcessing = true);

    try {
      // Get user info
      final user = ref.read(currentUserProvider).valueOrNull;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare topup params for after-payment crediting
      final payTransRef = generatePaymentReference();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final topupParams = TopupParams(
        operatorId: 150, // MTN Ghana - TODO: get from operator selection
        amount: widget.amount,
        description: 'Airtime purchase for ${widget.recipientPhone}',
        recipientEmail: user.email ?? 'user@example.com',
        recipientNumber: widget.recipientPhone,
        recipientCountryCode: 'GH',
        senderNumber: user.phoneNumber ?? '',
        senderCountryCode: user.country ?? 'GH',
        payTransRef: payTransRef,
        transType: 'GLOBALAIRTOPUP',
        customerEmail: user.email ?? '',
        customIdentifier: 'reloadly-airtime $timestamp',
      );

      // Initiate payment
      final paymentService = ref.read(paymentServiceProvider);
      final result = await paymentService.initiatePayment(
        userId: user.id,
        firstName: user.firstName ?? 'User',
        lastName: user.lastName ?? '',
        email: user.email ?? 'user@example.com',
        phoneNumber: user.phoneNumber ?? '',
        username: user.username ?? 'user',
        amount: widget.amount,
        orderDesc: 'Airtime purchase for ${widget.recipientPhone} on ${DateTime.now().toString().split(' ')[0]}',
        topupParams: topupParams,
      );

      if (!mounted) return;

      if (result.success) {
        // Payment initiated successfully, browser will open
        // The deep link callback will handle the rest
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to dashboard while waiting for payment
        context.go('/dashboard');
      } else {
        // Payment initiation failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.recipientName.isNotEmpty ? widget.recipientName : widget.recipientPhone;
    final initials = widget.recipientName.isNotEmpty
        ? widget.recipientName.split(' ').map((e) => e[0]).take(2).join()
        : '#';

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // Header
          _buildHeader(context, displayName, initials),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Details
                  _buildTransactionDetails(context),
                  const SizedBox(height: AppSpacing.xl),
                  // Payment Method
                  _buildPaymentMethod(context),
                  const SizedBox(height: AppSpacing.xl),
                  // Fee Breakdown
                  _buildFeeBreakdown(context),
                ],
              ),
            ),
          ),
          // Bottom Action
          _buildBottomAction(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayName, String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Confirm Payment',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Recipient Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.lg,
                ),
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.recipientPhone,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Amount
              Text(
                'GHS ${widget.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTransactionDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailRow(label: 'Type', value: 'Airtime Top-up'),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Network', value: 'MTN Ghana'),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Phone', value: widget.recipientPhone),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PaymentMethodCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'LidaPay Wallet',
          subtitle: 'Balance: GHS 1,250.00',
          isSelected: _selectedPaymentMethod == 'wallet',
          onTap: () => setState(() => _selectedPaymentMethod = 'wallet'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PaymentMethodCard(
          icon: Icons.credit_card_rounded,
          title: 'Credit/Debit Card',
          subtitle: '**** **** **** 4589',
          isSelected: _selectedPaymentMethod == 'card',
          onTap: () => setState(() => _selectedPaymentMethod = 'card'),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildFeeBreakdown(BuildContext context) {
    final fee = widget.amount * 0.01; // 1% fee
    final total = widget.amount + fee;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Amount', value: 'GHS ${widget.amount.toStringAsFixed(2)}'),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(label: 'Service Fee', value: 'GHS ${fee.toStringAsFixed(2)}'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                'GHS ${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPrimary,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.glow(AppColors.brandPrimary, opacity: 0.3),
            ),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirmTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Confirm & Pay',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.lightTextSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppShadows.glow(AppColors.brandPrimary, opacity: 0.1) : AppShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.brandPrimary.withOpacity(0.1)
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.brandPrimary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTextTertiary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.brandPrimary : AppColors.lightBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
