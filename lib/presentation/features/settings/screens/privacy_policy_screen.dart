import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
            Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  AppBackButton(
                    onTap: () => context.pop(),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms),
            Expanded(
              child: Container(
                color: colorScheme.surface,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last updated: ${DateTime.now().year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '1. Information We Collect'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We collect information to provide better services to all our users. The types of information we collect include:\n'
                        '• Personal identification information (name, email, phone number)\n'
                        '• Financial information (for payment processing)\n'
                        '• Transaction data and history\n'
                        '• Device and usage information',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '2. How We Use Your Information'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We use the information we collect to:\n'
                        '• Provide and maintain our service\n'
                        '• Process transactions and send related information\n'
                        '• Communicate with you about your account\n'
                        '• Improve our services and develop new features\n'
                        '• Detect and prevent fraud',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '3. Information Sharing'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except:\n'
                        '• To comply with legal obligations\n'
                        '• To protect and defend our rights and property\n'
                        '• With service providers who assist in operating our service',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '4. Data Security'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '5. Your Rights'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'You have the right to:\n'
                        '• Access and update your personal information\n'
                        '• Request deletion of your account and data\n'
                        '• Opt-out of marketing communications\n'
                        '• Obtain a copy of your data',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '6. Contact Us'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'If you have any questions about this Privacy Policy, please contact us:\n'
                        'Email: info@advansistechnologies.com\n'
                        'Phone: 0244588584',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
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
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
