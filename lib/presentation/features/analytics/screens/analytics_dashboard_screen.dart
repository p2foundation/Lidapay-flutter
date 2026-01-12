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
            child: _AnimatedBarChart(
              data: analytics.dailySpending,
              isDark: isDark,
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
          ...analytics.categorySpending.entries.map((entry) {
            final percentage = analytics.totalSpent > 0
                ? (entry.value / analytics.totalSpent * 100)
                : 0.0;
            return _CategoryItem(
              category: entry.key,
              amount: entry.value,
              percentage: percentage,
              isDark: isDark,
            );
          }),
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

    // Category spending
    final categorySpending = <String, double>{};
    for (final t in filteredTransactions.where((t) => t.amount < 0)) {
      final category = t.transType ?? t.type ?? 'Other';
      categorySpending[category] = (categorySpending[category] ?? 0) + t.amount.abs();
    }

    // Daily spending based on period
    final dailySpending = <String, double>{};
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
      totalTransactions: filteredTransactions.length,
      categorySpending: categorySpending,
      dailySpending: dailySpending,
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
  final int totalTransactions;
  final Map<String, double> categorySpending;
  final Map<String, double> dailySpending;
  final double transactionTrend;
  final double amountTrend;
  final double averageAmount;

  AnalyticsData({
    required this.totalSpent,
    required this.totalReceived,
    required this.totalTransactions,
    required this.categorySpending,
    required this.dailySpending,
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
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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

