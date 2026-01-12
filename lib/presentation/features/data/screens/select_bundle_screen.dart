import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/data_wizard_provider.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';

class SelectBundleScreen extends ConsumerStatefulWidget {
  const SelectBundleScreen({super.key});

  @override
  ConsumerState<SelectBundleScreen> createState() => _SelectBundleScreenState();
}

class _SelectBundleScreenState extends ConsumerState<SelectBundleScreen> {
  DataOperator? _selectedOperator;
  bool _showAllBundles = false;
  static const int _initialBundleCount = 5;

  @override
  void initState() {
    super.initState();
    final wizardState = ref.read(dataWizardProvider);
    _selectedOperator = wizardState.selectedOperator;
    
    // Auto-select if only one operator (delayed to avoid modifying provider during build)
    if (wizardState.availableOperators != null && 
        wizardState.availableOperators!.length == 1 &&
        _selectedOperator == null) {
      _selectedOperator = wizardState.availableOperators!.first;
      // Delay provider modification to after widget tree is built
      Future(() {
        if (mounted) {
          ref.read(dataWizardProvider.notifier).selectOperator(_selectedOperator!);
        }
      });
    }
  }

  void _selectOperator(DataOperator operator) {
    setState(() {
      _selectedOperator = operator;
    });
    ref.read(dataWizardProvider.notifier).selectOperator(operator);
  }

  void _selectBundle(DataBundle bundle) {
    ref.read(dataWizardProvider.notifier).selectBundle(bundle);
    setState(() {}); // Update UI to show selection
  }

  void _continue() {
    final wizardState = ref.read(dataWizardProvider);
    if (wizardState.selectedBundle != null) {
      context.push('/data/confirm');
    }
  }

  List<DataBundle> _generateBundles(DataOperator operator) {
    // Generate sample bundles based on operator
    // In production, these would come from an API endpoint
    return [
      DataBundle(
        id: 1,
        name: '${operator.name} Data',
        description: '500MB Daily Plan',
        amount: 0.26,
        currency: 'USD',
        validity: '1 day',
        dataAmount: 0.5,
      ),
      DataBundle(
        id: 2,
        name: '${operator.name} Bundles',
        description: 'Get 600MB + 2mins + 2 SMS, valid for 7 days',
        amount: 0.37,
        currency: 'USD',
        validity: '7 days',
        dataAmount: 0.6,
      ),
      DataBundle(
        id: 3,
        name: '${operator.name} Data',
        description: 'Get 1.8GB + 6mins + 5 SMS, valid for 7 days',
        amount: 1.11,
        currency: 'USD',
        validity: '7 days',
        dataAmount: 1.8,
      ),
      DataBundle(
        id: 4,
        name: '${operator.name} Data',
        description: '2GB Monthly Plan',
        amount: 2.50,
        currency: 'USD',
        validity: '30 days',
        dataAmount: 2.0,
      ),
      DataBundle(
        id: 5,
        name: '${operator.name} Data',
        description: '5GB Monthly Plan',
        amount: 5.00,
        currency: 'USD',
        validity: '30 days',
        dataAmount: 5.0,
      ),
      DataBundle(
        id: 6,
        name: '${operator.name} Data',
        description: '10GB Monthly Plan',
        amount: 8.00,
        currency: 'USD',
        validity: '30 days',
        dataAmount: 10.0,
      ),
      DataBundle(
        id: 7,
        name: '${operator.name} Data',
        description: '20GB Monthly Plan',
        amount: 15.00,
        currency: 'USD',
        validity: '30 days',
        dataAmount: 20.0,
      ),
      DataBundle(
        id: 8,
        name: '${operator.name} Data',
        description: '50GB Monthly Plan',
        amount: 30.00,
        currency: 'USD',
        validity: '30 days',
        dataAmount: 50.0,
      ),
    ];
  }
  
  List<DataBundle> _getDisplayBundles(List<DataBundle> allBundles) {
    if (_showAllBundles || allBundles.length <= _initialBundleCount) {
      return allBundles;
    }
    return allBundles.sublist(0, _initialBundleCount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wizardState = ref.watch(dataWizardProvider);
    final operators = wizardState.availableOperators;
    final selectedCountry = wizardState.selectedCountry;
    final selectedBundle = wizardState.selectedBundle;

    if (operators == null || operators.isEmpty || selectedCountry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    final bundles = _selectedOperator != null ? _generateBundles(_selectedOperator!) : <DataBundle>[];

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
                      'Choose Data Bundle',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Choose the data plan that suits your needs.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                    ),
                    if (operators.length > 1) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildOperatorSelection(context, operators),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    if (_selectedOperator != null) ...[
                      _buildBundlesList(context, bundles),
                    ],
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(context, selectedBundle != null),
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
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Enhanced Internet Data',
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
    final steps = ['Country', 'Network', 'Phone', 'Bundle', 'Confirm'];
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

  Widget _buildOperatorSelection(BuildContext context, List<DataOperator> operators) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Network',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...operators.map((operator) {
          final isSelected = _selectedOperator?.id == operator.id;
          return GestureDetector(
            onTap: () => _selectOperator(operator),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? AppShadows.softGlow(AppColors.primary) : AppShadows.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.wifi_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      operator.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBundlesList(BuildContext context, List<DataBundle> allBundles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayBundles = _getDisplayBundles(allBundles);
    final hasMoreBundles = allBundles.length > _initialBundleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Bundles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (hasMoreBundles)
              Text(
                '${allBundles.length} plans',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...displayBundles.map((bundle) {
          final selectedBundleId = ref.read(dataWizardProvider).selectedBundle?.id;
          final isSelected = selectedBundleId == bundle.id;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _selectBundle(bundle);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? AppShadows.softGlow(AppColors.primary) : AppShadows.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.primaryGradient : null,
                          color: isSelected ? null : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          Icons.wifi_rounded, 
                          color: isSelected ? Colors.white : AppColors.primary, 
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bundle.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bundle.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${bundle.currency} ${bundle.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (bundle.validity != null)
                            Text(
                              bundle.validity!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                            ),
                        ],
                      ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.05, end: 0);
        }),
        if (hasMoreBundles) ...[  
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showAllBundles = !_showAllBundles;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _showAllBundles ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showAllBundles ? 'Show less' : 'Show more (${allBundles.length - _initialBundleCount} more plans)',
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

