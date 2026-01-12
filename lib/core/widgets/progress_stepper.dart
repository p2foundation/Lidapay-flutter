import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Modern progress stepper widget - reusable across all wizard flows
/// Eliminates duplicate progress indicator code in airtime/data screens
class ProgressStepper extends StatelessWidget {
  final List<String> steps;
  final int currentStep;
  final bool showLabels;
  final double stepSize;
  final Color? activeColor;
  final Color? completedColor;

  const ProgressStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    this.showLabels = true,
    this.stepSize = 36,
    this.activeColor,
    this.completedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = activeColor ?? AppColors.primary;
    final completed = completedColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                decoration: BoxDecoration(
                  gradient: stepBefore < currentStep
                      ? LinearGradient(
                          colors: [completed, primary],
                        )
                      : null,
                  color: stepBefore < currentStep
                      ? null
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
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: stepSize,
                height: stepSize,
                decoration: BoxDecoration(
                  gradient: isCompleted || isCurrent
                      ? AppColors.primaryGradient
                      : null,
                  color: isCompleted || isCurrent
                      ? null
                      : (isDark ? AppColors.darkSurface : AppColors.lightBg),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? Colors.transparent
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: 2,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: primary.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ).animate().scale(
                            duration: 200.ms,
                            curve: Curves.elasticOut,
                          )
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              if (showLabels) ...[
                const SizedBox(height: 6),
                Text(
                  steps[stepIndex],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isCurrent
                            ? primary
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// Compact dot progress indicator
class DotProgressIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final Color? activeColor;
  final Color? inactiveColor;
  final double dotSize;
  final double spacing;

  const DotProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.activeColor,
    this.inactiveColor,
    this.dotSize = 8,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = activeColor ?? AppColors.primary;
    final inactive = inactiveColor ??
        (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: isActive ? dotSize * 3 : dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            gradient: isActive || isCompleted
                ? LinearGradient(
                    colors: [active, active.withOpacity(0.8)],
                  )
                : null,
            color: isActive || isCompleted ? null : inactive,
            borderRadius: BorderRadius.circular(dotSize),
          ),
        );
      }),
    );
  }
}

/// Linear progress bar with gradient
class GradientProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const GradientProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.gradient,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: radius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: gradient ?? AppColors.primaryGradient,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: (gradient?.colors.first ?? AppColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Circular progress indicator with percentage
class CircularProgressWidget extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Widget? child;
  final bool showPercentage;

  const CircularProgressWidget({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.gradient,
    this.backgroundColor,
    this.child,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(bgColor),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return (gradient ?? AppColors.primaryGradient)
                        .createShader(bounds);
                  },
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeCap: StrokeCap.round,
                  ),
                );
              },
            ),
          ),
          // Center content
          Center(
            child: child ??
                (showPercentage
                    ? Text(
                        '${(progress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      )
                    : null),
          ),
        ],
      ),
    );
  }
}
