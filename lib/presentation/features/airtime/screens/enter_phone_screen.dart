import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../data/models/api_models.dart';
import '../../../../data/datasources/api_client.dart';
import '../../../providers/airtime_wizard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../../core/widgets/custom_bottom_nav.dart';
import '../../../../core/widgets/country_flag_widget.dart';

class EnterPhoneScreen extends ConsumerStatefulWidget {
  const EnterPhoneScreen({super.key});

  @override
  ConsumerState<EnterPhoneScreen> createState() => _EnterPhoneScreenState();
}

class _EnterPhoneScreenState extends ConsumerState<EnterPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isDetecting = false;
  AutodetectData? _detectedOperator;
  String? _error;

  Timer? _detectDebounce;
  int _detectSeq = 0; // used to ignore stale autodetect responses

  @override
  void initState() {
    super.initState();
    final wizardState = ref.read(airtimeWizardProvider);
    if (wizardState.phoneNumber != null) {
      _phoneController.text = wizardState.phoneNumber!;
    }
    if (wizardState.operatorData != null) {
      _detectedOperator = wizardState.operatorData;
    }
  }

  @override
  void dispose() {
    _detectDebounce?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  static const _countriesRequiringZero = [
    'CI',
    'SN',
    'ML',
    'BF',
    'NE',
    'TG',
    'BJ',
    'GN',
    'CG',
    'CD',
    'CM',
  ];

  Future<void> _autodetectOperator() async {
    final int requestId = ++_detectSeq;
    final country = ref.read(airtimeWizardProvider).selectedCountry;
    if (country == null || _phoneController.text.isEmpty) return;

    // Extract phone number (digits only)
    String phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.length < 7) return;

    final fullPhoneNumber = _normalizePhoneNumber(country, phone);

    setState(() {
      _isDetecting = true;
      _error = null;
      _detectedOperator = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.autodetectOperator(
        AutodetectRequest(
          phone: fullPhoneNumber.toString(),
          countryIsoCode: country.code,
        ),
      );

      // Ignore stale responses (user may have typed again)
      if (!mounted || requestId != _detectSeq) return;

      if (response.success && response.data != null) {
        setState(() {
          _detectedOperator = response.data;
          _isDetecting = false;
          _error = null; // ensure any previous error is cleared
        });
        // Store full phone number (with country code) for use in confirm screen
        ref.read(airtimeWizardProvider.notifier)
          ..setPhoneNumber(fullPhoneNumber)
          ..setOperatorData(response.data!);
      } else {
        setState(() {
          _error = _sanitizePhoneError(
            response.message.isNotEmpty
                ? response.message
                : 'We could not detect the network for this number. Check the digits and try again.',
            country,
          );
          _isDetecting = false;
        });
      }
    } catch (e) {
      if (!mounted || requestId != _detectSeq) return;
      setState(() {
        _error = _sanitizePhoneError(
          'We could not detect the network for this number. Please verify the phone number and try again.',
          country,
        );
        _isDetecting = false;
      });
    }
  }

  String _normalizePhoneNumber(Country country, String rawPhone) {
    var phone = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    final countryCode = _getCountryCode(country);

    if (phone.startsWith(countryCode)) {
      phone = phone.substring(countryCode.length);
    }

    if (!_countriesRequiringZero.contains(country.code) && phone.startsWith('0')) {
      phone = phone.substring(1);
    }

    return '$countryCode$phone';
  }

  String _sanitizePhoneError(String message, Country country) {
    final lower = message.toLowerCase();
    if (lower.contains('phone number') && lower.contains('country code')) {
      final countryCode = _getCountryCode(country);
      return 'That phone number doesn\'t match ${country.name}. Remove the leading 0 after $countryCode and try again.';
    }
    return message;
  }

  void _useMyNumber() {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) {
      // Extract only digits from phone number
      String phone = user.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
      
      // Remove country code if present (assuming it starts with country code)
      final countryCode = _getCountryCode(ref.read(airtimeWizardProvider).selectedCountry!);
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
    if (_detectedOperator != null) {
      context.push('/airtime/select-amount');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wizardState = ref.watch(airtimeWizardProvider);
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
                    if (_isDetecting) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildDetectingIndicator(),
                    ],
                    if (_detectedOperator != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildOperatorInfo(context),
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
          AppBackButton(
            onTap: () => context.pop(),
            backgroundColor: Colors.white.withOpacity(0.2),
            iconColor: Colors.white,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Enter Phone Number',
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

  Widget _buildInstructions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Enter the phone number to recharge (network will be auto-detected). Your phone number is pre-filled for convenience.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
    );
  }

  Widget _buildPhoneInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCountry = ref.read(airtimeWizardProvider).selectedCountry!;
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

  Widget _buildDetectingIndicator() {
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
          Text(
            'Detecting network...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
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
    final canContinue = _detectedOperator != null;
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

