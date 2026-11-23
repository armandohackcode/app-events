import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Pop-brutalist container with a crisp dark border and zero-blur offset shadow.
class HardShadowBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double radius;
  final double shadowOffset;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;

  const HardShadowBox({
    super.key,
    required this.child,
    this.color = AppStyles.cardColor,
    this.borderColor = AppStyles.borderColor,
    this.shadowColor = AppStyles.borderColor,
    this.radius = 20,
    this.shadowOffset = 4,
    this.borderWidth = 2.5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadowOffset > 0
            ? [
                BoxShadow(
                  color: shadowColor,
                  offset: Offset(shadowOffset, shadowOffset),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
