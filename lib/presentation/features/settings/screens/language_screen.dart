import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/currency_provider.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final l10n = AppLocalizations.of(context)!;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        '${l10n.language} & ${l10n.settings}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: l10n.language),
                    Tab(text: l10n.currency),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLanguageTab(),
                _buildCurrencyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.chooseLanguage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...AppLocalizations.languages.map((lang) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LangTile(
                flag: lang.flag,
                title: lang.nativeName,
                subtitle: lang.name,
                value: lang.code,
                groupValue: currentLocale.languageCode,
                onChanged: (v) {
                  final locale = Locale(v);
                  ref.read(localeProvider.notifier).setLocale(locale);
                  final selectedLang = AppLocalizations.languages.firstWhere((l) => l.code == v);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${selectedLang.nativeName}'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCurrencyTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final currentCurrency = ref.watch(currencyProvider);
    final currencyNotifier = ref.read(currencyProvider.notifier);

    final currencies = [
      {'code': 'USD', 'name': 'US Dollar', 'symbol': r'$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
      {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
      {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
      {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
      {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': r'C$'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': r'A$'},
    ];

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Choose your preferred currency',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: secondaryText),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...currencies.map((currency) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _CurrencyTile(
                code: currency['code']!,
                name: currency['name']!,
                symbol: currency['symbol']!,
                value: currency['code']!,
                groupValue: currentCurrency,
                onChanged: (v) {
                  currencyNotifier.setCurrency(v);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Currency changed to $v'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _LangTile({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
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
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: enabled ? (v) => onChanged(v!) : null,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0);
  }
}

class _CurrencyTile extends StatelessWidget {
  final String code;
  final String name;
  final String symbol;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const _CurrencyTile({
    required this.code,
    required this.name,
    required this.symbol,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
              child: Center(
                child: Text(
                  symbol,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: enabled ? (v) => onChanged(v!) : null,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0);
  }
}
