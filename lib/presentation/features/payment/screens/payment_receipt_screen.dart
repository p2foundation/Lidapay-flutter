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

class PaymentReceiptScreen extends ConsumerStatefulWidget {
  final bool isSuccess;
  final String transactionType; // 'AIRTIME' or 'DATA'
  final String? transactionId;
  final double amount;
  final String currency;
  final double? topupAmount;
  final String? topupCurrency;
  final double? paymentAmount;
  final String? paymentCurrency;
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
    this.topupAmount,
    this.topupCurrency,
    this.paymentAmount,
    this.paymentCurrency,
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
  bool _isExporting = false;

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

  double get _displayPaymentAmount => widget.paymentAmount ?? widget.amount;
  String get _displayPaymentCurrency => widget.paymentCurrency ?? widget.currency;
  double get _displayTopupAmount => widget.topupAmount ?? widget.amount;
  String get _displayTopupCurrency => widget.topupCurrency ?? widget.currency;
  
  // For Ghana transactions, show top-up amount as primary
  double get _primaryAmount => (widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? _displayTopupAmount : _displayPaymentAmount;
  String get _primaryCurrency => (widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? _displayTopupCurrency : _displayPaymentCurrency;
  double get _secondaryAmount => (widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? _displayPaymentAmount : _displayTopupAmount;
  String get _secondaryCurrency => (widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? _displayPaymentCurrency : _displayTopupCurrency;

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

  String _receiptFileName() {
    final reference = (widget.transactionId ?? '').trim();
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

  Future<Uint8List> _buildReceiptPdf() async {
    final pdf = pw.Document();
    final timestamp = widget.timestamp ?? DateTime.now();
    final dateLabel = DateFormat('dd MMM yyyy - HH:mm').format(timestamp);
    final amountLabel = '${_primaryCurrency} ${_primaryAmount.toStringAsFixed(2)}';
    final topupLabel = _primaryCurrency != _secondaryCurrency ? '${_secondaryCurrency} ${_secondaryAmount.toStringAsFixed(2)}' : null;

    final primaryColor = PdfColor.fromInt(0xFFEC4899);
    final darkColor = PdfColor.fromInt(0xFF2D2952);
    final mutedColor = PdfColor.fromInt(0xFF6B7280);
    final dividerColor = PdfColor.fromInt(0xFFE5E7EB);

    final isSuccess = widget.isSuccess;
    final statusLabel = isSuccess ? 'SUCCESSFUL' : 'FAILED';
    final statusColor = isSuccess ? PdfColor.fromInt(0xFF16A34A) : PdfColor.fromInt(0xFFEF4444);
    final statusBackground = isSuccess ? PdfColor.fromInt(0xFFD1FAE5) : PdfColor.fromInt(0xFFFEE2E2);

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
      MapEntry('Transaction Type', _transactionTypeLabel),
      MapEntry('Status', statusLabel),
      MapEntry((widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? 'Bundle Amount' : 'Payment Amount', amountLabel),
      if (topupLabel != null) 
        MapEntry((widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? 'Paid Amount' : 'Top-up Amount', topupLabel),
      MapEntry('Recipient', widget.recipientNumber),
      MapEntry('Date & Time', dateLabel),
    ];

    if (widget.operatorName?.trim().isNotEmpty ?? false) {
      details.add(MapEntry('Operator', widget.operatorName!.trim()));
    }
    if (widget.countryName?.trim().isNotEmpty ?? false) {
      details.add(MapEntry('Country', widget.countryName!.trim()));
    }
    if (widget.bundleName?.trim().isNotEmpty ?? false) {
      details.add(MapEntry('Bundle', widget.bundleName!.trim()));
    }
    if (widget.transactionId?.trim().isNotEmpty ?? false) {
      details.add(MapEntry('Transaction ID', widget.transactionId!.trim()));
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
                      statusLabel,
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
            if (!isSuccess && widget.errorMessage?.trim().isNotEmpty == true) ...[
              pw.SizedBox(height: 16),
              pw.Text(
                'Failure Reason',
                style: pw.TextStyle(color: mutedColor, fontSize: 11),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                widget.errorMessage!.trim(),
                style: pw.TextStyle(color: darkColor, fontSize: 12),
              ),
            ],
            pw.SizedBox(height: 16),
            pw.Text(
              'Generated on ${DateFormat('dd MMM yyyy - HH:mm').format(DateTime.now())}',
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

  Future<void> _shareReceiptPdf() async {
    await _handlePdfAction(() async {
      final pdfBytes = await _buildReceiptPdf();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: _receiptFileName(),
      );
    });
  }

  Future<void> _downloadReceiptPdf() async {
    await _handlePdfAction(() async {
      await Printing.layoutPdf(
        name: _receiptFileName(),
        onLayout: (format) async => _buildReceiptPdf(),
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
                          _shareReceiptPdf();
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
                          _downloadReceiptPdf();
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
            onPressed: _showReceiptActions,
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
          
          // Amount (Primary)
          Text(
            '${_primaryCurrency} ${_primaryAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: AppSpacing.xs),
          // Secondary amount (show the other amount)
          if (_primaryCurrency != _secondaryCurrency) ...[
            Text(
              (widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA')
                  ? 'Paid: ${_secondaryCurrency} ${_secondaryAmount.toStringAsFixed(2)}'
                  : 'Top-up: ${_secondaryCurrency} ${_secondaryAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
            ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.2, end: 0),
          ],
          
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
                        DateFormat('dd MMM yyyy - HH:mm').format(timestamp),
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
                  label: (widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? 'Bundle Amount' : 'Payment Amount',
                  value: '${_primaryCurrency} ${_primaryAmount.toStringAsFixed(2)}',
                  isDark: isDark,
                  isHighlighted: true,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_primaryCurrency != _secondaryCurrency) ...[
                  _ReceiptRow(
                    label: (widget.transactionType == 'PRYMOAIRTIME' || widget.transactionType == 'PRYMODATA') ? 'Paid Amount' : 'Top-up Amount',
                    value: '${_secondaryCurrency} ${_secondaryAmount.toStringAsFixed(2)}',
                    isDark: isDark,
                  ),
                ],
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
                onPressed: _showReceiptActions,
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
