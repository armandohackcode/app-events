import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Container with a crisp pop-brutalist dashed border, rounded or circular.
class DashedBorderBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Color borderColor;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final bool circle;
  final EdgeInsetsGeometry? padding;

  const DashedBorderBox({
    super.key,
    required this.child,
    this.color,
    this.borderColor = AppStyles.borderColor,
    this.radius = 12,
    this.strokeWidth = 2,
    this.dashLength = 6,
    this.gapLength = 4,
    this.circle = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return CustomPaint(
      painter: _DashedBorderPainter(
        borderColor: borderColor,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
        circle: circle,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
        child: content,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color borderColor;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final bool circle;

  const _DashedBorderPainter({
    required this.borderColor,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.circle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path();
    if (circle) {
      path.addOval(rect);
    } else {
      path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    }

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength ||
      oldDelegate.circle != circle;
}
