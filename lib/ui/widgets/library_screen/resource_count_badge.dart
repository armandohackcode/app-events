import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Tilted yellow sticker with four book spines and the number of resources.
class ResourceCountBadge extends StatelessWidget {
  final int count;
  const ResourceCountBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -3 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppStyles.colorBaseYellow,
          border: Border.all(color: AppStyles.borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BookSpines(),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              AppStrings.resourceLibraryCountLabel,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: AppStyles.fontColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookSpines extends StatelessWidget {
  const _BookSpines();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Spine(height: 14, color: AppStyles.colorBaseBlue),
          SizedBox(width: 2),
          _Spine(height: 20, color: AppStyles.cardColor),
          SizedBox(width: 2),
          _Spine(height: 12, color: AppStyles.colorBaseRed),
          SizedBox(width: 2),
          _Spine(height: 17, color: AppStyles.colorBaseGreen),
        ],
      ),
    );
  }
}

class _Spine extends StatelessWidget {
  final double height;
  final Color color;
  const _Spine({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
