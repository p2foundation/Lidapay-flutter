import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// LidaPay Branding Constants
/// 
/// This file contains all branding-related constants including:
/// - Brand colors
/// - Logo specifications
/// - Typography guidelines
/// - Spacing and sizing for branded elements
class BrandingConstants {
  BrandingConstants._();

  // ============================================================================
  // BRAND COLORS
  // ============================================================================
  
  /// Primary Brand Color - Vibrant Pink/Magenta
  /// Used for: Primary actions, highlights, gradients
  static const Color brandPrimary = AppColors.primary; // #EC4899
  
  /// Secondary Brand Color - Deep Dark Blue/Indigo
  /// Used for: Secondary elements, text, backgrounds
  static const Color brandSecondary = AppColors.secondary; // #2D2952
  
  /// Brand Gradient - Pink to Indigo
  /// Used for: Hero sections, buttons, cards
  static const LinearGradient brandGradient = AppColors.heroGradient;
  
  /// Primary Gradient - Pink shades
  static const LinearGradient primaryGradient = AppColors.primaryGradient;

  // ============================================================================
  // LOGO SPECIFICATIONS
  // ============================================================================
  
  /// Logo aspect ratio (width:height)
  static const double logoAspectRatio = 1.0;
  
  /// Standard logo sizes
  static const double logoSizeSmall = 40.0;
  static const double logoSizeMedium = 80.0;
  static const double logoSizeLarge = 120.0;
  static const double logoSizeXLarge = 160.0;
  
  /// Logo corner radius
  static const double logoCornerRadius = AppRadius.xl;

  // ============================================================================
  // BRAND TYPOGRAPHY
  // ============================================================================
  
  /// Brand name
  static const String brandName = 'LidaPay';
  static const String brandNameShort = 'Lida';
  
  /// Brand tagline
  static const String brandTagline = 'Your Digital Financial Partner';
  static const String brandTaglineAlt = 'Your trusted payment partner';
  
  /// Brand description
  static const String brandDescription = 
      'International and local airtime and internet data remittance app for Ghana';

  // ============================================================================
  // BRAND ASSETS PATHS
  // ============================================================================
  
  /// Logo asset paths (to be added when logo files are created)
  static const String logoPath = 'assets/images/logo.png';
  static const String logoWhitePath = 'assets/images/logo_white.png';
  static const String logoIconPath = 'assets/icons/logo_icon.png';
  static const String splashLogoPath = 'assets/images/splash_logo.png';

  // ============================================================================
  // SPLASH SCREEN
  // ============================================================================
  
  /// Splash screen background color (pink gradient)
  static const Color splashBackgroundColor = brandPrimary;
  static const LinearGradient splashGradient = brandGradient;
  
  /// Splash screen animation duration
  static const Duration splashAnimationDuration = Duration(milliseconds: 1500);

  // ============================================================================
  // APP ICON COLORS
  // ============================================================================
  
  /// App icon background color
  static const Color appIconBackground = brandPrimary;
  
  /// App icon foreground color (for logo)
  static const Color appIconForeground = Colors.white;

  // ============================================================================
  // BRANDING GUIDELINES
  // ============================================================================
  
  /// Minimum logo size for visibility
  static const double minLogoSize = 24.0;
  
  /// Minimum spacing around logo
  static const double minLogoPadding = AppSpacing.md;
  
  /// Logo shadow configuration
  static List<BoxShadow> logoShadow(Color color) => AppShadows.glow(color);
}

