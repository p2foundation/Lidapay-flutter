import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Modern animated button with haptic feedback and press animations
/// Gen Z style - bouncy, responsive, and satisfying to tap
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool hapticFeedback;
  final EdgeInsetsGeometry? padding;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 56,
    this.borderRadius,
    this.isLoading = false,
    this.hapticFeedback = true,
    this.padding,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
      if (widget.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isDisabled ? 0.6 : 1.0,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: widget.gradient ??
                      (isDisabled
                          ? LinearGradient(
                              colors: [
                                (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder)
                                    .withOpacity(0.8),
                                isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ],
                            )
                          : AppColors.primaryGradient),
                  color: widget.gradient == null ? widget.backgroundColor : null,
                  boxShadow: isDisabled
                      ? null
                      : [
                          BoxShadow(
                            color: (widget.gradient?.colors.first ??
                                    widget.backgroundColor ??
                                    AppColors.primary)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.foregroundColor ?? Colors.white,
                            ),
                          ),
                        )
                      : DefaultTextStyle(
                          style: TextStyle(
                            color: widget.foregroundColor ?? Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          child: IconTheme(
                            data: IconThemeData(
                              color: widget.foregroundColor ?? Colors.white,
                              size: 20,
                            ),
                            child: widget.child,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Outlined button variant with animated border
class AnimatedOutlinedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? borderColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final double borderWidth;

  const AnimatedOutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderColor,
    this.foregroundColor,
    this.width,
    this.height = 56,
    this.borderRadius,
    this.isLoading = false,
    this.borderWidth = 2,
  });

  @override
  State<AnimatedOutlinedButton> createState() => _AnimatedOutlinedButtonState();
}

class _AnimatedOutlinedButtonState extends State<AnimatedOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final color = widget.borderColor ?? AppColors.primary;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) {
          _controller.forward();
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        _controller.reverse();
        if (!isDisabled) widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isDisabled ? 0.6 : 1.0,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: color,
                    width: widget.borderWidth,
                  ),
                  color: isDark
                      ? AppColors.darkCard.withOpacity(0.5)
                      : Colors.white,
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        )
                      : DefaultTextStyle(
                          style: TextStyle(
                            color: widget.foregroundColor ?? color,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          child: IconTheme(
                            data: IconThemeData(
                              color: widget.foregroundColor ?? color,
                              size: 20,
                            ),
                            child: widget.child,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Icon button with ripple and scale animation
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final LinearGradient? gradient;
  final String? badge;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.gradient,
    this.badge,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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

    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    color: widget.gradient == null
                        ? (widget.backgroundColor ??
                            (isDark ? AppColors.darkCard : Colors.white))
                        : null,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ??
                        (widget.gradient != null
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkText
                                : AppColors.lightText)),
                    size: widget.size * 0.5,
                  ),
                ),
                if (widget.badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        widget.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
