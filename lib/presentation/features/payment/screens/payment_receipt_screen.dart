import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentReceiptScreen extends ConsumerStatefulWidget {
  final bool isSuccess;
  final String transactionType; // 'AIRTIME' or 'DATA'
  final String? transactionId;
  final double amount;
  final String currency;
  final String recipientNumber;
  final String? operatorName;
  final String? countryName;
  final String? bundleName; // For data bundles
  final String? errorMessage;
  final DateTime? timestamp;

  const PaymentReceiptScreen({
    super.key,
    required this.isSuccess,
    required this.transactionType,
    this.transactionId,
    required this.amount,
    this.currency = 'GHS',
    required this.recipientNumber,
    this.operatorName,
    this.countryName,
    this.bundleName,
    this.errorMessage,
    this.timestamp,
  });

  @override
  ConsumerState<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends ConsumerState<PaymentReceiptScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    if (widget.isSuccess) {
      _confettiController.forward();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get _transactionTypeLabel {
    switch (widget.transactionType.toUpperCase()) {
      case 'AIRTIME':
      case 'GLOBALAIRTOPUP':
        return 'Airtime Top-up';
      case 'DATA':
      case 'GLOBALDATATOPUP':
        return 'Data Bundle';
      default:
        return widget.transactionType;
    }
  }

  IconData get _transactionIcon {
    switch (widget.transactionType.toUpperCase()) {
      case 'AIRTIME':
      case 'GLOBALAIRTOPUP':
        return Icons.phone_android_rounded;
      case 'DATA':
      case 'GLOBALDATATOPUP':
        return Icons.wifi_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timestamp = widget.timestamp ?? DateTime.now();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Receipt Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    // Status Card
                    _buildStatusCard(context, isDark),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Receipt Card
                    _buildReceiptCard(context, isDark, timestamp),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Action Buttons
                    _buildActionButtons(context, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/dashboard'),
          ),
          const Expanded(
            child: Text(
              'Transaction Receipt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareReceipt,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: widget.isSuccess
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: (widget.isSuccess ? AppColors.success : AppColors.error)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              widget.isSuccess 
                  ? Icons.check_circle_rounded 
                  : Icons.error_rounded,
              size: 50,
              color: widget.isSuccess ? AppColors.success : AppColors.error,
            ),
          )
              .animate()
              .scale(
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .then()
              .shimmer(duration: 1000.ms),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Status Text
          Text(
            widget.isSuccess ? 'Transaction Successful!' : 'Transaction Failed',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Amount
          Text(
            '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Transaction Type
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _transactionIcon,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _transactionTypeLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildReceiptCard(BuildContext context, bool isDark, DateTime timestamp) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Receipt Header with dashed line
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _transactionIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _transactionTypeLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark 
                                  ? AppColors.darkTextMuted 
                                  : AppColors.lightTextMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Receipt Details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _ReceiptRow(
                  label: 'Recipient',
                  value: widget.recipientNumber,
                  isDark: isDark,
                ),
                if (widget.operatorName != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ReceiptRow(
                    label: 'Operator',
                    value: widget.operatorName!,
                    isDark: isDark,
                  ),
                ],
                if (widget.countryName != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ReceiptRow(
                    label: 'Country',
                    value: widget.countryName!,
                    isDark: isDark,
                  ),
                ],
                if (widget.bundleName != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ReceiptRow(
                    label: 'Bundle',
                    value: widget.bundleName!,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _ReceiptRow(
                  label: 'Amount',
                  value: '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                  isDark: isDark,
                  isHighlighted: true,
                ),
                if (widget.transactionId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  _ReceiptRow(
                    label: 'Transaction ID',
                    value: widget.transactionId!,
                    isDark: isDark,
                    isCopyable: true,
                  ),
                ],
                if (!widget.isSuccess && widget.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Receipt Footer with dashed border effect
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkBackground.withOpacity(0.5) 
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xl),
                bottomRight: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: widget.isSuccess ? AppColors.success : AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  widget.isSuccess 
                      ? 'Verified by LidaPay' 
                      : 'Transaction not completed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.isSuccess 
                            ? AppColors.success 
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Primary Action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.home_rounded),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms),
        
        const SizedBox(height: AppSpacing.md),
        
        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareReceipt,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to transaction history
                  context.go('/transactions');
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms),
        
        if (!widget.isSuccess) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                // Retry - go back to appropriate screen
                if (widget.transactionType.toUpperCase().contains('AIRTIME')) {
                  context.go('/airtime');
                } else {
                  context.go('/data');
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ).animate().fadeIn(delay: 600.ms),
        ],
      ],
    );
  }

  void _shareReceipt() {
    final timestamp = widget.timestamp ?? DateTime.now();
    
    final receiptText = '''
🧾 LidaPay Transaction Receipt

${widget.isSuccess ? '✅ Transaction Successful' : '❌ Transaction Failed'}

📱 Type: $_transactionTypeLabel
💰 Amount: ${widget.currency} ${widget.amount.toStringAsFixed(2)}
📞 Recipient: ${widget.recipientNumber}
${widget.operatorName != null ? '🏢 Operator: ${widget.operatorName}' : ''}
${widget.countryName != null ? '🌍 Country: ${widget.countryName}' : ''}
${widget.bundleName != null ? '📦 Bundle: ${widget.bundleName}' : ''}
📅 Date: ${DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp)}
${widget.transactionId != null ? '🔖 Transaction ID: ${widget.transactionId}' : ''}

Powered by LidaPay
''';

    Share.share(receiptText, subject: 'LidaPay Transaction Receipt');
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isHighlighted;
  final bool isCopyable;

  const _ReceiptRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.isHighlighted = false,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                        color: isHighlighted 
                            ? (isDark ? Colors.white : AppColors.lightText)
                            : null,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
