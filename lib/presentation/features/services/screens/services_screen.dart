import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/service_card.dart';
import '../../../../core/widgets/glassmorphic_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _selectedCategory = 0;
  final List<String> _categories = ['All', 'Mobile', 'Finance', 'Utilities', 'More'];

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(context),
                    const SizedBox(height: AppSpacing.xl),
                    // Categories
                    _buildCategories(context),
                    const SizedBox(height: AppSpacing.xl),
                    // Featured Services
                    _buildFeaturedServices(context),
                    const SizedBox(height: AppSpacing.xl),
                    // All Services
                    _buildAllServices(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AppBackButton(
            onTap: () => context.pop(),
            backgroundColor: colorScheme.surface,
            boxShadow: AppShadows.xs,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Services',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: AppShadows.xs,
            ),
            child: const Icon(Icons.tune_rounded, size: 22),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: TextStyle(color: mutedText),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(Icons.search_rounded, color: mutedText),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCategories(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          final isSelected = entry.key == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: isSelected ? AppShadows.softGlow(AppColors.primary) : AppShadows.xs,
                ),
                child: Text(
                  entry.value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected ? Colors.white : secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildFeaturedServices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Special',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: HeroServiceCard(
                icon: Icons.signal_cellular_alt_rounded,
                title: 'Buy Airtime',
                subtitle: 'Instant top-up worldwide',
                gradient: AppColors.primaryGradient,
                promoText: 'Popular',
                onTap: () => context.push('/airtime/select-country'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: HeroServiceCard(
                icon: Icons.wifi_rounded,
                title: 'Data Bundles',
                subtitle: 'High-speed internet',
                gradient: AppColors.secondaryGradient,
                onTap: () => context.push('/data/select-country'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildAllServices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Services',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        ServiceCard(
          icon: Icons.signal_cellular_alt_rounded,
          title: 'International Airtime',
          subtitle: 'Send airtime to 150+ countries',
          gradient: AppColors.primaryGradient,
          isPopular: true,
          onTap: () => context.push('/airtime/select-country'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ServiceCard(
          icon: Icons.wifi_rounded,
          title: 'Data Bundles',
          subtitle: 'High-speed internet packages',
          gradient: AppColors.secondaryGradient,
          onTap: () => context.push('/data/select-country'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ServiceCard(
          icon: Icons.swap_horiz_rounded,
          title: 'Airtime Convert',
          subtitle: 'Convert airtime to cash',
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          isNew: true,
          onTap: () => context.push('/airtime'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ServiceCard(
          icon: Icons.bolt_rounded,
          title: 'Electricity Bills',
          subtitle: 'Pay ECG, NEDCO and more',
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          onTap: () => context.push('/airtime'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ServiceCard(
          icon: Icons.tv_rounded,
          title: 'TV Subscription',
          subtitle: 'DSTV, GOtv, StarTimes',
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          ),
          onTap: () => context.push('/airtime'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ServiceCard(
          icon: Icons.water_drop_rounded,
          title: 'Water Bills',
          subtitle: 'Pay water utility bills',
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
          ),
          onTap: () => context.push('/airtime'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ServiceCard(
          icon: Icons.workspace_premium_rounded,
          title: 'Rewards & Points',
          subtitle: 'Earn points and redeem perks',
          gradient: AppColors.brandGradient,
          isNew: true,
          onTap: () => context.push('/rewards'),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _FeaturedCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 26),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedText,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
