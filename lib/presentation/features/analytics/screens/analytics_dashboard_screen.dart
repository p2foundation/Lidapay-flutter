import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/transaction_provider.dart';
import '../../../../data/models/api_models.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'month'; // month, week, year
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    // Load transactions on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsNotifierProvider.notifier).loadTransactions();
    });
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
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = transactionsState.transactions;

    // Calculate analytics
    final analytics = _calculateAnalytics(transactions, _selectedPeriod, _selectedDate);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.read(transactionsNotifierProvider.notifier).refresh();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Period Selector
                      _buildPeriodSelector(context, isDark),
                      const SizedBox(height: AppSpacing.lg),
                      // Summary Cards
                      _buildSummaryCards(context, analytics, isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildInsightCards(context, analytics, isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildKeyMetrics(context, analytics, isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildStatusBreakdown(context, analytics, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      // Spending Chart
                      _buildSpendingChart(context, analytics, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      // Category Breakdown
                      _buildCategoryBreakdown(context, analytics, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      // Transaction Trends
                      _buildTransactionTrends(context, analytics, isDark),
                      const SizedBox(height: AppSpacing.xl),
                      // Top Transactions
                      _buildTopTransactions(context, transactions, isDark),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(BuildContext context, AnalyticsData analytics, bool isDark) {
    final netFlow = analytics.netFlow;
    final netPositive = netFlow >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _MetricCard(
              label: 'Net Flow',
              value: 'GHS ${netFlow.toStringAsFixed(2)}',
              icon: netPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: netPositive ? AppColors.success : AppColors.error,
              isDark: isDark,
            ),
            _MetricCard(
              label: 'Avg. Amount',
              value: 'GHS ${analytics.averageAmount.toStringAsFixed(2)}',
              icon: Icons.calculate_rounded,
              color: AppColors.primary,
              isDark: isDark,
            ),
            _MetricCard(
              label: 'Largest Spent',
              value: 'GHS ${analytics.maxSpent.toStringAsFixed(2)}',
              icon: Icons.trending_down_rounded,
              color: AppColors.error,
              isDark: isDark,
            ),
            _MetricCard(
              label: 'Largest Received',
              value: 'GHS ${analytics.maxReceived.toStringAsFixed(2)}',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Text(
                'Analytics Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
              onPressed: () {
                // TODO: Show filter options
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPeriodSelector(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          _PeriodButton(
            label: 'Week',
            isSelected: _selectedPeriod == 'week',
            onTap: () => setState(() => _selectedPeriod = 'week'),
          ),
          _PeriodButton(
            label: 'Month',
            isSelected: _selectedPeriod == 'month',
            onTap: () => setState(() => _selectedPeriod = 'month'),
          ),
          _PeriodButton(
            label: 'Year',
            isSelected: _selectedPeriod == 'year',
            onTap: () => setState(() => _selectedPeriod = 'year'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AnalyticsData analytics, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Spent',
            value: 'GHS ${analytics.totalSpent.toStringAsFixed(2)}',
            icon: Icons.trending_down_rounded,
            color: AppColors.error,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            title: 'Total Received',
            value: 'GHS ${analytics.totalReceived.toStringAsFixed(2)}',
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCards(BuildContext context, AnalyticsData analytics, bool isDark) {
    final spendingIncrease = analytics.amountTrend >= 0;
    final transactionIncrease = analytics.transactionTrend >= 0;

    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            label: 'Spending change',
            value:
                '${spendingIncrease ? '+' : ''}${analytics.amountTrend.toStringAsFixed(1)}%',
            subtitle: 'vs previous period',
            icon: spendingIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: spendingIncrease ? AppColors.warning : AppColors.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _InsightCard(
            label: 'Transaction change',
            value:
                '${transactionIncrease ? '+' : ''}${analytics.transactionTrend.toStringAsFixed(1)}%',
            subtitle: 'vs previous period',
            icon: transactionIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: transactionIncrease ? AppColors.success : AppColors.error,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(BuildContext context, AnalyticsData analytics, bool isDark) {
    final total = analytics.totalTransactions;
    final completed = analytics.completedCount;
    final pending = analytics.pendingCount;
    final failed = analytics.failedCount;
    final successRate = total > 0 ? (completed / total * 100) : 0.0;

    final segments = [
      _StatusSegment(label: 'Completed', count: completed, color: AppColors.success),
      _StatusSegment(label: 'Pending', count: pending, color: AppColors.warning),
      _StatusSegment(label: 'Failed', count: failed, color: AppColors.error),
    ].where((segment) => segment.count > 0).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Status Mix',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                total == 0 ? 'No transactions' : '${successRate.toStringAsFixed(0)}% success',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            _EmptyChartState(
              icon: Icons.analytics_rounded,
              title: 'No transactions in this period',
              subtitle: 'Your status mix will appear here',
              isDark: isDark,
            )
          else ...[
            Row(
              children: List.generate(segments.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const SizedBox(width: 4);
                }
                final segment = segments[index ~/ 2];
                final isFirst = index == 0;
                final isLast = index == segments.length * 2 - 2;
                return Expanded(
                  flex: segment.count,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: segment.color,
                      borderRadius: BorderRadius.horizontal(
                        left: isFirst ? const Radius.circular(AppRadius.full) : Radius.zero,
                        right: isLast ? const Radius.circular(AppRadius.full) : Radius.zero,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatusChip(
                  label: 'Completed',
                  count: completed,
                  color: AppColors.success,
                  isDark: isDark,
                ),
                _StatusChip(
                  label: 'Pending',
                  count: pending,
                  color: AppColors.warning,
                  isDark: isDark,
                ),
                _StatusChip(
                  label: 'Failed',
                  count: failed,
                  color: AppColors.error,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildSpendingChart(BuildContext context, AnalyticsData analytics, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 220,
            child: _AnimatedLineChart(
              data: analytics.dailySpending,
              isDark: isDark,
              showCurrency: true,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildCategoryBreakdown(BuildContext context, AnalyticsData analytics, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (analytics.categorySpending.isEmpty || analytics.totalSpent == 0)
            _EmptyChartState(
              icon: Icons.pie_chart_rounded,
              title: 'No category data yet',
              subtitle: 'Your spending breakdown will appear here',
              isDark: isDark,
            )
          else
            _CategoryBreakdownChart(
              data: analytics.categorySpending,
              total: analytics.totalSpent,
              isDark: isDark,
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildTransactionTrends(BuildContext context, AnalyticsData analytics, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Trends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 160,
            child: _AnimatedLineChart(
              data: analytics.dailyTransactions
                  .map((key, value) => MapEntry(key, value.toDouble())),
              isDark: isDark,
              showCurrency: false,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _TrendCard(
                  label: 'Transactions',
                  value: analytics.totalTransactions.toString(),
                  trend: analytics.transactionTrend,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _TrendCard(
                  label: 'Avg. Amount',
                  value: 'GHS ${analytics.averageAmount.toStringAsFixed(2)}',
                  trend: analytics.amountTrend,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTopTransactions(BuildContext context, List<Transaction> transactions, bool isDark) {
    final topTransactions = transactions
        .where((t) => t.amount < 0)
        .toList()
      ..sort((a, b) => b.amount.abs().compareTo(a.amount.abs()));

    if (topTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...topTransactions.take(5).map((t) => _TopTransactionItem(
                transaction: t,
                isDark: isDark,
              )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  AnalyticsData _calculateAnalytics(
    List<Transaction> transactions,
    String period,
    DateTime selectedDate,
  ) {
    DateTime startDate;
    switch (period) {
      case 'week':
        startDate = selectedDate.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        break;
      case 'year':
        startDate = DateTime(selectedDate.year, 1, 1);
        break;
      default:
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
    }

    final filteredTransactions = transactions.where((t) {
      return t.createdAt.isAfter(startDate) && t.createdAt.isBefore(selectedDate.add(const Duration(days: 1)));
    }).toList();

    final totalSpent = filteredTransactions
        .where((t) => t.amount < 0)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    final totalReceived = filteredTransactions
        .where((t) => t.amount > 0)
        .fold<double>(0, (sum, t) => sum + t.amount);

    double maxSpent = 0.0;
    double maxReceived = 0.0;
    for (final transaction in filteredTransactions) {
      if (transaction.amount < 0) {
        final value = transaction.amount.abs();
        if (value > maxSpent) {
          maxSpent = value;
        }
      } else if (transaction.amount > 0) {
        if (transaction.amount > maxReceived) {
          maxReceived = transaction.amount;
        }
      }
    }

    var pendingCount = 0;
    var completedCount = 0;
    var failedCount = 0;

    for (final transaction in filteredTransactions) {
      final status = _normalizeStatus(transaction.status);
      if (status == 'completed') {
        completedCount++;
      } else if (status == 'pending') {
        pendingCount++;
      } else if (status == 'failed') {
        failedCount++;
      }
    }

    // Category spending
    final categorySpending = <String, double>{};
    for (final t in filteredTransactions.where((t) => t.amount < 0)) {
      final category = t.transType ?? t.type ?? 'Other';
      categorySpending[category] = (categorySpending[category] ?? 0) + t.amount.abs();
    }

    // Daily spending based on period
    final dailySpending = <String, double>{};
    final dailyTransactions = <String, int>{};
    if (period == 'week') {
      // Last 7 days
      for (int i = 6; i >= 0; i--) {
        final date = selectedDate.subtract(Duration(days: i));
        final dateKey = DateFormat('MMM dd').format(date);
        final dayTotal = filteredTransactions
            .where((t) =>
                t.amount < 0 &&
                t.createdAt.year == date.year &&
                t.createdAt.month == date.month &&
                t.createdAt.day == date.day)
            .fold<double>(0, (sum, t) => sum + t.amount.abs());
        dailySpending[dateKey] = dayTotal;
        dailyTransactions[dateKey] = filteredTransactions
            .where((t) =>
                t.createdAt.year == date.year &&
                t.createdAt.month == date.month &&
                t.createdAt.day == date.day)
            .length;
      }
    } else if (period == 'month') {
      // Last 30 days grouped by day
      for (int i = 29; i >= 0; i--) {
        final date = selectedDate.subtract(Duration(days: i));
        final dateKey = DateFormat('MMM dd').format(date);
        final dayTotal = filteredTransactions
            .where((t) =>
                t.amount < 0 &&
                t.createdAt.year == date.year &&
                t.createdAt.month == date.month &&
                t.createdAt.day == date.day)
            .fold<double>(0, (sum, t) => sum + t.amount.abs());
        dailySpending[dateKey] = (dailySpending[dateKey] ?? 0) + dayTotal;
        dailyTransactions[dateKey] = filteredTransactions
            .where((t) =>
                t.createdAt.year == date.year &&
                t.createdAt.month == date.month &&
                t.createdAt.day == date.day)
            .length;
      }
    } else if (period == 'year') {
      // Last 12 months grouped by month
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(selectedDate.year, selectedDate.month - i, 1);
        final dateKey = DateFormat('MMM yyyy').format(date);
        final monthTotal = filteredTransactions
            .where((t) =>
                t.amount < 0 &&
                t.createdAt.year == date.year &&
                t.createdAt.month == date.month)
            .fold<double>(0, (sum, t) => sum + t.amount.abs());
        dailySpending[dateKey] = monthTotal;
        dailyTransactions[dateKey] = filteredTransactions
            .where((t) =>
                t.createdAt.year == date.year &&
                t.createdAt.month == date.month)
            .length;
      }
    }

    // Calculate trends (simplified - compare with previous period)
    final previousStartDate = startDate.subtract(Duration(
      days: period == 'week' ? 7 : period == 'month' ? 30 : 365,
    ));
    final previousTransactions = transactions.where((t) {
      return t.createdAt.isAfter(previousStartDate) && t.createdAt.isBefore(startDate);
    }).toList();

    final previousCount = previousTransactions.length;
    final currentCount = filteredTransactions.length;
    final transactionTrend = previousCount > 0
        ? ((currentCount - previousCount) / previousCount * 100)
        : 0.0;

    final previousAmount = previousTransactions
        .where((t) => t.amount < 0)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());
    final currentAmount = totalSpent;
    final amountTrend = previousAmount > 0
        ? ((currentAmount - previousAmount) / previousAmount * 100)
        : 0.0;

    return AnalyticsData(
      totalSpent: totalSpent,
      totalReceived: totalReceived,
      netFlow: totalReceived - totalSpent,
      maxSpent: maxSpent,
      maxReceived: maxReceived,
      totalTransactions: filteredTransactions.length,
      completedCount: completedCount,
      pendingCount: pendingCount,
      failedCount: failedCount,
      categorySpending: categorySpending,
      dailySpending: dailySpending,
      dailyTransactions: dailyTransactions,
      transactionTrend: transactionTrend,
      amountTrend: amountTrend,
      averageAmount: filteredTransactions.isNotEmpty
          ? totalSpent / filteredTransactions.length
          : 0.0,
    );
  }
}

class AnalyticsData {
  final double totalSpent;
  final double totalReceived;
  final double netFlow;
  final double maxSpent;
  final double maxReceived;
  final int totalTransactions;
  final int completedCount;
  final int pendingCount;
  final int failedCount;
  final Map<String, double> categorySpending;
  final Map<String, double> dailySpending;
  final Map<String, int> dailyTransactions;
  final double transactionTrend;
  final double amountTrend;
  final double averageAmount;

  AnalyticsData({
    required this.totalSpent,
    required this.totalReceived,
    required this.netFlow,
    required this.maxSpent,
    required this.maxReceived,
    required this.totalTransactions,
    required this.completedCount,
    required this.pendingCount,
    required this.failedCount,
    required this.categorySpending,
    required this.dailySpending,
    required this.dailyTransactions,
    required this.transactionTrend,
    required this.amountTrend,
    required this.averageAmount,
  });
}

// Widgets
class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _InsightCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      width: 160,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusSegment {
  final String label;
  final int count;
  final Color color;

  const _StatusSegment({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isDark;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyChartState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLineChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;
  final bool showCurrency;

  const _AnimatedLineChart({
    required this.data,
    required this.isDark,
    required this.showCurrency,
  });

  @override
  State<_AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<_AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty || widget.data.values.every((v) => v == 0)) {
      return _EmptyChartState(
        icon: Icons.show_chart_rounded,
        title: 'No spending data available',
        subtitle: 'Your activity will appear here',
        isDark: widget.isDark,
      );
    }

    final entries = widget.data.entries.toList();
    final maxValue = widget.data.values.reduce((a, b) => a > b ? a : b);
    final double maxY = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final step = entries.length <= 7
        ? 1
        : entries.length <= 14
            ? 2
            : entries.length <= 30
                ? 5
                : (entries.length / 6).ceil();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            minX: 0,
            maxX: (entries.length - 1).toDouble(),
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: widget.isDark
                      ? AppColors.darkBorder.withOpacity(0.2)
                      : AppColors.lightBorder.withOpacity(0.3),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    if (index % step != 0) {
                      return const SizedBox.shrink();
                    }
                    final label = entries[index].key;
                    final parts = label.split(' ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        parts.length > 1 ? parts[1] : label,
                        style: TextStyle(
                          color: widget.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) {
                      return const SizedBox.shrink();
                    }
                    final label = widget.showCurrency
                        ? 'GHS ${value.toInt()}'
                        : value.toInt().toString();
                    return Text(
                      label,
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: AppRadius.md,
                tooltipPadding: const EdgeInsets.all(8),
                tooltipBgColor:
                    widget.isDark ? AppColors.darkCard : Colors.white,
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final index = spot.x.toInt();
                    final label = entries[index].key;
                    final value = spot.y;
                    final formatted = widget.showCurrency
                        ? 'GHS ${value.toStringAsFixed(2)}'
                        : value.toInt().toString();
                    return LineTooltipItem(
                      '$formatted\n$label',
                      TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  width: 1,
                ),
                left: BorderSide(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: entries.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value.value * _animation.value,
                  );
                }).toList(),
                isCurved: true,
                barWidth: 3,
                gradient: AppColors.primaryGradient,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      AppColors.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryBreakdownChart extends StatelessWidget {
  final Map<String, double> data;
  final double total;
  final bool isDark;

  const _CategoryBreakdownChart({
    required this.data,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(4).toList();
    final otherTotal = entries.skip(4).fold<double>(0, (sum, e) => sum + e.value);
    if (otherTotal > 0) {
      topEntries.add(MapEntry('Other', otherTotal));
    }

    final palette = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 46,
                sections: topEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final color = palette[index % palette.length];
                  final percent = total == 0 ? 0.0 : (item.value / total * 100);
                  return PieChartSectionData(
                    value: item.value,
                    color: color,
                    radius: 48,
                    title: '${percent.toStringAsFixed(0)}%',
                    titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: topEntries.asMap().entries.map((entry) {
              final color = palette[entry.key % palette.length];
              final percent = total == 0 ? 0.0 : (entry.value.value / total * 100);
              return _CategoryLegendItem(
                label: entry.value.key,
                amount: entry.value.value,
                percentage: percent,
                color: color,
                isDark: isDark,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  final String label;
  final double amount;
  final double percentage;
  final Color color;
  final bool isDark;

  const _CategoryLegendItem({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBarChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const _AnimatedBarChart({
    required this.data,
    required this.isDark,
  });

  @override
  State<_AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<_AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty || widget.data.values.every((v) => v == 0)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No spending data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your spending will appear here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
            ),
          ],
        ),
      );
    }

    final entries = widget.data.entries.toList();
    final maxValue = widget.data.values.reduce((a, b) => a > b ? a : b);
    final maxY = maxValue * 1.2; // Add 20% padding at top

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: widget.isDark
                    ? AppColors.darkCard
                    : Colors.white,
                tooltipRoundedRadius: AppRadius.md,
                tooltipPadding: const EdgeInsets.all(8),
                tooltipMargin: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final date = entries[groupIndex].key;
                  final value = entries[groupIndex].value;
                  return BarTooltipItem(
                    'GHS ${value.toStringAsFixed(2)}\n$date',
                    TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= entries.length) {
                      return const Text('');
                    }
                    final date = entries[value.toInt()].key;
                    // Show abbreviated date
                    final parts = date.split(' ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        parts.length > 1 ? parts[1] : date,
                        style: TextStyle(
                          color: widget.isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) {
                      return const Text('');
                    }
                    return Text(
                      'GHS ${value.toInt()}',
                      style: TextStyle(
                        color: widget.isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: widget.isDark
                      ? AppColors.darkBorder.withOpacity(0.2)
                      : AppColors.lightBorder.withOpacity(0.3),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  width: 1,
                ),
                left: BorderSide(
                  color: widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            barGroups: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final dataEntry = entry.value;
              final animatedValue = dataEntry.value * _animation.value;
              
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: animatedValue,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xs),
                    ),
                    gradient: AppColors.primaryGradient,
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: widget.isDark
                          ? AppColors.darkBorder.withOpacity(0.1)
                          : AppColors.lightBorder.withOpacity(0.1),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final bool isDark;

  const _CategoryItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.toUpperCase(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                'GHS ${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}% of total',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String label;
  final String value;
  final double trend;
  final bool isDark;

  const _TrendCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = trend > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 16,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isPositive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopTransactionItem extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;

  const _TopTransactionItem({
    required this.transaction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.recipientName ?? transaction.transType ?? 'Transaction',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                ),
              ],
            ),
          ),
          Text(
            'GHS ${transaction.amount.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
          ),
        ],
      ),
    );
  }
}

