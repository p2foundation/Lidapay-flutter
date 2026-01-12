import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/api_models.dart';
import '../../../providers/data_wizard_provider.dart';
import '../../../providers/auth_provider.dart'; // Contains apiClientProvider
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/country_flag_widget.dart';

class EnterPhoneDataScreen extends ConsumerStatefulWidget {
  const EnterPhoneDataScreen({super.key});

  @override
  ConsumerState<EnterPhoneDataScreen> createState() => _EnterPhoneDataScreenState();
}

class _EnterPhoneDataScreenState extends ConsumerState<EnterPhoneDataScreen> {
  final _phoneController = TextEditingController();
  bool _isDetecting = false;
  bool _isLoadingOperators = false;
  AutodetectData? _detectedOperator;
  List<DataOperator>? _operators;
  String? _error;

  Timer? _detectDebounce;
  int _detectSeq = 0; // used to ignore stale autodetect responses

  @override
  void initState() {
    super.initState();
    final wizardState = ref.read(dataWizardProvider);
    if (wizardState.phoneNumber != null) {
      _phoneController.text = wizardState.phoneNumber!;
    }
    if (wizardState.operatorData != null) {
      _detectedOperator = wizardState.operatorData;
    }
    if (wizardState.availableOperators != null) {
      _operators = wizardState.availableOperators;
    }
  }

