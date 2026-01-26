import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../providers/rewards_provider.dart';
import '../../../../data/models/api_models.dart';

class RewardsHubScreen extends ConsumerWidget {
  const RewardsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointsAsync = ref.watch(userPointsProvider);
    final rewardsAsync = ref.watch(rewardsCatalogProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            ref.invalidate(userPointsProvider);
            ref.invalidate(rewardsCatalogProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _Header(pointsAsync: pointsAsync),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuickActions(pointsAsync: pointsAsync),
                      const SizedBox(height: AppSpacing.xl),
                      _RewardsSection(
                        pointsAsync: pointsAsync,
                        rewardsAsync: rewardsAsync,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _PerksSection(pointsAsync: pointsAsync),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AsyncValue<int> pointsAsync;

  const _Header({required this.pointsAsync});

  @override
  Widget build(BuildContext context) {
    final points = pointsAsync.valueOrNull ?? 0;
    final tier = _tierFor(points);
    final nextTier = _nextTierFor(points);
    final nextTarget = nextTier?.minPoints;
    final progress = nextTarget == null ? 1.0 : (points / nextTarget).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppBackButton(
                  onTap: () => context.pop(),
                  backgroundColor: Colors.white.withOpacity(0.18),
                  iconColor: Colors.white,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Rewards',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        tier.name,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pointsAsync.isLoading ? '—' : points.toString(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'points',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              nextTier == null
                  ? 'You’re at the top tier — enjoy all perks.'
                  : '${(nextTarget! - points).clamp(0, 1 << 30)} points to ${nextTier.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: pointsAsync.isLoading ? null : progress,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.22),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _QuickActions extends StatelessWidget {
  final AsyncValue<int> pointsAsync;

  const _QuickActions({required this.pointsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final chipWidth = (constraints.maxWidth - AppSpacing.sm) / 2;

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: chipWidth,
                  child: _ActionChip(
                    icon: Icons.bolt_rounded,
                    label: 'Earn',
                    onTap: () => _showComingSoon(context, 'Earn more points'),
                  ),
                ),
                SizedBox(
                  width: chipWidth,
                  child: _ActionChip(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Redeem',
                    onTap: () => _showComingSoon(context, 'Redeem rewards'),
                  ),
                ),
                SizedBox(
                  width: chipWidth,
                  child: _ActionChip(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: () => _showComingSoon(context, 'Rewards history'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06, end: 0);
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: border),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.xs,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardsSection extends StatelessWidget {
  final AsyncValue<int> pointsAsync;
  final AsyncValue<List<Reward>> rewardsAsync;

  const _RewardsSection({
    required this.pointsAsync,
    required this.rewardsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final points = pointsAsync.valueOrNull ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Redeemable rewards',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'From API',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.lightTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        rewardsAsync.when(
          loading: () => _loadingList(),
          error: (e, _) => _emptyState(
            context,
            title: 'Couldn’t load rewards',
            subtitle: 'Pull to refresh. We’ll keep the rest of Rewards working.',
          ),
          data: (rewards) {
            if (rewards.isEmpty) {
              return _emptyState(
                context,
                title: 'No rewards yet',
                subtitle: 'When rewards are added in the backend, they’ll show up here.',
              );
            }

            return Column(
              children: rewards.take(8).map((r) {
                final pointsRequired = (r.pointsRequired ?? r.pointsRequiredAlt ?? 0);
                final canRedeem = pointsRequired > 0 && points >= pointsRequired;
                final title = (r.title?.trim().isNotEmpty ?? false) ? r.title!.trim() : (r.name?.trim() ?? 'Reward');
                final desc = r.description?.trim().isNotEmpty == true
                    ? r.description!.trim()
                    : 'Redeem this reward with your points.';

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _RewardCard(
                    title: title,
                    description: desc,
                    pointsRequired: pointsRequired,
                    canRedeem: canRedeem,
                    onRedeem: () => _showComingSoon(context, 'Redeem “$title”'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 120.ms);
  }

  Widget _loadingList() {
    return Column(
      children: List.generate(
        3,
        (i) => Container(
          height: 92,
          margin: EdgeInsets.only(bottom: i == 2 ? 0 : AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, {required String title, required String subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String title;
  final String description;
  final int pointsRequired;
  final bool canRedeem;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.canRedeem,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: border),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        pointsRequired > 0 ? '$pointsRequired pts' : '—',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: canRedeem ? onRedeem : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canRedeem ? AppColors.primary : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: Text(canRedeem ? 'Redeem' : 'Need more'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerksSection extends StatelessWidget {
  final AsyncValue<int> pointsAsync;

  const _PerksSection({required this.pointsAsync});

  @override
  Widget build(BuildContext context) {
    final points = pointsAsync.valueOrNull ?? 0;
    final tier = _tierFor(points);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your perks',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: tier.gradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      '${tier.name} benefits',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _perkRow(context, icon: Icons.percent_rounded, text: 'Better promos and cashback boosts (rolling out)'),
              _perkRow(context, icon: Icons.flash_on_rounded, text: 'Faster checkout & smarter suggestions'),
              _perkRow(context, icon: Icons.security_rounded, text: 'Priority support (coming soon)'),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 160.ms);
  }

  Widget _perkRow(BuildContext context, {required IconData icon, required String text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature: coming soon.'),
      duration: const Duration(seconds: 2),
    ),
  );
}

class _Tier {
  final String name;
  final int minPoints;
  final LinearGradient gradient;

  const _Tier({required this.name, required this.minPoints, required this.gradient});
}

const List<_Tier> _tiers = [
  _Tier(
    name: 'Bronze',
    minPoints: 0,
    gradient: LinearGradient(colors: [Color(0xFFB45309), Color(0xFF92400E)]),
  ),
  _Tier(
    name: 'Silver',
    minPoints: 500,
    gradient: LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)]),
  ),
  _Tier(
    name: 'Gold',
    minPoints: 1500,
    gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
  ),
  _Tier(
    name: 'Platinum',
    minPoints: 4000,
    gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF2563EB)]),
  ),
];

_Tier _tierFor(int points) {
  var current = _tiers.first;
  for (final t in _tiers) {
    if (points >= t.minPoints) current = t;
  }
  return current;
}

_Tier? _nextTierFor(int points) {
  for (var i = 0; i < _tiers.length; i++) {
    if (points < _tiers[i].minPoints) {
      return _tiers[i];
    }
  }
  return null;
}


