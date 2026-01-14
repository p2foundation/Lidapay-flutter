import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _loadSavedCredentials();
  }

  void _onFieldChanged() {
    setState(() {});
  }
  
  Future<void> _loadSavedCredentials() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final isRememberMeEnabled = await authRepository.isRememberMeEnabled();
      
      if (isRememberMeEnabled) {
        final savedUsername = await authRepository.getSavedUsername();
        final savedPassword = await authRepository.getSavedPassword();
        
        if (savedUsername != null && savedPassword != null) {
          setState(() {
            _phoneController.text = savedUsername;
            _passwordController.text = savedPassword;
            _rememberMe = true;
          });
          AppLogger.info('📋 Loaded saved credentials', 'LoginScreen');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load saved credentials', e, null, 'LoginScreen');
    }
  }

  bool get _isPhoneValid {
    final phone = _phoneController.text.trim();
    return phone.length >= 9 && Validators.phone(phone) == null;
  }

  bool get _isPasswordValid {
    final password = _passwordController.text;
    return password.length >= 6;
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    // Validate password is not empty
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate password has minimum length
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    AppLogger.info('🚀 Login attempt for: $username', 'LoginScreen');

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      await authNotifier.login(username, password, rememberMe: _rememberMe);

      // Check the state after login completes
      final authState = ref.read(authStateProvider);
      
      authState.when(
        data: (tokens) {
          if (tokens != null && 
              tokens.containsKey('accessToken') && 
              tokens['accessToken']!.isNotEmpty) {
            AppLogger.info('✅ Login successful - navigating to dashboard', 'LoginScreen');
            // Clear any previous errors
            if (mounted) {
              context.go('/dashboard');
            }
          } else {
            AppLogger.warning('⚠️ Login returned invalid tokens', 'LoginScreen');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login failed. Invalid credentials.'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        },
        loading: () {
          // Still loading - UI will show loading state
          AppLogger.info('⏳ Login in progress...', 'LoginScreen');
        },
        error: (error, stackTrace) {
          AppLogger.error('❌ Login error', error, stackTrace, 'LoginScreen');
          final errorMessage = error.toString().replaceAll('Exception: ', '');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage.isNotEmpty 
                    ? errorMessage 
                    : 'Login failed. Please check your credentials.'),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ Unexpected login error', e, stackTrace, 'LoginScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  // Logo
                  const Center(
                    child: BrandLogo.xlarge(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Text(
                      'Sign in to continue your journey',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: secondaryText,
                          ),
                    ).animate().fadeIn(delay: 300.ms),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  //     Text(
                  //       'Welcome Back! ',
                  //       style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  //             fontWeight: FontWeight.w800,
                  //           ),
                  //     ),
                  //     const Text('👋', style: TextStyle(fontSize: 28)),
                  //   ],
                  // ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1, end: 0, duration: 400.ms),
                  // const SizedBox(height: AppSpacing.xs),
                  // Text(
                  //   'Sign in to continue your journey',
                  //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  //         color: secondaryText,
                  //       ),
                  // ).animate().fadeIn(delay: 300.ms),
                  // const SizedBox(height: AppSpacing.xxl),

                  // Phone Field
                  Text(
                    'Phone Number',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Enter your phone number',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.phone_outlined,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      suffixIcon: _isPhoneValid
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.lightSuccess)
                          : null,
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: Validators.phone,
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: AppSpacing.lg),

                  // Password Field
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isPasswordValid)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_circle_rounded, color: AppColors.lightSuccess),
                            ),
                          IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ],
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    validator: Validators.password,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: AppSpacing.md),

                  // Remember & Forgot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v!),
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: AppSpacing.lg),

                  // Error Message
                  authState.maybeWhen(
                    error: (error, _) => Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              error.toString().replaceAll('Exception: ', ''),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.error,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: authState.maybeWhen(
                      loading: () => Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                      ),
                      orElse: () => Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _handleLogin();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign In',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95), duration: 300.ms),
                  const SizedBox(height: AppSpacing.xl),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'or continue with',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: AppSpacing.lg),

                  // Social Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          icon: 'G',
                          label: 'Google',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SocialButton(
                          icon: '',
                          label: 'Apple',
                          isApple: true,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: AppSpacing.xxl),

                  // Sign Up Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/register');
                          },
                          child: ShaderMask(
                            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                            child: Text(
                              'Sign Up ✨',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 650.ms),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isApple;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    this.isApple = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isApple)
              Icon(
                Icons.apple,
                size: 22,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              )
            else
              Text(
                icon,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDB4437),
                ),
              ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
