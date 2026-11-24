import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Subtle halftone dot grid painted behind cards and graphic headers.
class DotPattern extends StatelessWidget {
  final Color color;
  final double step;
  final double dotRadius;

  const DotPattern({
    super.key,
    this.color = AppStyles.spinDotPatternColor,
    this.step = 9.0,
    this.dotRadius = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _DotPatternPainter(
            color: color,
            step: step,
            dotRadius: dotRadius,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;
  final double step;
  final double dotRadius;

  const _DotPatternPainter({
    required this.color,
    required this.step,
    required this.dotRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = step / 2; x < size.width; x += step) {
      for (var y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.step != step ||
      oldDelegate.dotRadius != dotRadius;
}
