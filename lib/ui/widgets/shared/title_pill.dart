import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Section title drawn as a slightly tilted pill with a hard shadow.
class TitlePill extends StatelessWidget {
  final String text;
  final Color color;

  /// Tilt of the pill, in degrees.
  final double angle;

  /// Optional widget placed after [text] inside the pill (e.g. a count badge).
  final Widget? trailing;

  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final double shadowOffset;
  final double borderRadius;

  const TitlePill({
    super.key,
    required this.text,
    this.color = AppStyles.titlePillColor,
    this.angle = 1.5,
    this.trailing,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    this.borderWidth = 2.5,
    this.shadowOffset = 3,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppStyles.borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppStyles.borderColor,
              offset: Offset(shadowOffset, shadowOffset),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: AppStyles.fontColor,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}
