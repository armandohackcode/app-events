import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Red tilted "LIVE" sticker with a white dot, put over the activity that is
/// happening right now.
class LiveBadge extends StatelessWidget {
  /// Tilt of the badge, in degrees.
  final double angle;

  const LiveBadge({super.key, this.angle = 20});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppStyles.colorBaseRed,
          border: Border.all(color: AppStyles.borderColor, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 7,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppStyles.onAccentColor,
                ),
              ),
            ),
            SizedBox(width: 5),
            Text(
              AppStrings.homeLiveBadge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppStyles.onAccentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
