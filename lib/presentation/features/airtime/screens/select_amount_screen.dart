import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/airtime_wizard_provider.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/country_flag_widget.dart';

class SelectAmountScreen extends ConsumerStatefulWidget {
  const SelectAmountScreen({super.key});

  @override
  ConsumerState<SelectAmountScreen> createState() => _SelectAmountScreenState();
}

class _SelectAmountScreenState extends ConsumerState<SelectAmountScreen> {
  final _amountController = TextEditingController();
  double? _selectedPreset;
  bool _showAllAmounts = false;
  static const int _initialAmountCount = 12;

  @override
  void initState() {
    super.initState();
    final wizardState = ref.read(airtimeWizardProvider);
    if (wizardState.selectedAmount != null) {
      _amountController.text = wizardState.selectedAmount!.toStringAsFixed(0);
      _selectedPreset = wizardState.selectedAmount;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  List<double> _getSuggestedAmounts(AutodetectData? operatorData) {
    if (operatorData == null) {
      return [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
    }

    // Use suggestedAmounts from API if available
    if (operatorData.suggestedAmounts != null && operatorData.suggestedAmounts!.isNotEmpty) {
      return operatorData.suggestedAmounts!;
    }
    
    // Fallback to suggestedAmountsMap if available
    if (operatorData.suggestedAmountsMap != null && operatorData.suggestedAmountsMap!.isNotEmpty) {
      return operatorData.suggestedAmountsMap!;
    }

    // Generate fallback amounts based on min/max
    final min = operatorData.localMinAmount ?? operatorData.minAmount;
    final max = operatorData.localMaxAmount ?? operatorData.maxAmount;
    final popular = operatorData.mostPopularLocalAmount ?? operatorData.mostPopularAmount;

    final amounts = <double>[];
    
    // Add popular amount if available
    if (popular != null && popular >= min && popular <= max) {
      amounts.add(popular);
    }

    // Generate amounts based on min/max
    if (min < 10) {
      amounts.addAll([1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100]);
    } else {
      final step = (max - min) / 15;
      for (int i = 0; i <= 15; i++) {
        final amount = (min + (step * i)).roundToDouble();
        if (amount <= max) amounts.add(amount);
      }
    }

    // Remove duplicates and sort
    final uniqueAmounts = amounts.toSet().toList();
    uniqueAmounts.removeWhere((a) => a < min || a > max);
    uniqueAmounts.sort();
    
    return uniqueAmounts;
  }
  
  List<double> _getDisplayAmounts(List<double> allAmounts) {
    if (_showAllAmounts || allAmounts.length <= _initialAmountCount) {
      return allAmounts;
    }
    return allAmounts.sublist(0, _initialAmountCount);
  }

  void _selectPreset(double amount) {
    final wizardState = ref.read(airtimeWizardProvider);
    final operatorData = wizardState.operatorData;
    
    if (operatorData != null) {
      final minAmount = operatorData.minAmount;
      final maxAmount = operatorData.maxAmount;
      final senderSymbol = operatorData.senderCurrencySymbol;
      
      if (amount >= minAmount && amount <= maxAmount) {
        setState(() {
          _selectedPreset = amount;
          _amountController.text = amount.toStringAsFixed(0);
        });
        ref.read(airtimeWizardProvider.notifier).setAmount(amount);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Amount must be between $senderSymbol${minAmount.toStringAsFixed(0)} and $senderSymbol${maxAmount.toStringAsFixed(0)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      setState(() {
        _selectedPreset = amount;
        _amountController.text = amount.toStringAsFixed(0);
      });
      ref.read(airtimeWizardProvider.notifier).setAmount(amount);
    }
  }

  void _continue() {
    final amount = double.tryParse(_amountController.text);
    final wizardState = ref.read(airtimeWizardProvider);
    final operatorData = wizardState.operatorData;
    
    if (amount != null && amount > 0 && operatorData != null) {
      final minAmount = operatorData.minAmount;
      final maxAmount = operatorData.maxAmount;
      final senderSymbol = operatorData.senderCurrencySymbol;
      
      if (amount >= minAmount && amount <= maxAmount) {
        context.push('/airtime/confirm-airtime');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Amount must be between $senderSymbol${minAmount.toStringAsFixed(0)} and $senderSymbol${maxAmount.toStringAsFixed(0)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wizardState = ref.watch(airtimeWizardProvider);
    final operatorData = wizardState.operatorData;
    final selectedCountry = wizardState.selectedCountry;

    if (operatorData == null || selectedCountry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    final quickAmounts = _getSuggestedAmounts(operatorData);
    final amount = double.tryParse(_amountController.text);
    
    // Use suggestedAmounts min/max (sender currency) if available, otherwise fall back to operator limits
    final minAmount = quickAmounts.isNotEmpty ? quickAmounts.first : operatorData.minAmount;
    final maxAmount = quickAmounts.isNotEmpty ? quickAmounts.last : operatorData.maxAmount;
    
    final canContinue = amount != null && amount >= minAmount && amount <= maxAmount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressIndicator(context, 3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose the amount to recharge',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAmountInput(context, operatorData, minAmount, maxAmount, amount),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickAmounts(context, quickAmounts, operatorData),
                    const SizedBox(height: AppSpacing.md),
                    _buildNetworkInfo(context, selectedCountry, operatorData),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(context, canContinue),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AppBackButton(
            onTap: () => context.pop(),
            backgroundColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.white,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Select Amount',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStep) {
    final steps = ['Country', 'Network', 'Phone', 'Amount', 'Confirm'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: stepBefore < currentStep
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;

          return Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? AppColors.primary
                      : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 2,
                  ),
                  boxShadow: isCurrent ? AppShadows.softGlow(AppColors.primary) : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[stepIndex],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isCurrent
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context, AutodetectData operatorData, double minAmount, double maxAmount, double? amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wizardState = ref.read(airtimeWizardProvider);
    final selectedCountry = wizardState.selectedCountry;
    
    // Use Ghana Cedis for Ghana, otherwise use sender currency
    final currencySymbol = CurrencyFormatter.isGhana(selectedCountry) ? 'GHS' : operatorData.senderCurrencySymbol;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter amount',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            onChanged: (value) {
              final parsed = double.tryParse(value);
              if (parsed != null) {
                setState(() {
                  _selectedPreset = null;
                });
                ref.read(airtimeWizardProvider.notifier).setAmount(parsed);
              }
            },
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              prefixText: currencySymbol,
              prefixStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Min: $currencySymbol${minAmount.toStringAsFixed(0)} • Max: $currencySymbol${maxAmount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
          ),
          if (amount != null && amount > 0 && operatorData.fx != null && !CurrencyFormatter.isGhana(selectedCountry)) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'You will pay ${(operatorData.fx!['currencyCode'] as String? ?? 'GHS')}${(amount * (operatorData.fx!['rate'] as double? ?? 1.0)).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickAmounts(BuildContext context, List<double> allAmounts, AutodetectData operatorData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayAmounts = _getDisplayAmounts(allAmounts);
    final hasMoreAmounts = allAmounts.length > _initialAmountCount;
    final wizardState = ref.read(airtimeWizardProvider);
    final selectedCountry = wizardState.selectedCountry;
    
    // Use Ghana Cedis for Ghana, otherwise use sender currency code
    final currencyCode = CurrencyFormatter.isGhana(selectedCountry) ? 'GHS' : operatorData.senderCurrencyCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Amounts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (hasMoreAmounts)
              Text(
                '${allAmounts.length} options',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: displayAmounts.map((amount) {
            final isSelected = _selectedPreset == amount;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _selectPreset(amount);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? AppShadows.softGlow(AppColors.primary) : null,
                ),
                child: Text(
                  '$currencyCode ${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkText : AppColors.lightText),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
        if (hasMoreAmounts) ...[  
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showAllAmounts = !_showAllAmounts;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAllAmounts ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showAllAmounts ? 'Show less' : 'Show more (${allAmounts.length - _initialAmountCount} more)',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildNetworkInfo(BuildContext context, Country selectedCountry, AutodetectData operatorData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Operator Logo or Country Flag as fallback
          operatorData.logoUrl != null && operatorData.logoUrl!.isNotEmpty
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.network(
                      operatorData.logoUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to country flag if logo fails
                        return CountryFlagWidget(
                          flagUrl: selectedCountry.flag,
                          countryCode: selectedCountry.code,
                          size: 32,
                        );
                      },
                    ),
                  ),
                )
              : CountryFlagWidget(
                  flagUrl: selectedCountry.flag,
                  countryCode: selectedCountry.code,
                  size: 32,
                ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${operatorData.name} • ${selectedCountry.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context, bool canContinue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('PREVIOUS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canContinue ? _continue : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('NEXT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canContinue ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                foregroundColor: canContinue ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                disabledBackgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

