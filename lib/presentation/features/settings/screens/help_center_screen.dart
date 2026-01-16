import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(phoneUri)) {
      throw Exception('Could not launch $phoneUri');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=LidaPay Support Request',
    );
    if (!await launchUrl(emailUri)) {
      throw Exception('Could not launch $emailUri');
    }
  }

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
                      'Help Center',
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
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Text(
                      'Quick answers and support options.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: secondaryText),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _FaqTile(
                      question: 'How do I reset my password?',
                      answer: 'Use "Forgot Password" on the login screen to request a reset link via email.',
                      gradient: AppColors.primaryGradient,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FaqTile(
                      question: 'Why are my transactions not loading?',
                      answer: 'Check your internet connection. If the issue persists, the app will show a safe fallback and you can retry.',
                      gradient: AppColors.secondaryGradient,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FaqTile(
                      question: 'How do I add a payment method?',
                      answer: 'Go to Settings > Payment Methods to add and manage your payment options including mobile money and cards.',
                      gradient: AppColors.primaryGradient,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FaqTile(
                      question: 'Is my financial information secure?',
                      answer: 'Yes, LidaPay uses industry-standard encryption to protect your data and transactions.',
                      gradient: AppColors.secondaryGradient,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FaqTile(
                      question: 'How do I contact customer support?',
                      answer: 'Reach us via phone at 0244588584 or email at info@advansistechnologies.com for immediate assistance.',
                      gradient: AppColors.primaryGradient,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Contact Support',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ContactTile(
                      icon: Icons.phone_rounded,
                      title: 'Call Us',
                      subtitle: '0244588584',
                      gradient: AppColors.primaryGradient,
                      onTap: () => _launchPhone('0244588584'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ContactTile(
                      icon: Icons.email_rounded,
                      title: 'Email Us',
                      subtitle: 'info@advansistechnologies.com',
                      gradient: AppColors.secondaryGradient,
                      onTap: () => _launchEmail('info@advansistechnologies.com'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final LinearGradient gradient;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(Icons.question_answer_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(answer, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0);
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, 
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ],
        ),
      ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08, end: 0),
    );
  }
}


