import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/transaction_provider.dart';

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
  late Transaction _transaction;
  bool _isVerifying = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  bool _isPendingStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'pending' || normalized == 'processing';
  }

  String _normalizeStatus(String status) {
    final lower = status.toLowerCase();
    if (lower == 'successful' || lower == 'success' || lower == 'completed') {
      return 'completed';
    }
    if (lower == 'processing' || lower == 'pending') {
      return 'pending';
    }
    if (lower == 'failed' || lower == 'error') {
      return 'failed';
    }
    return lower;
  }

  Future<void> _verifyTransactionStatus(Transaction transaction) async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await ref.read(paymentServiceProvider).verifyPendingTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppColors.success : AppColors.error,
        ),
      );

      if (result.success) {
        setState(() {
          _transaction = _transaction.copyWith(status: 'completed');
        });
        await ref.read(transactionsNotifierProvider.notifier).refresh();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to verify transaction: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  String _resolveNetworkLabel(Transaction transaction) {
    final network = (transaction.network ?? '').trim();
    final operatorName = (transaction.operator ?? '').trim();
    final retailer = (transaction.retailer ?? '').trim();

    if (network.isNotEmpty) {
      final isNumeric = RegExp(r'^\d+$').hasMatch(network);
      if (isNumeric && operatorName.isNotEmpty) {
        return '$operatorName ($network)';
      }
      return network;
    }

    if (operatorName.isNotEmpty) {
      return operatorName;
    }
    if (retailer.isNotEmpty) {
      return retailer;
    }
    return '';
  }

  String _receiptFileName(Transaction transaction) {
    final reference = (transaction.transId ?? transaction.id).trim();
    final safeReference = reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final fallback = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    final fileToken = safeReference.isEmpty ? fallback : safeReference;
    return 'lidapay-receipt-$fileToken.pdf';
  }

  Future<void> _handlePdfAction(Future<void> Function() action) async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
    });
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to export receipt: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<Uint8List> _buildTransactionPdf(Transaction transaction) async {
    final pdf = pw.Document();
    final status = _normalizeStatus(transaction.status);
    final dateLabel = DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt);
    final amountLabel = '${transaction.currency} ${transaction.amount.abs().toStringAsFixed(2)}';
    final transactionTypeLabel = _formatTransactionType(transaction);
    final directionLabel = transaction.amount < 0 ? 'Sent' : 'Received';
    final networkLabel = _resolveNetworkLabel(transaction);

    final primaryColor = PdfColor.fromInt(0xFFEC4899);
    final darkColor = PdfColor.fromInt(0xFF2D2952);
    final mutedColor = PdfColor.fromInt(0xFF6B7280);
    final dividerColor = PdfColor.fromInt(0xFFE5E7EB);

    PdfColor statusColor;
    PdfColor statusBackground;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = PdfColor.fromInt(0xFF16A34A);
        statusBackground = PdfColor.fromInt(0xFFD1FAE5);
        break;
      case 'pending':
        statusColor = PdfColor.fromInt(0xFFF59E0B);
        statusBackground = PdfColor.fromInt(0xFFFDE68A);
        break;
      case 'failed':
        statusColor = PdfColor.fromInt(0xFFEF4444);
        statusBackground = PdfColor.fromInt(0xFFFEE2E2);
        break;
      default:
        statusColor = PdfColor.fromInt(0xFF2563EB);
        statusBackground = PdfColor.fromInt(0xFFDBEAFE);
    }

    pw.Widget detailRow(String label, String value) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(color: mutedColor, fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(color: darkColor, fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      );
    }

    final details = <MapEntry<String, String>>[
      MapEntry('Transaction Type', transactionTypeLabel),
      MapEntry('Status', status.toUpperCase()),
      MapEntry('Direction', directionLabel),
      MapEntry('Amount', amountLabel),
      MapEntry('Date & Time', dateLabel),
    ];

    final recipientName = transaction.recipientName?.trim();
    if (recipientName?.isNotEmpty ?? false) {
      details.add(MapEntry('Recipient', recipientName!));
    }
    final recipientPhone = transaction.recipientPhone?.trim();
    if (recipientPhone?.isNotEmpty ?? false) {
      details.add(MapEntry('Phone Number', recipientPhone!));
    }
    if (networkLabel.isNotEmpty) {
      details.add(MapEntry('Network', networkLabel));
    }
    final operatorName = transaction.operator?.trim();
    if (operatorName?.isNotEmpty ?? false && !networkLabel.toLowerCase().contains(operatorName!.toLowerCase())) {
      details.add(MapEntry('Operator', operatorName ?? 'N/A'));
    }
    final retailer = transaction.retailer?.trim();
    if (retailer?.isNotEmpty ?? false) {
      details.add(MapEntry('Retailer', retailer!));
    }
    final reference = transaction.transId?.trim();
    if (reference?.isNotEmpty ?? false) {
      details.add(MapEntry('Reference', reference!));
    }
    final token = transaction.trxn?.trim();
    if (token?.isNotEmpty ?? false) {
      details.add(MapEntry('Token', token!));
    }

    final detailWidgets = <pw.Widget>[];
    for (var i = 0; i < details.length; i++) {
      detailWidgets.add(detailRow(details[i].key, details[i].value));
      if (i < details.length - 1) {
        detailWidgets.add(pw.SizedBox(height: 8));
        detailWidgets.add(pw.Container(height: 1, color: dividerColor));
        detailWidgets.add(pw.SizedBox(height: 8));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'LidaPay',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Transaction Receipt',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: statusBackground,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      status.toUpperCase(),
                      style: pw.TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Amount',
              style: pw.TextStyle(color: mutedColor, fontSize: 11),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              amountLabel,
              style: pw.TextStyle(color: darkColor, fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: dividerColor),
              ),
              child: pw.Column(children: detailWidgets),
            ),
            if (transaction.note?.trim().isNotEmpty ?? false) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Note',
                style: pw.TextStyle(color: mutedColor, fontSize: 11),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                transaction.note!.trim(),
                style: pw.TextStyle(color: darkColor, fontSize: 12),
              ),
            ],
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF3F4F6),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Receipt ID',
                    style: pw.TextStyle(color: mutedColor, fontSize: 10),
                  ),
                  pw.Text(
                    transaction.transId ?? transaction.id,
                    style: pw.TextStyle(color: darkColor, fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Generated on ${DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(color: mutedColor, fontSize: 9),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Powered by LidaPay',
              style: pw.TextStyle(color: primaryColor, fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _shareTransactionPdf() async {
    await _handlePdfAction(() async {
      final pdfBytes = await _buildTransactionPdf(_transaction);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: _receiptFileName(_transaction),
      );
    });
  }

  Future<void> _downloadTransactionPdf() async {
    await _handlePdfAction(() async {
      await Printing.layoutPdf(
        name: _receiptFileName(_transaction),
        onLayout: (format) async => _buildTransactionPdf(_transaction),
      );
    });
  }

  void _showReceiptActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Receipt Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Share or save a polished PDF receipt for this transaction.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.share_rounded, color: AppColors.brandPrimary),
                  title: const Text('Share PDF'),
                  subtitle: const Text('Send the receipt via any app.'),
                  onTap: _isExporting
                      ? null
                      : () {
                          Navigator.pop(context);
                          _shareTransactionPdf();
                        },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.download_rounded, color: AppColors.secondary),
                  title: const Text('Download PDF'),
                  subtitle: const Text('Save or print the receipt locally.'),
                  onTap: _isExporting
                      ? null
                      : () {
                          Navigator.pop(context);
                          _downloadTransactionPdf();
                        },
                ),
                if (_isExporting) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Preparing your receipt...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    final status = _normalizeStatus(transaction.status);
    final isExpense = transaction.amount < 0;

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
                  _buildJourneyCard(context, transaction, isExpense, status),
                  const SizedBox(height: AppSpacing.lg),
                  // Transaction Status Card
                  _buildStatusCard(context, transaction, status),
                  if (_isPendingStatus(status)) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildPendingAction(context, transaction),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Amount Card
                  _buildAmountCard(context, transaction, isExpense),
                  const SizedBox(height: AppSpacing.lg),
                  // Transaction Details
                  _buildDetailsSection(context, transaction, isExpense),
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
                    onPressed: _showReceiptActions,
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

  Widget _buildJourneyCard(
    BuildContext context,
    Transaction transaction,
    bool isExpense,
    String status,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(status);
    final formattedType = _formatTransactionType(transaction);
    final senderName = (transaction.userName?.trim().isNotEmpty ?? false)
        ? transaction.userName!
        : 'You';
    final recipientName = (transaction.recipientName?.trim().isNotEmpty ?? false)
        ? transaction.recipientName!
        : (transaction.recipientPhone?.trim().isNotEmpty ?? false)
            ? transaction.recipientPhone!
            : 'Recipient';
    final recipientSub = (transaction.recipientPhone?.trim().isNotEmpty ?? false)
        ? transaction.recipientPhone!
        : transaction.retailer ?? 'Lidapay Wallet';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer Journey',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              _buildStatusPill(status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RouteTimeline(color: statusColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _JourneyPoint(
                      label: 'From',
                      value: senderName,
                      caption: 'Lidapay Wallet',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _JourneyPoint(
                      label: 'To',
                      value: recipientName,
                      caption: recipientSub,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _JourneyMeta(label: 'Type', value: formattedType),
              _JourneyMeta(
                label: 'Date',
                value: DateFormat('MMM dd, yyyy').format(transaction.createdAt),
              ),
              _JourneyMeta(
                label: 'Time',
                value: DateFormat('hh:mm a').format(transaction.createdAt),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 120.ms);
  }

  Widget _buildPendingAction(BuildContext context, Transaction transaction) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

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
            'Pending Action',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This transaction is still processing. Check its status to update it or credit your account.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isVerifying ? null : () => _verifyTransactionStatus(transaction),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: _isVerifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_rounded, size: 18),
              label: Text(_isVerifying ? 'Checking...' : 'Check Status'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 220.ms);
  }

  Widget _buildDetailsSection(BuildContext context, Transaction transaction, bool isExpense) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final details = <Widget>[
      _DetailRow(
        label: 'Transaction Type',
        value: _formatTransactionType(transaction),
      ),
      _DetailRow(
        label: 'Direction',
        value: isExpense ? 'Sent' : 'Received',
      ),
    ];

    if (transaction.recipientName?.trim().isNotEmpty ?? false) {
      details.add(
        _DetailRow(
          label: 'Recipient',
          value: transaction.recipientName!,
        ),
      );
    }
    if (transaction.recipientPhone?.trim().isNotEmpty ?? false) {
      details.add(
        _DetailRow(
          label: 'Phone Number',
          value: transaction.recipientPhone!,
        ),
      );
    }

    details.add(
      _DetailRow(
        label: 'Date & Time',
        value: DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.createdAt),
      ),
    );

    if (transaction.note?.trim().isNotEmpty ?? false) {
      details.add(
        _DetailRow(
          label: 'Note',
          value: transaction.note!,
        ),
      );
    }
    final networkLabel = _resolveNetworkLabel(transaction);
    if (networkLabel.isNotEmpty) {
      details.add(
        _DetailRow(
          label: 'Network',
          value: networkLabel,
        ),
      );
    }
    final operatorName = transaction.operator?.trim();
    if (operatorName?.isNotEmpty ?? false && !networkLabel.toLowerCase().contains(operatorName!.toLowerCase())) {
      details.add(
        _DetailRow(
          label: 'Operator',
          value: operatorName ?? 'N/A',
        ),
      );
    }
    if (transaction.retailer?.trim().isNotEmpty ?? false) {
      details.add(
        _DetailRow(
          label: 'Retailer',
          value: transaction.retailer!,
        ),
      );
    }
    if (transaction.transId?.trim().isNotEmpty ?? false) {
      details.add(
        _DetailRow(
          label: 'Reference',
          value: transaction.transId!,
          isCopyable: true,
        ),
      );
    }
    if (transaction.trxn?.trim().isNotEmpty ?? false) {
      details.add(
        _DetailRow(
          label: 'Token',
          value: transaction.trxn!,
          isCopyable: true,
        ),
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < details.length; i++) {
      children.add(details[i]);
      if (i < details.length - 1) {
        children.add(const Divider(height: AppSpacing.xl));
      }
    }

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
          ...children,
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

  Widget _buildStatusPill(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  String _formatTransactionType(Transaction transaction) {
    final raw = (transaction.transType ?? transaction.type ?? '').toLowerCase().trim();
    if (raw.isEmpty) {
      return 'Transfer';
    }
    if (raw.contains('airtime') || raw.contains('airtopup')) {
      return 'Airtime Top-up';
    }
    if (raw.contains('data')) {
      return 'Data Bundle';
    }
    if (raw.contains('momo') || raw.contains('mobile')) {
      return 'Mobile Money';
    }
    final cleaned = raw.replaceAll(RegExp(r'[_-]'), ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _JourneyPoint extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const _JourneyPoint({
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: muted,
              ),
        ),
      ],
    );
  }
}

class _JourneyMeta extends StatelessWidget {
  final String label;
  final String value;

  const _JourneyMeta({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withOpacity(isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: muted,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _RouteTimeline extends StatelessWidget {
  final Color color;

  const _RouteTimeline({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 32,
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: color.withOpacity(0.3),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
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

