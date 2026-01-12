import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/api_models.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _shareTransaction() {
    final transaction = widget.transaction;
    final dateFormatter = DateFormat('MMM dd, yyyy • hh:mm a');
    final formattedDate = dateFormatter.format(transaction.createdAt);
    
    final transType = (transaction.transType ?? transaction.type ?? 'Transaction').toUpperCase();
    final status = transaction.status.toUpperCase();
    final currency = transaction.currency;
    final amount = transaction.amount.abs().toStringAsFixed(2);
    
    String transactionTypeLabel;
    switch (transType) {
      case 'GLOBALAIRTOPUP':
        transactionTypeLabel = 'Airtime Top-up';
        break;
      case 'GLOBALDATATOPUP':
        transactionTypeLabel = 'Data Bundle';
        break;
      case 'MOMO':
        transactionTypeLabel = 'Mobile Money';
        break;
      default:
        transactionTypeLabel = transType;
    }
    
    final shareText = '''
🧾 LIDAPAY TRANSACTION RECEIPT

📋 Transaction Type: $transactionTypeLabel
🆔 Transaction ID: ${transaction.transId ?? transaction.id}
📱 Recipient: ${transaction.recipientPhone ?? 'N/A'}
💰 Amount: $currency $amount
📊 Status: $status
📅 Date: $formattedDate
${transaction.note != null ? '\n📝 Note: ${transaction.note}' : ''}
---
Powered by Lidapay
''';

    Share.share(shareText, subject: 'Lidapay Transaction Receipt');
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final status = transaction.status.toLowerCase();
    final isExpense = transaction.amount < 0;
    final type = (transaction.transType ?? transaction.type ?? '').toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          _buildHeader(context, transaction, status),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Status Card
                  _buildStatusCard(context, transaction, status),
                  const SizedBox(height: AppSpacing.lg),
                  // Amount Card
                  _buildAmountCard(context, transaction, isExpense),
                  const SizedBox(height: AppSpacing.lg),
                  // Transaction Details
                  _buildDetailsSection(context, transaction),
                  const SizedBox(height: AppSpacing.lg),
                  // Payment Information
                  if (transaction.paymentMethod != null)
                    _buildPaymentSection(context, transaction),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Transaction transaction, String status) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    onPressed: _shareTransaction,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Transaction ID
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      transaction.transId ?? transaction.id,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatusCard(BuildContext context, Transaction transaction, String status) {
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextMuted,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildAmountCard(BuildContext context, Transaction transaction, bool isExpense) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        children: [
          Text(
            isExpense ? 'Amount Sent' : 'Amount Received',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${isExpense ? '-' : '+'}${transaction.currency} ${transaction.amount.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildDetailsSection(BuildContext context, Transaction transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Transaction Type',
            value: transaction.transType ?? transaction.type ?? 'N/A',
          ),
          const Divider(height: AppSpacing.xl),
          if (transaction.recipientName != null)
            _DetailRow(
              label: 'Recipient',
              value: transaction.recipientName!,
            ),
          if (transaction.recipientName != null) const Divider(height: AppSpacing.xl),
          if (transaction.recipientPhone != null)
            _DetailRow(
              label: 'Phone Number',
              value: transaction.recipientPhone!,
            ),
          if (transaction.recipientPhone != null) const Divider(height: AppSpacing.xl),
          _DetailRow(
            label: 'Date & Time',
            value: DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
          ),
          const Divider(height: AppSpacing.xl),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            _DetailRow(
              label: 'Note',
              value: transaction.note!,
            ),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            const Divider(height: AppSpacing.xl),
          if (transaction.retailer != null)
            _DetailRow(
              label: 'Retailer',
              value: transaction.retailer!,
            ),
          if (transaction.retailer != null) const Divider(height: AppSpacing.xl),
          if (transaction.transId != null)
            _DetailRow(
              label: 'Transaction ID',
              value: transaction.transId!,
              isCopyable: true,
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPaymentSection(BuildContext context, Transaction transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            label: 'Payment Method',
            value: transaction.paymentMethod ?? 'N/A',
          ),
          if (transaction.currency != null) ...[
            const Divider(height: AppSpacing.xl),
            _DetailRow(
              label: 'Currency',
              value: transaction.currency!,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'successful':
      case 'success':
        return AppColors.success;
      case 'pending':
      case 'processing':
        return AppColors.warning;
      case 'failed':
      case 'error':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'successful':
      case 'success':
        return Icons.check_circle_rounded;
      case 'pending':
      case 'processing':
        return Icons.access_time_rounded;
      case 'failed':
      case 'error':
        return Icons.error_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

