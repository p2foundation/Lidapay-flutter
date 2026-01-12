import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../constants/branding_constants.dart';

/// LidaPay Brand Logo Widget
/// 
/// A reusable logo component that displays the LidaPay branding.
/// Supports different sizes and styles.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showTagline;
  final bool animated;
  final Color? backgroundColor;
  final bool useGradient;
  final MainAxisAlignment textAlignment;

  const BrandLogo({
    super.key,
    this.size = BrandingConstants.logoSizeMedium,
    this.showText = false,
    this.showTagline = false,
    this.animated = false,
    this.backgroundColor,
    this.useGradient = true,
    this.textAlignment = MainAxisAlignment.center,
  });

  /// Small logo (40x40)
  const BrandLogo.small({
    super.key,
    this.size = BrandingConstants.logoSizeSmall,
    this.showText = false,
    this.showTagline = false,
    this.animated = false,
    this.backgroundColor,
    this.useGradient = true,
    this.textAlignment = MainAxisAlignment.center,
  });

  /// Medium logo (80x80)
  const BrandLogo.medium({
    super.key,
    this.size = BrandingConstants.logoSizeMedium,
    this.showText = false,
    this.showTagline = false,
    this.animated = false,
    this.backgroundColor,
    this.useGradient = true,
    this.textAlignment = MainAxisAlignment.center,
  });

  /// Large logo (120x120)
  const BrandLogo.large({
    super.key,
    this.size = BrandingConstants.logoSizeLarge,
    this.showText = true,
    this.showTagline = false,
    this.animated = false,
    this.backgroundColor,
    this.useGradient = true,
    this.textAlignment = MainAxisAlignment.center,
  });

  /// Extra large logo with text and tagline (160x160)
  const BrandLogo.xlarge({
    super.key,
    this.size = BrandingConstants.logoSizeXLarge,
    this.showText = true,
    this.showTagline = true,
    this.animated = true,
    this.backgroundColor,
    this.useGradient = true,
    this.textAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget logoWidget = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: textAlignment,
      children: [
        // Logo Icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(BrandingConstants.logoCornerRadius),
            boxShadow: backgroundColor != null && backgroundColor != Colors.transparent ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ] : null,
          ),
          child: Center(
            child: _buildLogoIcon(size),
          ),
        ),
        
        // Brand Name
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            BrandingConstants.brandName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : null,
                ),
          ),
        ],
        
        // Tagline
        if (showTagline) ...[
          SizedBox(height: size * 0.05),
          Text(
            BrandingConstants.brandTagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (animated) {
      return logoWidget
          .animate()
          .scale(
            duration: 500.ms,
            curve: Curves.elasticOut,
          )
          .then()
          .fadeIn(duration: 300.ms);
    }

    return logoWidget;
  }

  /// Builds the logo icon - loads from assets
  Widget _buildLogoIcon(double iconSize) {
    // Select appropriate image size based on logo size
    String imagePath;
    if (iconSize <= 48) {
      imagePath = 'assets/images/icon-48.webp';
    } else if (iconSize <= 72) {
      imagePath = 'assets/images/icon-72.webp';
    } else if (iconSize <= 96) {
      imagePath = 'assets/images/icon-96.webp';
    } else if (iconSize <= 128) {
      imagePath = 'assets/images/icon-128.webp';
    } else if (iconSize <= 192) {
      imagePath = 'assets/images/icon-192.webp';
    } else if (iconSize <= 256) {
      imagePath = 'assets/images/icon-256.webp';
    } else {
      imagePath = 'assets/images/icon-512.webp';
    }
    
    return Image.asset(
      imagePath,
      width: iconSize * 0.95,
      height: iconSize * 0.95,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fall back to custom painter if image not found
        return _LogoIcon(size: iconSize * 0.85);
      },
    );
  }
}

/// Logo Icon Component
/// 
/// The stylized logo icon: two dark blue dots connected by a diagonal line,
/// with a shorter diagonal line extending from the top dot (stylized 'L')
class _LogoIcon extends StatelessWidget {
  final double size;

  const _LogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(),
    );
  }
}

/// Custom painter for the LidaPay logo
/// 
/// Logo design: Two dark blue dots connected by a diagonal line,
/// with a shorter diagonal line extending from the top dot (stylized 'L')
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 100; // Scale factor based on 100x100 base
    
    // Dark blue color for logo elements
    paint.color = BrandingConstants.brandSecondary;
    
    // Calculate positions for the logo elements
    final dotRadius = 8 * scale;
    final lineWidth = 6 * scale;
    
    // Top dot position (upper right area)
    final topDotCenter = Offset(center.dx + 15 * scale, center.dy - 20 * scale);
    
    // Bottom dot position (lower left area)
    final bottomDotCenter = Offset(center.dx - 15 * scale, center.dy + 20 * scale);
    
    // Main diagonal line connecting the two dots
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = lineWidth;
    paint.color = BrandingConstants.brandSecondary;
    
    final mainLinePath = Path()
      ..moveTo(topDotCenter.dx, topDotCenter.dy)
      ..lineTo(bottomDotCenter.dx, bottomDotCenter.dy);
    canvas.drawPath(mainLinePath, paint);
    
    // Shorter diagonal line extending from top dot (creating stylized 'L')
    // This line extends upward and to the left from the top dot
    final shortLineEnd = Offset(
      topDotCenter.dx - 18 * scale,
      topDotCenter.dy - 12 * scale,
    );
    
    final shortLinePath = Path()
      ..moveTo(topDotCenter.dx, topDotCenter.dy)
      ..lineTo(shortLineEnd.dx, shortLineEnd.dy);
    canvas.drawPath(shortLinePath, paint);
    
    // Draw the two dots
    paint.style = PaintingStyle.fill;
    
    // Top dot
    canvas.drawCircle(topDotCenter, dotRadius, paint);
    
    // Bottom dot
    canvas.drawCircle(bottomDotCenter, dotRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

