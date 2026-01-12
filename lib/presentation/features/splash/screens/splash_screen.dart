import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../core/constants/branding_constants.dart';

/// Splash Screen
/// 
/// Displays the LidaPay branding while the app initializes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for minimum splash duration
    await Future.delayed(BrandingConstants.splashAnimationDuration);
    
    if (!mounted) return;
    
    // Navigate to appropriate screen (login or home)
    // This will be handled by your routing logic
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: BrandingConstants.splashGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animation
                const BrandLogo.xlarge()
                    .animate()
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .then()
                    .fadeIn(duration: 400.ms),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 1000.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

