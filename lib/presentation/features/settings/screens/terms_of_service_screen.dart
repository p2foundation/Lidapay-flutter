import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Terms of Service',
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
                      _SectionTitle(title: '1. Acceptance of Terms'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'By downloading, installing, or using LidaPay, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '2. Description of Service'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'LidaPay is a digital payment platform that enables users to send money, pay bills, purchase airtime, and perform various financial transactions through mobile devices.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '3. User Responsibilities'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'You are responsible for:\n'
                        '• Maintaining the confidentiality of your account credentials\n'
                        '• All activities that occur under your account\n'
                        '• Providing accurate and complete information\n'
                        '• Notifying us immediately of any unauthorized use',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '4. Privacy and Data Protection'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service, to understand our practices.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '5. Prohibited Activities'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'You agree not to:\n'
                        '• Use the service for any illegal or unauthorized purpose\n'
                        '• Engage in fraudulent activities\n'
                        '• Attempt to gain unauthorized access to our systems\n'
                        '• Interfere with or disrupt the service',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '6. Limitation of Liability'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'LidaPay shall not be liable for any indirect, incidental, special, or consequential damages resulting from your use of the service.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: secondaryText),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionTitle(title: '7. Contact Information'),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'For questions about these Terms of Service, please contact us at:\n'
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
