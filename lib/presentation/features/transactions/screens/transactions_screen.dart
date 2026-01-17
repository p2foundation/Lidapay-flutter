import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/transaction_provider.dart';
import '../widgets/date_button.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedType;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  final ScrollController _scrollController = ScrollController();
  bool _isApplyingFilter = false; // Prevent multiple simultaneous filter applications
  final Set<String> _verifyingTransactions = {};

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // Load initial transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsNotifierProvider.notifier).loadTransactions();
    });
    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  List<Transaction> _applyLocalFilters(List<Transaction> transactions) {
    if (_selectedType == null && _selectedStatus == null) {
      return transactions;
    }

    return transactions.where((transaction) {
      final matchesType = _selectedType == null
          ? true
          : _matchesType(transaction, _selectedType!);
      final matchesStatus = _selectedStatus == null
          ? true
          : _normalizeStatus(transaction.status) == _selectedStatus;
      return matchesType && matchesStatus;
    }).toList();
  }

  bool _matchesType(Transaction transaction, String type) {
    final raw = (transaction.transType ?? transaction.type ?? '').toLowerCase();
    switch (type) {
      case 'airtime':
        return raw.contains('airtime');
      case 'data':
        return raw.contains('data');
      case 'momo':
        return raw.contains('momo');
      default:
        return true;
    }
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when user scrolls near bottom
      final state = ref.read(transactionsNotifierProvider);
      if (state.hasMore && !state.isLoading) {
        ref.read(transactionsNotifierProvider.notifier).loadMore();
      }
    }
  }

  bool _isPendingStatus(String status) {
    return _normalizeStatus(status) == 'pending';
  }

  Future<void> _verifyPendingTransaction(Transaction transaction) async {
    if (_verifyingTransactions.contains(transaction.id)) {
      return;
    }

    setState(() {
      _verifyingTransactions.add(transaction.id);
    });

    try {
      final result = await ref
          .read(paymentServiceProvider)
          .verifyPendingTransaction(transaction);

      if (!mounted) return;

      final color = result.success ? AppColors.success : AppColors.error;
      final message = result.success
          ? result.message
          : 'Payment failed or was not authorized. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          showCloseIcon: true,
        ),
      );

      if (result.success) {
        await ref.read(transactionsNotifierProvider.notifier).refresh();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Payment failed or was not authorized. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          showCloseIcon: true,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _verifyingTransactions.remove(transaction.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsNotifierProvider);
    final visibleTransactions = _applyLocalFilters(transactionsState.transactions);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Hero Header with Gradient
            _buildHeader(context, transactionsState, visibleTransactions),
            // Main Content
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  children: [
                    // Add spacing from header
                    const SizedBox(height: AppSpacing.lg),
                    // Filter Chips
                    _buildFilterChips(),
                    const SizedBox(height: AppSpacing.lg),
                    // Transactions List
                    Expanded(
                      child: _buildTransactionsList(transactionsState, visibleTransactions),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(
    TransactionsState state,
    List<Transaction> visibleTransactions,
  ) {
    // Show error state (only if we have an error and no transactions)
    if (state.error != null && state.transactions.isEmpty && !state.isLoading) {
      return _ErrorState(
        message: state.error!,
        onRetry: () {
          ref.read(transactionsNotifierProvider.notifier).refresh();
        },
      );
    }

    // Show loading state on first load
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show empty state (only if not loading and truly empty)
    if (!state.isLoading && visibleTransactions.isEmpty) {
      return _EmptyState(
        isFallback: state.error != null,
        onRetry: () {
          ref.read(transactionsNotifierProvider.notifier).refresh();
        },
      );
    }

    // Show transactions list (even if loading more)
    return Builder(
      builder: (context) {
        final paymentDisplayInfo = ref.watch(paymentDisplayInfoProvider).maybeWhen(
          data: (data) => data,
          orElse: () => <String, PaymentDisplayInfo>{},
        );
        return RefreshIndicator(
          onRefresh: () async {
            // Check if the widget is still mounted before proceeding
            if (!context.mounted) return;
            await ref.read(transactionsNotifierProvider.notifier).refresh();
          },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: visibleTransactions.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show load more indicator at the end
          if (index >= visibleTransactions.length) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: state.isLoading
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: state.hasMore
                            ? () {
                                ref.read(transactionsNotifierProvider.notifier).loadMore();
                              }
                            : null,
                        child: const Text('Load More'),
                      ),
              ),
            );
          }

          final transaction = visibleTransactions[index];
          final reference = transaction.transId ?? transaction.id;
          final displayInfo = paymentDisplayInfo[reference];
          final isPending = _isPendingStatus(transaction.status);
          final isVerifying = _verifyingTransactions.contains(transaction.id);
          return InkWell(
            onTap: () {
              context.push('/transactions/${transaction.id}', extra: transaction);
            },
            child: _TransactionListItem(
              transaction: transaction,
              displayInfo: displayInfo,
              onVerify: isPending ? () => _verifyPendingTransaction(transaction) : null,
              isVerifying: isVerifying,
            )
                .animate()
                .fadeIn(delay: (index * 50).ms)
                .slideX(begin: 0.1, end: 0),
          );
        },
      ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TransactionsState state,
    List<Transaction> visibleTransactions,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient, // Pink to Indigo
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button and Title
            Row(
              children: [
                AppBackButton(
                  onTap: () => context.pop(),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  iconColor: Colors.white,
                ),
                Expanded(
                  child: Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                  onPressed: () {
                    context.push('/analytics');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                  onPressed: () {
                    _showFilterModal(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Transaction Stats
            _buildTransactionStats(state, visibleTransactions),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTransactionStats(TransactionsState state, List<Transaction> visibleTransactions) {
    final isFiltered = _selectedType != null || _selectedStatus != null;
    final statTransactions = isFiltered ? visibleTransactions : state.transactions;
    final total = isFiltered ? visibleTransactions.length : state.total;
    final completed = statTransactions
        .where((t) => _normalizeStatus(t.status) == 'completed')
        .length;
    final pending = statTransactions
        .where((t) => _normalizeStatus(t.status) == 'pending')
        .length;
    final failed = statTransactions
        .where((t) => _normalizeStatus(t.status) == 'failed')
        .length;

    if (state.isLoading && state.transactions.isEmpty) {

      return SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: List.generate(4, (index) => Container(
            width: 80,
            margin: EdgeInsets.only(right: index < 3 ? AppSpacing.sm : 0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
          )),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Total',
            value: total.toString(),
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Completed',
            value: completed.toString(),
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.access_time_rounded,
            label: 'Pending',
            value: pending.toString(),
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.error_rounded,
            label: 'Failed',
            value: failed.toString(),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: _selectedType == null && _selectedStatus == null,
              onTap: () {
                if (_isApplyingFilter) return;
                if (_selectedType == null && _selectedStatus == null) return;
                
                _isApplyingFilter = true;
                setState(() {
                  _selectedType = null;
                  _selectedStatus = null;
                });
                // Clear filters
                ref.read(transactionsNotifierProvider.notifier).setFilter();
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() => _isApplyingFilter = false);
                  }
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Airtime',
              isSelected: _selectedType == 'airtime',
              onTap: () {
                if (_isApplyingFilter) return; // Prevent multiple taps
                if (_selectedType == 'airtime') return; // Already selected
                
                _isApplyingFilter = true;
                setState(() {
                  _selectedType = 'airtime';
                  _selectedStatus = null;
                });
                ref.read(transactionsNotifierProvider.notifier).setFilter(
                  transType: _getTransTypeForFilter('airtime'),
                );
                // Reset flag after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() => _isApplyingFilter = false);
                  }
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Data',
              isSelected: _selectedType == 'data',
              onTap: () {
                if (_isApplyingFilter) return;
                if (_selectedType == 'data') return;
                
                _isApplyingFilter = true;
                setState(() {
                  _selectedType = 'data';
                  _selectedStatus = null;
                });
                ref.read(transactionsNotifierProvider.notifier).setFilter(
                  transType: _getTransTypeForFilter('data'),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() => _isApplyingFilter = false);
                  }
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'MOMO',
              isSelected: _selectedType == 'momo',
              onTap: () {
                if (_isApplyingFilter) return;
                if (_selectedType == 'momo') return;
                
                _isApplyingFilter = true;
                setState(() {
                  _selectedType = 'momo';
                  _selectedStatus = null;
                });
                ref.read(transactionsNotifierProvider.notifier).setFilter(
                  transType: _getTransTypeForFilter('momo'),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() => _isApplyingFilter = false);
                  }
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Completed',
              isSelected: _selectedStatus == 'completed',
              onTap: () {
                setState(() {
                  _selectedStatus = 'completed';
                  _selectedType = null;
                });
                ref.read(transactionsNotifierProvider.notifier).setFilter(
                  status: _getStatusForFilter('completed'),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Pending',
              isSelected: _selectedStatus == 'pending',
              onTap: () {
                setState(() {
                  _selectedStatus = 'pending';
                  _selectedType = null;
                });
                ref.read(transactionsNotifierProvider.notifier).setFilter(
                  status: _getStatusForFilter('pending'),
                );
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Failed',
              isSelected: _selectedStatus == 'failed',
              onTap: () {
                setState(() {
                  _selectedStatus = 'failed';
                  _selectedType = null;
                });
                ref.read(transactionsNotifierProvider.notifier).setFilter(
                  status: _getStatusForFilter('failed'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterModal(
        selectedType: _selectedType,
        selectedStatus: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        onFilterChanged: (type, status, start, end) {
          setState(() {
            _selectedType = type;
            _selectedStatus = status;
            _startDate = start;
            _endDate = end;
          });
          ref.read(transactionsNotifierProvider.notifier).setFilter(
            transType: type != null ? _getTransTypeForFilter(type) : null,
            status: status != null ? _getStatusForFilter(status) : null,
            startDate: start,
            endDate: end,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  String? _getTransTypeForFilter(String? type) {
    switch (type) {
      case 'airtime':
        return 'GLOBAL AIRTIME';
      case 'data':
        return 'GLOBAL DATA';
      case 'momo':
        return 'MOMO';
      default:
        return null;
    }
  }

  String? _getStatusForFilter(String? status) {
    switch (status) {
      case 'completed':
        return 'COMPLETED';
      case 'pending':
        return 'PENDING';
      case 'failed':
        return 'FAILED';
      default:
        return status;
    }
  }
}

// ============================================================================
// STAT CARD
// ============================================================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.2,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.withOpacity(0.85),
                  fontSize: 11,
                  height: 1.2,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FILTER CHIP
// ============================================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final unselectedText = isDark ? AppColors.darkTextSecondary : AppColors.brandSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : borderColor,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : unselectedText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

// ============================================================================
// TRANSACTION LIST ITEM
// ============================================================================
class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final PaymentDisplayInfo? displayInfo;
  final VoidCallback? onVerify;
  final bool isVerifying;

  const _TransactionListItem({
    required this.transaction,
    this.displayInfo,
    this.onVerify,
    this.isVerifying = false,
  });

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.amount < 0;
    final status = _normalizeStatus(transaction.status);
    // Use transType if available, otherwise fall back to type
    final type = (transaction.transType ?? transaction.type ?? '').toLowerCase();
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final paymentAmount = displayInfo?.paymentAmount ?? transaction.amount.abs();
    final paymentCurrency = displayInfo?.paymentCurrency ?? transaction.currency;
    final topupAmount = displayInfo?.topupAmount;
    final topupCurrency = displayInfo?.topupCurrency;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : AppShadows.xs,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon with Gradient
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _getTypeGradient(type),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _getTransactionIcon(type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.recipientName ?? transaction.recipientPhone ?? 'Transaction',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (transaction.paymentMethod != null) ...[
                          Text(
                            transaction.paymentMethod!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                          ),
                          Text(
                            ' • ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                          ),
                        ],
                        Text(
                          _formatDate(transaction.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'}$paymentCurrency ${paymentAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isExpense ? AppColors.error : AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (topupAmount != null && topupCurrency != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Top-up: $topupCurrency ${topupAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (onVerify != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: isVerifying ? null : onVerify,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandPrimary,
                  side: BorderSide(color: AppColors.brandPrimary.withOpacity(0.6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                icon: isVerifying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_rounded, size: 16),
                label: Text(isVerifying ? 'Checking...' : 'Check Status'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'airtime':
        return Icons.phone_android_rounded;
      case 'data':
        return Icons.wifi_rounded;
      case 'payment':
        return Icons.payment_rounded;
      default:
        return Icons.swap_horiz_rounded;
    }
  }

  LinearGradient _getTypeGradient(String? type) {
    switch (type?.toLowerCase()) {
      case 'airtime':
        return AppColors.primaryGradient; // Pink
      case 'data':
        return AppColors.secondaryGradient; // Indigo
      default:
        return AppColors.brandGradient; // Pink to Indigo
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
      case 'error':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================================
// FILTER MODAL
// ============================================================================
class _FilterModal extends StatelessWidget {
  final String? selectedType;
  final String? selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?, String?, DateTime?, DateTime?) onFilterChanged;

  const _FilterModal({
    required this.selectedType,
    required this.selectedStatus,
    this.startDate,
    this.endDate,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Type Filters
                Text(
                  'Transaction Type',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _FilterOption(
                      label: 'All Types',
                      isSelected: selectedType == null,
                      onTap: () => onFilterChanged(null, selectedStatus, startDate, endDate),
                    ),
                    _FilterOption(
                      label: 'Airtime',
                      isSelected: selectedType == 'airtime',
                      onTap: () => onFilterChanged('airtime', selectedStatus, startDate, endDate),
                    ),
                    _FilterOption(
                      label: 'Data',
                      isSelected: selectedType == 'data',
                      onTap: () => onFilterChanged('data', selectedStatus, startDate, endDate),
                    ),
                    _FilterOption(
                      label: 'MOMO',
                      isSelected: selectedType == 'momo',
                      onTap: () => onFilterChanged('momo', selectedStatus, startDate, endDate),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Date Range Filters
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DateButton(
                        label: 'Start Date',
                        date: startDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            onFilterChanged(selectedType, selectedStatus, date, endDate);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DateButton(
                        label: 'End Date',
                        date: endDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            onFilterChanged(selectedType, selectedStatus, startDate, date);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Status Filters
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _FilterOption(
                      label: 'All Status',
                      isSelected: selectedStatus == null,
                      onTap: () => onFilterChanged(selectedType, null, startDate, endDate),
                    ),
                    _FilterOption(
                      label: 'Completed',
                      isSelected: selectedStatus == 'completed',
                      onTap: () => onFilterChanged(selectedType, 'completed', startDate, endDate),
                    ),
                    _FilterOption(
                      label: 'Pending',
                      isSelected: selectedStatus == 'pending',
                      onTap: () => onFilterChanged(selectedType, 'pending', startDate, endDate),
                    ),
                    _FilterOption(
                      label: 'Failed',
                      isSelected: selectedStatus == 'failed',
                      onTap: () => onFilterChanged(selectedType, 'failed', startDate, endDate),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                // Clear Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => onFilterChanged(null, null, null, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text('Clear All Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final unselectedText = isDark ? AppColors.darkTextSecondary : AppColors.brandSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : borderColor,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : unselectedText,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING STATE
// ============================================================================
class _LoadingState extends StatefulWidget {
  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState> {
  bool _showTimeoutMessage = false;

  @override
  void initState() {
    super.initState();
    // Show timeout message after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showTimeoutMessage = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showTimeoutMessage) {
      return _EmptyState(
        isFallback: true,
        onRetry: () {
          // Retry will be handled by parent
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.brandPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading transactions...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================
class _EmptyState extends StatelessWidget {
  final bool isFallback;
  final VoidCallback? onRetry;

  const _EmptyState({
    this.isFallback = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(AppColors.brandPrimary),
              ),
              child: Icon(
                isFallback ? Icons.cloud_off_rounded : Icons.receipt_long_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isFallback ? 'Unable to load transactions' : 'No transactions found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isFallback
                  ? 'The server is taking too long to respond. Please check your connection and try again.'
                  : 'Your transaction history will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (isFallback && onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR STATE
// ============================================================================
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error loading transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
