import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A modern glassmorphic card widget with blur effect and gradient border
/// Perfect for Gen Z aesthetic - trendy, modern, and visually appealing
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<Color>? gradientColors;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool showGlow;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
    this.margin,
    this.gradientColors,
    this.borderWidth = 1.5,
    this.onTap,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xl);
    final colors = gradientColors ?? [
      AppColors.primary.withOpacity(0.5),
      AppColors.secondary.withOpacity(0.5),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: radius,
                color: isDark
                    ? Colors.white.withOpacity(opacity)
                    : Colors.white.withOpacity(opacity + 0.6),
                border: Border.all(
                  width: borderWidth,
                  color: LinearGradient(colors: colors)
                      .colors
                      .first
                      .withOpacity(0.3),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                    Colors.white.withOpacity(isDark ? 0.05 : 0.6),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated gradient border card - perfect for highlighting important elements
class GradientBorderCard extends StatefulWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final double borderWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool animate;
  final Duration animationDuration;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.borderWidth = 2,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.animate = true,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<GradientBorderCard> createState() => _GradientBorderCardState();
}

class _GradientBorderCardState extends State<GradientBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.xl);
    final colors = widget.gradientColors ??
        [
          AppColors.primary,
          AppColors.secondary,
          AppColors.primary,
        ];

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: SweepGradient(
                center: Alignment.center,
                startAngle: 0,
                endAngle: 6.28,
                transform: GradientRotation(_controller.value * 6.28),
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(widget.borderWidth),
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  radius.topLeft.x - widget.borderWidth,
                ),
                color: isDark ? AppColors.darkCard : Colors.white,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Neumorphic card for a soft, modern look
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool isPressed;
  final Color? color;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.isPressed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xl);
    final bgColor = color ?? (isDark ? AppColors.darkCard : AppColors.lightBg);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: bgColor,
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.white.withOpacity(0.7),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.15),
                    offset: const Offset(6, 6),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white,
                    offset: const Offset(-6, -6),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

/// Floating action card with hover effect
class FloatingCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final Color? backgroundColor;

  const FloatingCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.gradient,
    this.backgroundColor,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 8, end: 2).animate(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.xl);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: widget.gradient,
                color: widget.gradient == null
                    ? (widget.backgroundColor ??
                        (isDark ? AppColors.darkCard : Colors.white))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient != null
                        ? widget.gradient!.colors.first.withOpacity(0.3)
                        : Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                    blurRadius: _elevationAnimation.value * 2,
                    offset: Offset(0, _elevationAnimation.value),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
