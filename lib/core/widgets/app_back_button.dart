import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double iconSize;
  final double size;
  final double hitSize;
  final BorderRadius? borderRadius;
  final IconData icon;
  final bool enableHaptics;
  final bool enabled;

  const AppBackButton({
    super.key,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.boxShadow,
    this.iconSize = 22,
    this.size = 44,
    this.hitSize = 48,
    this.borderRadius,
    this.icon = Icons.arrow_back_rounded,
    this.enableHaptics = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedOnTap = onTap ?? () => Navigator.of(context).maybePop();
    final resolvedBorderRadius = borderRadius ?? BorderRadius.circular(AppRadius.md);
    final resolvedIconColor = iconColor ?? Theme.of(context).iconTheme.color;

    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: enabled
            ? () {
                if (enableHaptics) {
                  HapticFeedback.selectionClick();
                }
                resolvedOnTap();
              }
            : null,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        borderRadius: resolvedBorderRadius,
        radius: hitSize / 2,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: resolvedBorderRadius,
                boxShadow: boxShadow,
              ),
              child: Icon(
                icon,
                color: resolvedIconColor,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
