import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Slightly tilted card with a hard shadow and a small tilted [label] tag
/// resting on its top edge. With [speechTail] the card points down like a
/// speech bubble.
class LabeledCard extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Color labelTextColor;
  final Color color;
  final Widget child;
  final bool speechTail;

  /// Tilt of the label tag, in degrees.
  final double labelAngle;

  /// Tilt of the card, in degrees.
  final double angle;

  const LabeledCard({
    super.key,
    required this.label,
    required this.labelColor,
    required this.labelTextColor,
    required this.color,
    required this.child,
    this.speechTail = false,
    this.labelAngle = -2,
    this.angle = -0.6,
  });

  static const double _labelOverlap = 13;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _labelOverlap),
          child: Transform.rotate(
            angle: angle * math.pi / 180,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: AppStyles.borderColor, width: 2.5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: AppStyles.borderColor, offset: Offset(4, 4)),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                    child: child,
                  ),
                  if (speechTail)
                    Positioned(
                      left: 28,
                      bottom: -12,
                      child: CustomPaint(
                        size: const Size(20, 12),
                        painter: _TailPainter(color: color),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 10,
          right: 10,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.rotate(
              angle: labelAngle * math.pi / 180,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: labelColor,
                  border: Border.all(color: AppStyles.borderColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: AppStyles.borderColor,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: labelTextColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Downward triangle that continues the card: filled with the card color and
/// outlined only on its two slanted sides.
class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppStyles.borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
