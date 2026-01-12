import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/wallet_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final balanceAsync = ref.watch(balanceProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    String themeModeLabel(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'System';
      }
    }

    String themeModeKey(ThemeMode mode) {
      switch (mode) {
        case ThemeMode.light:
          return 'light';
        case ThemeMode.dark:
          return 'dark';
        case ThemeMode.system:
          return 'system';
      }
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Hero Header with Gradient
            _buildHeader(context, userAsync, balanceAsync),
            // Main Content
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(currentUserProvider);
                    ref.invalidate(balanceProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Section
                        _SettingsSection(
                          title: 'Account',
                          items: [
                            _SettingsItem(
                              icon: Icons.person_rounded,
                              title: 'Profile',
                              subtitle: 'View and edit your profile',
                              gradient: AppColors.primaryGradient,
                              onTap: () => context.push('/profile'),
                            ),
                            _SettingsItem(
                              icon: Icons.lock_rounded,
                              title: 'Change Password',
                              subtitle: 'Update your account password',
                              gradient: AppColors.secondaryGradient,
                              onTap: () => context.push('/change-password'),
                            ),
                            _SettingsItem(
                              icon: Icons.verified_user_rounded,
                              title: 'KYC Verification',
                              subtitle: 'Pending',
                              badgeColor: AppColors.warning,
                              gradient: AppColors.warningGradient,
                              onTap: () => context.push('/kyc'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Payment Section
                        _SettingsSection(
                          title: 'Payment',
                          items: [
                            _SettingsItem(
                              icon: Icons.credit_card_rounded,
                              title: 'Payment Methods',
                              subtitle: 'Manage payment methods',
                              gradient: AppColors.primaryGradient,
                              onTap: () => context.push('/payment-methods'),
                            ),
                            _SettingsItem(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Wallet',
                              subtitle: 'View wallet details',
                              gradient: AppColors.secondaryGradient,
                              onTap: () => context.push('/wallet'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Preferences Section
                        _SettingsSection(
                          title: 'Preferences',
                          items: [
                            _SettingsItem(
                              icon: Icons.notifications_rounded,
                              title: 'Notifications',
                              trailing: Switch(
                                value: true,
                                onChanged: (_) {},
                                activeColor: AppColors.brandPrimary,
                              ),
                              gradient: AppColors.primaryGradient,
                            ),
                            _SettingsItem(
                              icon: Icons.palette_rounded,
                              title: 'Appearance',
                              subtitle: themeModeLabel(themeMode),
                              gradient: AppColors.secondaryGradient,
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (sheetContext) {
                                    final modes = <ThemeMode>[
                                      ThemeMode.light,
                                      ThemeMode.dark,
                                      ThemeMode.system,
                                    ];

                                    return SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.lg,
                                              vertical: AppSpacing.md,
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Theme',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          ...modes.map((mode) {
                                            return ListTile(
                                              title: Text(themeModeLabel(mode)),
                                              leading: Radio<ThemeMode>(
                                                value: mode,
                                                groupValue: themeMode,
                                                onChanged: (value) {
                                                  if (value == null) return;
                                                  ref
                                                      .read(themeModeProvider.notifier)
                                                      .state = value;
                                                  prefs.setString(
                                                    AppConstants.themeModeKey,
                                                    themeModeKey(value),
                                                  );
                                                  Navigator.of(sheetContext).pop();
                                                },
                                              ),
                                              onTap: () {
                                                ref
                                                    .read(themeModeProvider.notifier)
                                                    .state = mode;
                                                prefs.setString(
                                                  AppConstants.themeModeKey,
                                                  themeModeKey(mode),
                                                );
                                                Navigator.of(sheetContext).pop();
                                              },
                                            );
                                          }),
                                          const SizedBox(height: AppSpacing.md),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            _SettingsItem(
                              icon: Icons.language_rounded,
                              title: 'Language',
                              subtitle: 'English',
                              gradient: AppColors.brandGradient,
                              onTap: () => context.push('/language'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Support Section
                        _SettingsSection(
                          title: 'Support',
                          items: [
                            _SettingsItem(
                              icon: Icons.help_outline_rounded,
                              title: 'Help Center',
                              subtitle: 'Get help and support',
                              gradient: AppColors.primaryGradient,
                              onTap: () => context.push('/help-center'),
                            ),
                            _SettingsItem(
                              icon: Icons.info_outline_rounded,
                              title: 'About',
                              subtitle: 'App version and info',
                              gradient: AppColors.secondaryGradient,
                              onTap: () => context.push('/about'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxxl),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              final authNotifier = ref.read(authStateProvider.notifier);
                              await authNotifier.logout();
                              if (context.mounted) {
                                context.go('/login');
                              }
                              ref.invalidate(currentUserProvider);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            child: Text(
                              'Logout',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue userAsync, AsyncValue balanceAsync) {
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                Expanded(
                  child: Text(
                    'Account',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Profile Card
            userAsync.when(
              data: (user) => _ProfileHeaderCard(user: user, balanceAsync: balanceAsync),
              loading: () => const _ProfileHeaderCardShimmer(),
              error: (_, __) => const _ProfileHeaderCardError(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ============================================================================
// PROFILE HEADER CARD
// ============================================================================
class _ProfileHeaderCard extends StatelessWidget {
  final dynamic user;
  final AsyncValue balanceAsync;

  const _ProfileHeaderCard({
    required this.user,
    required this.balanceAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: AppShadows.glow(Colors.white, opacity: 0.3),
            ),
            child: ClipOval(
              child: user?.email != null && user!.email!.isNotEmpty
                  ? Image.network(
                      Gravatar(user.email!).imageUrl(),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to initials if Gravatar fails
                        return Center(
                          child: Text(
                            user?.firstName?[0].toUpperCase() ??
                                user?.lastName?[0].toUpperCase() ??
                                'U',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        user?.firstName?[0].toUpperCase() ??
                            user?.lastName?[0].toUpperCase() ??
                            'U',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  user?.phoneNumber ?? user?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          balanceAsync.when(
            data: (balance) => Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Balance',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                  Text(
                    'GHS ${balance.balance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCardShimmer extends StatelessWidget {
  const _ProfileHeaderCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    );
  }
}

class _ProfileHeaderCardError extends StatelessWidget {
  const _ProfileHeaderCardError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Error loading profile',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SETTINGS SECTION
// ============================================================================
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}

// ============================================================================
// SETTINGS ITEM
// ============================================================================
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? badgeColor;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badgeColor,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
