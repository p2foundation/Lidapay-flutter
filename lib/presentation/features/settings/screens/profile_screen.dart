import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
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

              // Verification Status
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: (user?.isVerified == true
                                ? AppColors.lightSuccess
                                : AppColors.lightWarning)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        user?.isVerified == true
                            ? Icons.verified_rounded
                            : Icons.verified_user_outlined,
                        color: user?.isVerified == true
                            ? AppColors.lightSuccess
                            : AppColors.lightWarning,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user?.isVerified == true
                                ? 'Verified'
                                : 'Pending Verification',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (user?.isVerified != true)
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Start KYC verification
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: const Text('Verify'),
                      ),
                  ],
                ),
              ),
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