  @override
  void dispose() {
    _detectDebounce?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _autodetectOperator() async {
    final int requestId = ++_detectSeq;
    final country = ref.read(dataWizardProvider).selectedCountry;
    if (country == null || _phoneController.text.isEmpty) return;

    // Extract phone number (digits only)
    String phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.length < 7) return;

    // Get country code (without +)
    final countryCode = _getCountryCode(country);
    
    // Remove country code if user included it
    if (phone.startsWith(countryCode)) {
      phone = phone.substring(countryCode.length);
    }
    
    // Smart handling of leading zero based on country
    // Some countries require the leading zero for operator detection
    final countriesRequiringZero = ['CI', 'SN', 'ML', 'BF', 'NE', 'TG', 'BJ', 'GN', 'CG', 'CD', 'CM'];
    
    String localPhone;
    if (countriesRequiringZero.contains(country.code)) {
      // For these countries, keep the leading zero if present
      localPhone = phone;
    } else {
      // For other countries, strip leading zero (common in local phone numbers)
      if (phone.startsWith('0')) {
        localPhone = phone.substring(1);
      } else {
        localPhone = phone;
      }
    }
    
    // Prepend country code to phone number for API
    final fullPhoneNumber = '$countryCode$localPhone';

    setState(() {
      _isDetecting = true;
      _error = null;
      _detectedOperator = null;
      _operators = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      // Step 1: Auto-detect operator
      final autodetectResponse = await apiClient.autodetectOperator(
        AutodetectRequest(
          phone: fullPhoneNumber.toString(),
          countryIsoCode: country.code,
        ),
      );

      // Ignore stale responses (user may have typed again)
      if (!mounted || requestId != _detectSeq) return;

      if (autodetectResponse.success && autodetectResponse.data != null) {
        setState(() {
          _detectedOperator = autodetectResponse.data;
          _isDetecting = false;
          _error = null; // ensure any previous error is cleared
        });
        
        // Store full phone number (with country code) for use in confirm screen
        ref.read(dataWizardProvider.notifier)
          ..setPhoneNumber(fullPhoneNumber)
          ..setOperatorData(autodetectResponse.data!);

        // Step 2: Call list-operators right after auto-detect
        await _loadOperators(country.code);
      } else {
        setState(() {
          _error = autodetectResponse.message;
          _isDetecting = false;
        });
      }
    } catch (e) {
      if (!mounted || requestId != _detectSeq) return;
      setState(() {
        _error = 'Failed to detect operator. Please check the phone number.';
        _isDetecting = false;
      });
    }
  }

  Future<void> _loadOperators(String countryCode) async {
    setState(() {
      _isLoadingOperators = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final httpResponse = await apiClient.listDataOperatorsRaw(
        DataOperatorsRequest(countryCode: countryCode),
      );
      final rawResponse = httpResponse.data;

      // Parse the raw list response
      final allOperators = <DataOperator>[];
      if (rawResponse is List) {
        for (var item in rawResponse) {
          try {
            if (item is Map<String, dynamic>) {
              final operator = DataOperator.fromJson(item);
              allOperators.add(operator);
            }
          } catch (e) {
            print('⚠️ Failed to parse operator: $e');
          }
        }
      }

      if (allOperators.isEmpty) {
        setState(() {
          _error = 'No operators found for this country.';
          _isLoadingOperators = false;
        });
        return;
      }

      // Filter operators by detected network name and data capability
      final detectedName = _detectedOperator?.name?.toLowerCase() ?? '';
      List<DataOperator> filteredOperators;
      
      if (detectedName.isNotEmpty) {
        // Extract base network name (e.g., "MTN" from "MTN Nigeria")
        final baseNetworkName = detectedName.split(' ').first;
        
        // Filter for operators matching the detected network that support data
        filteredOperators = allOperators.where((op) {
          final opName = op.name.toLowerCase();
          final matchesNetwork = opName.contains(baseNetworkName);
          final supportsData = op.data == true || op.bundle == true;
          return matchesNetwork && supportsData;
        }).toList();
        
        // If no data operators found for detected network, show all data operators
        if (filteredOperators.isEmpty) {
          filteredOperators = allOperators.where((op) => op.data == true || op.bundle == true).toList();
        }
      } else {
        // No detected operator, show all data operators
        filteredOperators = allOperators.where((op) => op.data == true || op.bundle == true).toList();
      }
      
      setState(() {
        _operators = filteredOperators;
        _isLoadingOperators = false;
      });
      
      ref.read(dataWizardProvider.notifier).setAvailableOperators(filteredOperators);
    } catch (e) {
      print('❌ Failed to load operators: $e');
      setState(() {
        _error = 'Failed to load operators. Please try again.';
        _isLoadingOperators = false;
      });
    }
  }

  void _useMyNumber() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      // Extract only digits from phone number
      String phone = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      
      // Remove country code if present (assuming it starts with country code)
      final countryCode = _getCountryCode(ref.read(dataWizardProvider).selectedCountry!);
      if (phone.startsWith(countryCode)) {
        phone = phone.substring(countryCode.length);
      }
      
      _phoneController.text = phone;
      // Trigger autodetect after a short delay
      _detectDebounce?.cancel();
      _detectDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) _autodetectOperator();
      });
    }
  }

  void _continue() {
    if (_operators != null && _operators!.isNotEmpty) {
      context.push('/data/select-bundle');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wizardState = ref.watch(dataWizardProvider);
    final selectedCountry = wizardState.selectedCountry;

    if (selectedCountry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.pop());
      return const SizedBox.shrink();
    }

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildProgressIndicator(context, 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructions(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPhoneInput(context),
                    if (_isDetecting || _isLoadingOperators) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildLoadingIndicator(),
                    ],
                    if (_detectedOperator != null && _operators != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildOperatorInfo(context),
                      if (_operators!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildOperatorsCount(context),
                      ],
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildError(context),
                    ],
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(context),
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

  Widget _buildInstructions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Enter the phone number for the data bundle. Your phone number is pre-filled for convenience.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
    );
  }

  Widget _buildPhoneInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCountry = ref.read(dataWizardProvider).selectedCountry!;
    // Watch so UI updates when profile loads (enables "Use My Number")
    final user = ref.watch(currentUserProvider).valueOrNull;
    final countryCode = _getCountryCode(selectedCountry);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country code selector - fixed width with flag image
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flag image
                    CountryFlagWidget(
                      flagUrl: selectedCountry.flag,
                      countryCode: selectedCountry.code,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    // Country code text
                    Flexible(
                      child: Text(
                        '+$countryCode',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Phone input - takes remaining space
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) {
                    setState(() {
                      _detectedOperator = null;
                      _operators = null;
                      _error = null;
                    });
                    // Auto-detect after a delay
                    _detectDebounce?.cancel();
                    _detectDebounce = Timer(const Duration(milliseconds: 800), () {
                      if (mounted && _phoneController.text.length >= 7) {
                        _autodetectOperator();
                      }
                    });
                  },
                  style: Theme.of(context).textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: _phoneController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _phoneController.clear();
                              setState(() {
                                _detectedOperator = null;
                                _operators = null;
                                _error = null;
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _useMyNumber,
                icon: const Icon(Icons.person_rounded),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Use My Number (${user.phoneNumber})'),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'For ${selectedCountry.name}, enter a number starting with $countryCode (e.g., ${countryCode}123456789)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _isDetecting ? 'Detecting network...' : 'Loading data operators...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final operator = _detectedOperator!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${operator.name} detected',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  operator.countryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.05, end: 0);
  }

  Widget _buildOperatorsCount(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${_operators!.length} data operator${_operators!.length > 1 ? 's' : ''} available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final canContinue = _operators != null && _operators!.isNotEmpty;
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

  String _getCountryCode(Country country) {
    // Use calling codes from API response if available
    if (country.callingCodes != null && country.callingCodes!.isNotEmpty) {
      // Remove "+" if present (API might return "+233" or "233")
      return country.callingCodes!.first.replaceFirst(RegExp(r'^\+'), '');
    }
    // Fallback to common country codes
    final codes = {
      'NG': '234',
      'GH': '233',
      'KE': '254',
      'ZA': '27',
      'UG': '256',
      'TZ': '255',
      'ET': '251',
      'RW': '250',
      'ZM': '260',
      'ZW': '263',
    };
    return codes[country.code] ?? '234';
  }
}

