import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_back_button.dart';

class SelectRecipientScreen extends StatefulWidget {
  const SelectRecipientScreen({super.key});

  @override
  State<SelectRecipientScreen> createState() => _SelectRecipientScreenState();
}

class _SelectRecipientScreenState extends State<SelectRecipientScreen> {
  final _phoneController = TextEditingController();

  final List<_Contact> _recentContacts = [
    _Contact(name: 'John Doe', phone: '+233 24 123 4567', avatar: 'JD', color: AppColors.primary),
    _Contact(name: 'Sarah Wilson', phone: '+233 55 987 6543', avatar: 'SW', color: AppColors.secondary),
    _Contact(name: 'Mike Johnson', phone: '+233 20 456 7890', avatar: 'MJ', color: AppColors.accent),
    _Contact(name: 'Emma Brown', phone: '+233 27 321 0987', avatar: 'EB', color: AppColors.warning),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _selectContact(_Contact contact) {
    context.push(
      '/airtime/enter-amount?recipient=${Uri.encodeComponent(contact.phone)}&name=${Uri.encodeComponent(contact.name)}',
    );
  }

  void _continueWithPhone() {
    if (_phoneController.text.length >= 9) {
      context.push(
        '/airtime/enter-amount?recipient=${Uri.encodeComponent(_phoneController.text)}&name=',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Steps
                    _StepProgress(currentStep: 0),
                    const SizedBox(height: AppSpacing.xl),
                    // Phone Input
                    _buildPhoneInput(context),
                    const SizedBox(height: AppSpacing.xl),
                    // Recent Contacts
                    _buildRecentContacts(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AppBackButton(
            onTap: () => context.pop(),
            backgroundColor: colorScheme.surface,
            boxShadow: AppShadows.xs,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Buy Airtime',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPhoneInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final fieldFill = isDark ? AppColors.darkSurface : AppColors.lightBg;
    final disabledFill = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Phone Number',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Country Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Text('🇬🇭', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '+233',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Phone Input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: Theme.of(context).textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: '24 XXX XXXX',
                    hintStyle: TextStyle(color: mutedText),
                    filled: true,
                    fillColor: fieldFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts_rounded, color: AppColors.primary),
                      onPressed: () {},
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: _phoneController.text.length >= 9 
                    ? AppColors.primaryGradient 
                    : null,
                color: _phoneController.text.length >= 9 
                    ? null 
                    : disabledFill,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: _phoneController.text.length >= 9 
                    ? AppShadows.softGlow(AppColors.primary) 
                    : null,
              ),
              child: ElevatedButton(
                onPressed: _phoneController.text.length >= 9 ? _continueWithPhone : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: _phoneController.text.length >= 9 
                            ? Colors.white 
                            : mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildRecentContacts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(_recentContacts.length, (index) {
          final contact = _recentContacts[index];
          return _ContactCard(
            contact: contact,
            onTap: () => _selectContact(contact),
          ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05, end: 0);
        }),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }
}

// ============================================================================
// STEP PROGRESS
// ============================================================================
class _StepProgress extends StatelessWidget {
  final int currentStep;

  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Recipient', 'Amount', 'Confirm'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final chipBg = isDark ? AppColors.darkSurface : AppColors.lightBg;

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: stepBefore < currentStep 
                    ? AppColors.primary 
                    : border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        // Step circle
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
                    : chipBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isCurrent 
                      ? AppColors.primary 
                      : border,
                  width: 2,
                ),
                boxShadow: isCurrent 
                    ? AppShadows.softGlow(AppColors.primary) 
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isCurrent 
                              ? Colors.white 
                              : mutedText,
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
                        : mutedText,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        );
      }),
    );
  }
}

// ============================================================================
// CONTACT
// ============================================================================
class _Contact {
  final String name;
  final String phone;
  final String avatar;
  final Color color;

  _Contact({
    required this.name,
    required this.phone,
    required this.avatar,
    required this.color,
  });
}

class _ContactCard extends StatelessWidget {
  final _Contact contact;
  final VoidCallback onTap;

  const _ContactCard({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final mutedText = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final chipBg = isDark ? AppColors.darkSurface : AppColors.lightBg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: contact.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  contact.avatar,
                  style: TextStyle(
                    color: contact.color,
                    fontWeight: FontWeight.w700,
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
                    contact.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: mutedText,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
