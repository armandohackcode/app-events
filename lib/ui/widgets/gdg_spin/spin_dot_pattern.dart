import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/dot_pattern.dart';
import 'package:flutter/material.dart';

/// Subtle halftone dot grid painted behind the cabinet and celebration scrim.
class SpinDotPattern extends StatelessWidget {
  final Color color;

  const SpinDotPattern({super.key, this.color = AppStyles.spinDotPatternColor});

  @override
  Widget build(BuildContext context) {
    return DotPattern(color: color);
  }
}
