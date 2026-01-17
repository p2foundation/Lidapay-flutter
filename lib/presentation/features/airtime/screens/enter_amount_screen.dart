import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';

class EnterAmountScreen extends StatefulWidget {
  final String recipientPhone;
  final String recipientName;

  const EnterAmountScreen({
    super.key,
    required this.recipientPhone,
    required this.recipientName,
  });

  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen> {
  String _amount = '';
  final List<int> _presets = [5, 10, 20, 50, 100, 200];
  int? _selectedPreset;

  void _addDigit(String digit) {
    if (_amount.length < 6) {
      setState(() {
        _amount += digit;
        _selectedPreset = null;
      });
    }
  }

  void _removeDigit() {
    if (_amount.isNotEmpty) {
      setState(() {
        _amount = _amount.substring(0, _amount.length - 1);
        _selectedPreset = null;
      });
    }
  }

  void _selectPreset(int value) {
    setState(() {
      _amount = value.toString();
      _selectedPreset = value;
    });
  }

  void _continue() {
    if (_amount.isNotEmpty && double.parse(_amount) > 0) {
      context.push(
        '/airtime/confirm?recipient=${Uri.encodeComponent(widget.recipientPhone)}&name=${Uri.encodeComponent(widget.recipientName)}&amount=$_amount',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayAmount = _amount.isEmpty ? '0' : _amount;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // Header
          _buildHeader(context, displayAmount),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Recipient Info
                  _buildRecipientInfo(context),
                  const SizedBox(height: AppSpacing.xl),
                  // Presets
                  _buildPresets(context),
                  const Spacer(),
                  // Keypad
                  _buildKeypad(context),
                  const SizedBox(height: AppSpacing.lg),
                  // Continue Button
                  _buildContinueButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String displayAmount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  AppBackButton(
                    onTap: () => context.pop(),
                    size: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Enter Amount',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Amount Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GHS',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayAmount,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 56,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Available balance: GHS 1,250.00',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRecipientInfo(BuildContext context) {
    final displayName = widget.recipientName.isNotEmpty
        ? widget.recipientName
        : widget.recipientPhone;
    final initials = widget.recipientName.isNotEmpty
        ? widget.recipientName.split(' ').map((e) => e[0]).take(2).join()
        : '#';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sending to',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.lightTextTertiary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Change',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildPresets(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _presets.map((value) {
            final isSelected = _selectedPreset == value;
            return GestureDetector(
              onTap: () => _selectPreset(value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected ? AppColors.brandPrimary : AppColors.lightBorder,
                  ),
                  boxShadow: isSelected ? AppShadows.glow(AppColors.brandPrimary, opacity: 0.2) : null,
                ),
                child: Text(
                  'GHS $value',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected ? Colors.white : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildKeypad(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              return _KeypadButton(
                label: key,
                onTap: () {
                  if (key == '⌫') {
                    _removeDigit();
                  } else if (key == '.' && !_amount.contains('.')) {
                    _addDigit(key);
                  } else if (key != '.') {
                    _addDigit(key);
                  }
                },
              );
            }).toList(),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildContinueButton(BuildContext context) {
    final isValid = _amount.isNotEmpty && double.tryParse(_amount) != null && double.parse(_amount) > 0;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: isValid ? AppColors.primaryGradient : null,
          color: isValid ? null : AppColors.lightBorder,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: isValid ? AppShadows.glow(AppColors.brandPrimary, opacity: 0.3) : null,
        ),
        child: ElevatedButton(
          onPressed: isValid ? _continue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(
            'Continue',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isValid ? Colors.white : AppColors.lightTextTertiary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.xs,
        ),
        child: Center(
          child: label == '⌫'
              ? const Icon(Icons.backspace_outlined, size: 22, color: AppColors.lightTextPrimary)
              : Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
        ),
      ),
    );
  }
}
