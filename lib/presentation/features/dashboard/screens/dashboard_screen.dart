import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/service_card.dart';
import '../../../../core/widgets/glassmorphic_card.dart';
import '../../../providers/wallet_provider.dart';
import '../../../providers/transaction_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasLoadedTransactions = false;

  @override
  void initState() {
    super.initState();
    // Status bar will be updated in build method based on theme
    // Load transactions only once on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoadedTransactions) {
        _hasLoadedTransactions = true;
        ref.read(transactionsNotifierProvider.notifier).loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsState = ref.watch(transactionsNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Update status bar based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(balanceProvider);
            ref.read(transactionsNotifierProvider.notifier).refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Header with Purple Gradient
                _buildHeader(context, ref),
                // Main Content
                Container(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Services
                        _buildQuickServices(context),
                        const SizedBox(height: AppSpacing.xl),
                        // Transaction Summary
                        _buildTransactionSummary(context, transactionsState, ref),
                        const SizedBox(height: AppSpacing.xl),
                        // Service Cards
                        _buildServiceCards(context),
                        const SizedBox(height: AppSpacing.xl),
                        // Special Offer Banner
                        _SpecialOfferBanner(),
                        const SizedBox(height: AppSpacing.xl),
                        // Recent Transactions
                        _buildRecentTransactions(context, transactionsState),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient, // Pink to Indigo (Brand Colors)
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo and Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lidapay',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Your Digital Financial Partner',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white),
                      onPressed: () => context.push('/search'),
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () => context.push('/notifications'),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Status Metrics
            _buildStatusMetrics(context, ref),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildStatusMetrics(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsNotifierProvider);
    
    // Calculate statistics from transactions
    final transactions = transactionsState.transactions;
    final totalTransactions = transactionsState.total > 0 ? transactionsState.total : transactions.length;
    final totalAirtime = transactions
        .where((t) => (t.transType?.toLowerCase() ?? t.type?.toLowerCase() ?? '').contains('airtime') || 
                      (t.transType?.toLowerCase() ?? '').contains('momo'))
        .fold<double>(0, (sum, t) => sum + t.amount.abs());
    final totalData = transactions
        .where((t) => (t.transType?.toLowerCase() ?? t.type?.toLowerCase() ?? '').contains('data'))
        .fold<double>(0, (sum, t) => sum + t.amount.abs());
    final totalSent = transactions
        .where((t) => t.amount < 0)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());
    final totalReceived = transactions
        .where((t) => t.amount > 0)
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Show loading only on initial load
    if (transactionsState.isLoading && transactions.isEmpty) {
      return SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: List.generate(5, (index) => Container(
            width: 80,
            margin: EdgeInsets.only(right: index < 4 ? AppSpacing.sm : 0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
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

    // Show actual statistics
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatusMetricItem(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
            value: totalTransactions.toString(),
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusMetricItem(
            icon: Icons.phone_android_rounded,
            label: 'Airtime',
            value: 'GHS ${totalAirtime.toStringAsFixed(0)}',
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusMetricItem(
            icon: Icons.wifi_rounded,
            label: 'Data',
            value: 'GHS ${totalData.toStringAsFixed(0)}',
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusMetricItem(
            icon: Icons.trending_up_rounded,
            label: 'Sent',
            value: 'GHS ${totalSent.toStringAsFixed(0)}',
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusMetricItem(
            icon: Icons.trending_down_rounded,
            label: 'Received',
            value: 'GHS ${totalReceived.toStringAsFixed(0)}',
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Quick Services',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            GestureDetector(
              onTap: () => context.push('/airtime'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Air Menu',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ServiceCard(
                icon: Icons.signal_cellular_alt_rounded,
                title: 'Airtime',
                gradient: AppColors.primaryGradient,
                isCompact: true,
                isPopular: true,
                onTap: () => context.push('/airtime/select-country'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ServiceCard(
                icon: Icons.wifi_rounded,
                title: 'Data',
                gradient: AppColors.secondaryGradient,
                isCompact: true,
                onTap: () => context.push('/data/select-country'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ServiceCard(
                icon: Icons.swap_horiz_rounded,
                title: 'Convert',
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                isCompact: true,
                isNew: true,
                onTap: () => context.push('/airtime'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ServiceCard(
                icon: Icons.receipt_long_rounded,
                title: 'Bills',
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                isCompact: true,
                onTap: () => context.push('/airtime'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ServiceCard(
                icon: Icons.more_horiz_rounded,
                title: 'More',
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                isCompact: true,
                onTap: () => context.push('/airtime'),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildTransactionSummary(BuildContext context, TransactionsState transactionsState, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = transactionsState.transactions;
    final pendingCount = transactions.where((t) => t.status.toLowerCase() == 'pending').length;
    final completedCount = transactions.where((t) => t.status.toLowerCase() == 'completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              onPressed: () {
                ref.read(transactionsNotifierProvider.notifier).refresh();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _TransactionSummaryCard(
                icon: Icons.access_time_rounded,
                title: 'Pending Transactions',
                count: pendingCount,
                gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
                onTap: () => context.push('/transactions?filter=pending'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _TransactionSummaryCard(
                icon: Icons.check_circle_rounded,
                title: 'Completed Transactions',
                count: completedCount,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                onTap: () => context.push('/transactions?filter=completed'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildServiceCards(BuildContext context) {
    return Column(
      children: [
        _ServiceCard(
          icon: Icons.signal_cellular_alt_rounded,
          title: 'Buy Airtime',
          subtitle: 'Top up any phone number worldwide',
          gradient: AppColors.primaryGradient, // Pink/Magenta
          onTap: () => context.push('/airtime/select-country'),
        ),
        const SizedBox(height: AppSpacing.md),
        _ServiceCard(
          icon: Icons.wifi_rounded,
          title: 'Internet Data',
          subtitle: 'High-speed data bundles for all networks',
          gradient: AppColors.brandGradient, // Pink to Indigo
          onTap: () => context.push('/data/select-country'),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRecentTransactions(BuildContext context, TransactionsState transactionsState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = transactionsState.transactions;
    
    if (transactionsState.isLoading && transactions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }
    
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions'),
              child: Text(
                'See All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...transactions.take(5).map((t) => InkWell(
          onTap: () => context.push('/transactions/${t.id}', extra: t),
          child: _TransactionItem(transaction: t),
        )),
      ],
    );
  }
}

// ============================================================================
// QUICK SERVICE CARD
// ============================================================================
class _QuickServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickServiceCard({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, // Increased width
        constraints: const BoxConstraints(
          minHeight: 120, // Minimum height to prevent overflow
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, // Larger icon container
              height: 64, // Larger icon container
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 32), // Larger icon
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TRANSACTION SUMMARY CARD
// ============================================================================
class _TransactionSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _TransactionSummaryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SERVICE CARD
// ============================================================================
class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.lightTextSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded, 
              size: 18, 
              color: isDark 
                  ? AppColors.darkTextMuted 
                  : AppColors.lightTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SPECIAL OFFER BANNER
// ============================================================================
class _SpecialOfferBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient, // Pink to Indigo (Brand Colors)
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'SPECIAL OFFER',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Get 10% Cashback',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'On your first airtime purchase',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_horiz_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TRANSACTION ITEM
// ============================================================================
class _TransactionItem extends StatelessWidget {
  final dynamic transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = transaction.amount < 0;
    final status = transaction.status?.toLowerCase() ?? 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isExpense ? AppColors.error : AppColors.success).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isExpense ? AppColors.error : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.recipientName ?? 'Transaction',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(transaction.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark 
                            ? AppColors.darkTextMuted 
                            : AppColors.lightTextMuted,
                      ),
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
                      color: isExpense ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'completed' 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: status == 'completed' ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================================
// STATUS METRIC ITEM
// ============================================================================
class _StatusMetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatusMetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 8),
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
                  fontSize: 12,
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
                  fontSize: 9,
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
