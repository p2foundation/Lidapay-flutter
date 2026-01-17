import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../../data/models/api_models.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        primary: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: AppBackButton(
          onTap: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              userAsync.whenData((user) {
                if (user != null) {
                  context.push('/edit-profile', extra: user);
                }
              });
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Profile Picture Section
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.lg + AppShadows.glow(AppColors.brandPrimary),
                    ),
                    child: ClipOval(
                      child: user?.email != null && user!.email!.isNotEmpty
                          ? Image.network(
                              Gravatar(user.email!).imageUrl(),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to initials if Gravatar fails
                                return Center(
                                  child: Text(
                                    user?.firstName?[0].toUpperCase() ??
                                        user?.lastName?[0].toUpperCase() ??
                                        'U',
                                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.md,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.brandPrimary,
                          size: 20,
                        ),
                        onPressed: () {
                          // TODO: Change profile picture
                        },
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms),
              const SizedBox(height: AppSpacing.lg),
              // User Name
              Text(
                '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                user?.email ?? user?.phoneNumber ?? '',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // User Info Section
              _InfoSection(
                title: 'Personal Information',
                items: [
                  _InfoItem(
                    icon: Icons.person_rounded,
                    label: 'First Name',
                    value: user?.firstName ?? 'Not set',
                    onEdit: () {
                      context.push('/edit-profile', extra: user);
                    },
                  ),
                  _InfoItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Last Name',
                    value: user?.lastName ?? 'Not set',
                    onEdit: () {
                      context.push('/edit-profile', extra: user);
                    },
                  ),
                  _InfoItem(
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: user?.phoneNumber ?? 'Not set',
                    onEdit: () {
                      context.push('/edit-profile', extra: user);
                    },
                  ),
                  _InfoItem(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: user?.email ?? 'Not set',
                    onEdit: () {
                      context.push('/edit-profile', extra: user);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Verification Status Section
              _VerificationSection(user: user),
              const SizedBox(height: AppSpacing.lg),

              // Points Display
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.glow(AppColors.brandPrimary, opacity: 0.22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: Colors.white.withOpacity(0.22)),
                      ),
                      child: const Icon(
                        Icons.stars_rounded,
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
                            'Reward Points',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${user?.points ?? 0} points',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                      onPressed: () => context.push('/rewards'),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(delay: 300.ms),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.lightError),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error loading profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationSection extends StatelessWidget {
  final User? user;

  const _VerificationSection({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emailVerified = user?.emailVerified ?? false;
    final phoneVerified = user?.phoneVerified ?? false;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Email Verification
          _VerificationItem(
            icon: Icons.email_rounded,
            title: 'Email Verification',
            subtitle: emailVerified ? 'Verified' : 'Not verified',
            isVerified: emailVerified,
            points: '50 points',
            onTap: emailVerified ? null : () => context.push('/email-verification'),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Phone Verification
          _VerificationItem(
            icon: Icons.phone_rounded,
            title: 'Phone Verification',
            subtitle: phoneVerified ? 'Verified' : 'Not verified',
            isVerified: phoneVerified,
            points: '75 points',
            onTap: phoneVerified ? null : () => context.push('/phone-verification'),
          ),
          
          if (!emailVerified || !phoneVerified) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, 
                    size: 20, 
                    color: AppColors.brandPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Complete verifications to earn rewards and unlock all features!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0);
  }
}

class _VerificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isVerified;
  final String points;
  final VoidCallback? onTap;

  const _VerificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isVerified,
    required this.points,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isVerified 
              ? AppColors.lightSuccess.withOpacity(0.1)
              : onTap != null 
                  ? AppColors.brandPrimary.withOpacity(0.05)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isVerified 
                ? AppColors.lightSuccess.withOpacity(0.3)
                : onTap != null
                    ? AppColors.brandPrimary.withOpacity(0.2)
                    : AppColors.darkBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isVerified 
                    ? AppColors.lightSuccess.withOpacity(0.2)
                    : onTap != null
                        ? AppColors.brandPrimary.withOpacity(0.1)
                        : AppColors.darkBorder.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                color: isVerified 
                    ? AppColors.lightSuccess
                    : onTap != null
                        ? AppColors.brandPrimary
                        : isDark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.lightTextSecondary,
                size: 20,
              ),
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
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isVerified 
                              ? AppColors.lightSuccess
                              : isDark 
                                  ? AppColors.darkTextSecondary 
                                  : AppColors.lightTextSecondary,
                        ),
                      ),
                      if (!isVerified && onTap != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            '+$points',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isVerified)
              Icon(
                Icons.verified_rounded,
                color: AppColors.lightSuccess,
                size: 20,
              )
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: isDark 
                    ? AppColors.darkTextSecondary 
                    : AppColors.lightTextSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _InfoSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
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
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: AppColors.brandPrimary, size: 20),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      trailing: onEdit != null
          ? IconButton(
              icon: Icon(
                Icons.edit_rounded,
                size: 20,
                color: AppColors.brandPrimary,
              ),
              onPressed: onEdit,
            )
          : null,
    );
  }
}
