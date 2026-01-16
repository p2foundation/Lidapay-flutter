import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/statistics_provider.dart';
import '../../../providers/transaction_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedPeriod = 'expenses';
  String _selectedMonth = 'Month';
  bool _hasLoadedTransactions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasLoadedTransactions) return;
      _hasLoadedTransactions = true;
      final state = ref.read(transactionsNotifierProvider);
      if (state.transactions.isEmpty && !state.isLoading) {
        ref.read(transactionsNotifierProvider.notifier).loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statisticsAsync = ref.watch(statisticsProvider);
    final transactionsState = ref.watch(transactionsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentTransactions =
        transactionsState.transactions.take(4).toList(growable: false);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Statistics',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              'All your transaction history',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Toggle Buttons
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: 'Expenses',
                    isSelected: _selectedPeriod == 'expenses',
                    onTap: () => setState(() => _selectedPeriod = 'expenses'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ToggleButton(
                    label: 'Income',
                    isSelected: _selectedPeriod == 'income',
                    onTap: () => setState(() => _selectedPeriod = 'income'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Month Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    underline: const SizedBox(),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'Month', child: Text('Month')),
                      DropdownMenuItem(value: 'Week', child: Text('Week')),
                      DropdownMenuItem(value: 'Year', child: Text('Year')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMonth = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Overview + Chart
            statisticsAsync.when(
              data: (data) => Column(
                children: [
                  _OverviewCards(data: data),
                  const SizedBox(height: AppSpacing.lg),
                  _ChartSection(
                    data: data,
                    selectedPeriod: _selectedPeriod,
                  ),
                ],
              ),
              loading: () => Column(
                children: [
                  const _OverviewSkeleton(),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.error_outline_rounded, color: AppColors.lightError),
                      const SizedBox(height: AppSpacing.md),
                      Text('Error loading statistics'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push('/transactions'),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.brandPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (transactionsState.isLoading && recentTransactions.isEmpty)
              const _HistoryLoadingState()
            else if (recentTransactions.isEmpty)
              const _EmptyHistoryState()
            else
              ...recentTransactions
                  .map((transaction) => _HistoryItem(transaction: transaction))
                  .toList(),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : AppColors.lightBorder,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.brandSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final StatisticsData data;
  final String selectedPeriod;

  const _ChartSection({
    required this.data,
    required this.selectedPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthlyStats = data.monthlyStats;

    if (monthlyStats.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.md,
        ),
        child: const Center(child: Text('No data available')),
      );
    }

    // Highlight latest available month
    final highlightedIndex = monthlyStats.length - 1;
    final highlightedValue = selectedPeriod == 'expenses'
        ? monthlyStats[highlightedIndex].expenses
        : monthlyStats[highlightedIndex].income;
    final monthLabels = monthlyStats.map((stat) => stat.month).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < monthLabels.length) {
                          final label = monthLabels[index];
                          final shortLabel = label.length > 3 ? label.substring(0, 3) : label;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              shortLabel,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyStats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stat = entry.value;
                      return FlSpot(
                        index.toDouble(),
                        selectedPeriod == 'expenses' ? stat.expenses : stat.income,
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.brandPrimary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: index == highlightedIndex ? 6 : 4,
                          color: index == highlightedIndex
                              ? AppColors.brandPrimary
                              : AppColors.brandPrimary.withOpacity(0.5),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brandPrimary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Highlighted Value
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '\$${highlightedValue.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms);
  }
}

class _HistoryItem extends StatelessWidget {
  final Transaction transaction;

  const _HistoryItem({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.amount < 0;
    final status = transaction.status.toLowerCase();
    final amountColor = isExpense
        ? AppColors.lightError
        : (isDark ? AppColors.darkSuccess : AppColors.lightSuccess);
    final title = _buildTitle();
    final subtitle = _buildSubtitle();
    final statusColor = _statusColor(status, isDark);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(_iconForTransaction(), color: AppColors.brandPrimary, size: 24),
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
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? '-' : '+'}${transaction.currency} ${transaction.amount.abs().toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  String _buildTitle() {
    final name = transaction.recipientName?.trim();
    final phone = transaction.recipientPhone?.trim();
    if (name != null && name.isNotEmpty) {
      return transaction.amount < 0 ? 'To $name' : 'From $name';
    }
    if (phone != null && phone.isNotEmpty) {
      return transaction.amount < 0 ? 'To $phone' : 'From $phone';
    }
    return _formatTransactionType();
  }

  String _buildSubtitle() {
    final type = _formatTransactionType();
    final date = DateFormat('dd MMM, yyyy').format(transaction.createdAt);
    return '$type • $date';
  }

  String _formatTransactionType() {
    final raw = (transaction.transType ?? transaction.type ?? '').toLowerCase();
    if (raw.contains('airtime') || raw.contains('airtopup')) return 'Airtime';
    if (raw.contains('data')) return 'Data Bundle';
    if (raw.contains('momo') || raw.contains('mobile')) return 'Mobile Money';
    if (raw.isEmpty) return 'Transfer';
    return raw
        .replaceAll(RegExp(r'[_-]'), ' ')
        .split(RegExp(r'\s+'))
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  IconData _iconForTransaction() {
    final raw = (transaction.transType ?? transaction.type ?? '').toLowerCase();
    if (raw.contains('airtime') || raw.contains('airtopup')) {
      return Icons.signal_cellular_alt_rounded;
    }
    if (raw.contains('data')) return Icons.wifi_rounded;
    if (raw.contains('momo') || raw.contains('mobile')) {
      return Icons.phone_android_rounded;
    }
    return Icons.swap_horiz_rounded;
  }

  Color _statusColor(String status, bool isDark) {
    if (status.contains('pending') || status.contains('processing')) {
      return AppColors.warning;
    }
    if (status.contains('fail') || status.contains('error')) {
      return AppColors.error;
    }
    return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
  }
}

class _OverviewCards extends StatelessWidget {
  final StatisticsData data;

  const _OverviewCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final netFlow = data.totalIncome - data.totalExpenses;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: cardWidth,
              child: _OverviewCard(
                title: 'Total Spent',
                amount: data.totalExpenses,
                icon: Icons.trending_down_rounded,
                accent: AppColors.error,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _OverviewCard(
                title: 'Total Income',
                amount: data.totalIncome,
                icon: Icons.trending_up_rounded,
                accent: AppColors.success,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _OverviewCard(
                title: 'Net Flow',
                amount: netFlow,
                icon: Icons.swap_vert_rounded,
                accent: netFlow >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color accent;

  const _OverviewCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat.compactCurrency(symbol: 'GHS ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(amount.abs()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
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

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(
            3,
            (index) => Container(
              width: cardWidth,
              height: 72,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryLoadingState extends StatelessWidget {
  const _HistoryLoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 72,
          margin: EdgeInsets.only(bottom: index < 2 ? AppSpacing.sm : 0),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No activity yet',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recent transactions will appear here once available.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
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
