import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/data_wizard_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/utils/ghana_network_codes.dart';

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

  List<DataBundle> _generateBundles(
    DataOperator operator,
    Map<int, Map<String, dynamic>>? operatorMetadata,
    Country? country,
  ) {
    // Special handling for Ghana bundles
    if (country?.code == 'GH') {
      return _generateGhanaBundles(operator);
    }
    
    final metadata = operatorMetadata?[operator.operatorId];
    if (metadata == null) {
      return [];
    }

    final fixedAmounts = (metadata['fixedAmounts'] as List?)
            ?.map((value) => (value as num).toDouble())
            .toList() ??
        <double>[];
    final localFixedAmounts = (metadata['localFixedAmounts'] as List?)
            ?.map((value) => (value as num).toDouble())
            .toList() ??
        <double>[];

    final descriptions = (metadata['fixedAmountsDescriptions'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
        <String, String>{};
    final localDescriptions = (metadata['localFixedAmountsDescriptions'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
        <String, String>{};

    final useFixed = fixedAmounts.isNotEmpty;
    final amounts = useFixed ? fixedAmounts : localFixedAmounts;
    final currency = useFixed
        ? (metadata['senderCurrencyCode'] as String? ?? 'USD')
        : (metadata['destinationCurrencyCode'] as String? ?? 'GHS');
    final amountDescriptions = useFixed ? descriptions : localDescriptions;

    String _resolveDescription(double amount) {
      final keyExact = amount.toStringAsFixed(2);
      if (amountDescriptions.containsKey(keyExact)) {
        return amountDescriptions[keyExact]!;
      }
      for (final entry in amountDescriptions.entries) {
        final parsed = double.tryParse(entry.key);
        if (parsed != null && (parsed - amount).abs() < 0.001) {
          return entry.value;
        }
      }
      return 'Data bundle';
    }

    return List.generate(amounts.length, (index) {
      final amount = amounts[index];
      final description = _resolveDescription(amount);
      return DataBundle(
        id: index + 1,
        name: operator.name,
        description: description,
        amount: amount,
        currency: currency,
        metadata: metadata,
      );
    });
  }
  
  List<DataBundle> _generateGhanaBundles(DataOperator operator) {
    final networkCode = GhanaNetworkCodes.fromOperatorId(operator.operatorId);
    final bundleListAsync = ref.watch(ghanaDataBundlesProvider(networkCode));
    
    return bundleListAsync.when(
      data: (bundles) {
        return bundles.asMap().entries.map((entry) {
          final index = entry.key;
          final bundle = entry.value;
          
          // Create user-friendly display name
          String displayName = bundle['plan_name'] ?? 'Unknown Bundle';
          final volume = bundle['volume'] ?? '';
          final price = bundle['price']?.toString() ?? '0';
          
          // Format readable name: "7.27 GB - GHS 3.00" or "40.91 MB - GHS 1.00"
          if (volume.isNotEmpty && !displayName.toLowerCase().contains('ghc')) {
            // Extract data amount from volume if available
            if (volume.contains('GB') || volume.contains('MB')) {
              displayName = "${volume.split(' of ')[0]} - GHS $price";
            } else {
              displayName = "$volume - GHS $price";
            }
          } else {
            // Clean up the original name
            displayName = displayName.replaceAll('_Others', '').replaceAll('_', ' ');
          }
          
          // Format the description to show additional details
          String description = '';
          final validity = bundle['validity'];
          final category = bundle['category'];
          
          // Add validity info
          if (validity != null && validity != 'NO EXPIRY' && validity != '') {
            description += validity;
          } else if (validity == 'NO EXPIRY') {
            description += 'No expiry';
          }
          
          // Add type info for special bundles
          if (category == 'FLEXI') {
            if (description.isNotEmpty) description += ' • ';
            description += 'Flexi amount';
          }
          
          // Add special bundle info
          if (bundle['plan_name'].toString().toLowerCase().contains('midnight')) {
            if (description.isNotEmpty) description += ' • ';
            description += 'Midnight bundle (12AM-8AM)';
          }
          
          return DataBundle(
            id: index + 1000, // Use unique IDs starting from 1000 to avoid conflicts
            name: displayName, // User-friendly name for display
            description: description, // Additional details
            amount: double.tryParse(bundle['price']?.toString() ?? '0') ?? 0.0,
            currency: 'GHS',
            validity: validity,
            planId: bundle['plan_id'], // Store original plan_id for API call
            metadata: {
              ...bundle,
              'original_name': bundle['plan_name'], // Keep original name for reference
            },
          );
        }).toList();
      },
      loading: () => [],
      error: (_, __) => [],
    );
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

    final bundles = _selectedOperator != null
        ? _generateBundles(_selectedOperator!, wizardState.operatorMetadata, selectedCountry)
        : <DataBundle>[];

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
          AppBackButton(
            onTap: () => context.pop(),
            backgroundColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.white,
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
                    child: operator.logoUrl != null && operator.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.network(
                              operator.logoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.wifi_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : Icon(Icons.wifi_rounded, color: AppColors.primary, size: 24),
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
                            'GHS ${bundle.amount.toStringAsFixed(2)}',
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

