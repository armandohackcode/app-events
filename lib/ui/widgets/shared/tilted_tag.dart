import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Colored section pill rotated slightly to sit over the top edge of a card.
class TiltedTag extends StatelessWidget {
  final String text;
  final Color color;
  final double angleDegrees;
  final bool compact;

  const TiltedTag({
    super.key,
    required this.text,
    required this.color,
    this.angleDegrees = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDegrees * math.pi / 180,
      child: HardShadowBox(
        color: color,
        radius: 999,
        shadowOffset: compact ? 2.5 : 3,
        borderWidth: compact ? 2 : 2.5,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: compact ? 12 : 15,
            fontWeight: FontWeight.w800,
            color: AppStyles.fontColor,
          ),
        ),
      ),
    );
  }
}

/// Positions a [TiltedTag] overlapping the top-left edge of [child].
class TaggedCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final double angleDegrees;
  final bool compact;
  final Widget child;

  const TaggedCard({
    super.key,
    required this.tag,
    required this.tagColor,
    required this.angleDegrees,
    this.compact = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.only(top: compact ? 20 : 28),
          child: child,
        ),
        Positioned(
          top: 0,
          left: compact ? 10 : 12,
          child: TiltedTag(
            text: tag,
            color: tagColor,
            angleDegrees: angleDegrees,
            compact: compact,
          ),
        ),
      ],
    );
  }
}
