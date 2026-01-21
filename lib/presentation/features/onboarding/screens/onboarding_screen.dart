import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../providers/onboarding_provider.dart';

/// Modern Gen Z Onboarding Screen
/// Features: Gradient backgrounds, floating elements, smooth animations
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatingController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Your Money,\nYour Way',
      description:
          'Take control of your finances with a simple, secure experience built for everyday payments.',
      icon: Icons.account_balance_wallet_rounded,
      gradient: AppColors.heroGradient,
      emoji: '',
    ),
    OnboardingPage(
      title: 'Global Airtime\n& Data',
      description:
          'Send airtime and data bundles across 150+ countries with speed, security, and reliability.',
      icon: Icons.signal_cellular_alt_rounded,
      gradient: AppColors.heroGradient,
      emoji: '',
    ),
    OnboardingPage(
      title: 'Transparent\nPricing',
      description:
          'Clear pricing you can trust. What you see is what you pay—no surprises.',
      icon: Icons.verified_rounded,
      gradient: AppColors.heroGradient,
      emoji: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() async {
    HapticFeedback.mediumImpact();
    // Mark onboarding as completed using provider
    final notifier = ref.read(onboardingNotifierProvider);
    await notifier.completeOnboarding();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: Stack(
          children: [
            // Floating background elements
            ..._buildFloatingElements(),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top bar with skip and progress
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Empty spacer (logo removed since main logo is displayed below)
                        const SizedBox(width: 80),
                        // Skip button
                        GestureDetector(
                          onTap: _goToAuth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _OnboardingPageContent(
                          page: _pages[index],
                          pageIndex: index,
                          floatingController: _floatingController,
                        );
                      },
                    ),
                  ),

                  // Bottom section
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        // Page indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => _PageIndicator(
                              isActive: index == _currentPage,
                              index: index,
                              currentPage: _currentPage,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Action button
                        _AnimatedButton(
                          onPressed: _nextPage,
                          isLastPage: _currentPage == _pages.length - 1,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        // Terms text
                        Text(
                          'By continuing, you agree to our Terms & Privacy Policy',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingElements() {
    Widget buildRing({
      required double size,
      required double opacity,
    }) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(opacity),
            width: 1.5,
          ),
        ),
      );
    }

    return [
      // Large circle top right
      Positioned(
        top: -100,
        right: -100,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final t = _floatingController.value * 2 * pi;
            return Transform.translate(
              offset: Offset(
                12 * sin(t * 0.6),
                18 * cos(t * 0.6),
              ),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            );
          },
        ),
      ),
      // Medium circle bottom left
      Positioned(
        bottom: -50,
        left: -50,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final t = _floatingController.value * 2 * pi;
            return Transform.translate(
              offset: Offset(
                10 * cos(t * 0.8),
                12 * sin(t * 0.8),
              ),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            );
          },
        ),
      ),
      // Small floating dots
      ...List.generate(3, (index) {
        final positions = [
          const Offset(50, 200),
          const Offset(300, 150),
          const Offset(100, 500),
        ];
        return Positioned(
          left: positions[index].dx,
          top: positions[index].dy,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final t = _floatingController.value * 2 * pi;
              return Transform.translate(
                offset: Offset(
                  12 * sin(t + index),
                  12 * cos(t + index),
                ),
                child: Container(
                  width: 10 + (index * 6).toDouble(),
                  height: 10 + (index * 6).toDouble(),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06 + (index * 0.02)),
                  ),
                ),
              );
            },
          ),
        );
      }),
      // Bottom ring cluster
      Positioned(
        bottom: -140,
        left: -80,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final t = _floatingController.value * 2 * pi;
            return Transform.translate(
              offset: Offset(18 * sin(t * 0.4), 10 * cos(t * 0.4)),
              child: buildRing(size: 280, opacity: 0.12),
            );
          },
        ),
      ),
      Positioned(
        bottom: -165,
        left: 10,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final t = _floatingController.value * 2 * pi;
            return Transform.translate(
              offset: Offset(22 * cos(t * 0.35), 14 * sin(t * 0.35)),
              child: buildRing(size: 340, opacity: 0.08),
            );
          },
        ),
      ),
      Positioned(
        bottom: -120,
        right: -120,
        child: AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            final t = _floatingController.value * 2 * pi;
            return Transform.translate(
              offset: Offset(16 * sin(t * 0.5), 12 * cos(t * 0.5)),
              child: buildRing(size: 240, opacity: 0.1),
            );
          },
        ),
      ),
    ];
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final String emoji;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.emoji,
  });
}

class _OnboardingPageContent extends StatelessWidget {
  final OnboardingPage page;
  final int pageIndex;
  final AnimationController floatingController;

  const _OnboardingPageContent({
    required this.page,
    required this.pageIndex,
    required this.floatingController,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40),
            // Icon/Illustration with floating animation
            AnimatedBuilder(
              animation: floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 8 * floatingController.value),
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main logo/icon container
                  Container(
                    width: isSmallScreen ? 140 : 160,
                    height: isSmallScreen ? 140 : 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/icon-256.webp',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Emoji badge
                  if (page.emoji.isNotEmpty)
                    Positioned(
                      right: isSmallScreen ? 10 : 15,
                      top: isSmallScreen ? 10 : 15,
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          page.emoji,
                          style: TextStyle(fontSize: isSmallScreen ? 18 : 22),
                        ),
                      ),
                    ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .scale(begin: const Offset(0.95, 0.95), delay: 100.ms, duration: 500.ms),
            SizedBox(height: isSmallScreen ? AppSpacing.lg : AppSpacing.xl),

            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.2,
                  ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.15, end: 0, duration: 500.ms, delay: 200.ms, curve: Curves.easeOutCubic),
            SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.lg),

            // Description
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                page.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 300.ms)
                .slideY(begin: 0.15, end: 0, duration: 500.ms, delay: 300.ms, curve: Curves.easeOutCubic),
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;
  final int index;
  final int currentPage;

  const _PageIndicator({
    required this.isActive,
    required this.index,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = index < currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.95)
            : (isCompleted
                ? Colors.white.withOpacity(0.55)
                : Colors.white.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: null,
      ),
      child: null,
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLastPage;

  const _AnimatedButton({
    required this.onPressed,
    required this.isLastPage,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isLastPage ? 'Get Started' : 'Continue',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
