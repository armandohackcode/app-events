import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Section title drawn as a slightly tilted pill with a hard shadow.
class TitlePill extends StatelessWidget {
  final String text;
  final Color color;

  /// Tilt of the pill, in degrees.
  final double angle;

  const TitlePill({
    super.key,
    required this.text,
    this.color = AppStyles.titlePillColor,
    this.angle = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppStyles.borderColor, width: 2.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppStyles.fontColor,
          ),
        ),
      ),
    );
  }
}
