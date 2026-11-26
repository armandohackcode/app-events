import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Geometric `{ DevFest [Sucre] }` event emblem with gradient curly braces.
class DevFestLogo extends StatelessWidget {
  const DevFestLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: _CurlyBrace(
                colors: [AppStyles.backdropBlueColor, AppStyles.colorBaseRed],
              ),
            ),
            const SizedBox(width: 11),
            IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    AppStrings.signInEventName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'GoogleSans',
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.0,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 36,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppStyles.cardColor.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppStyles.fontSecondaryColor.withValues(
                          alpha: 0.7,
                        ),
                        width: 1.0,
                      ),
                    ),
                    child: const Text(
                      AppStrings.signInCommunityCity,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'GoogleSans',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: _CurlyBrace(
                colors: [AppStyles.colorBaseYellow, AppStyles.colorBaseGreen],
                isRight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurlyBrace extends StatelessWidget {
  final List<Color> colors;
  final bool isRight;

  const _CurlyBrace({required this.colors, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(25, 87),
      painter: _CurlyBracePainter(colors: colors, isRight: isRight),
    );
  }
}

class _CurlyBracePainter extends CustomPainter {
  final List<Color> colors;
  final bool isRight;

  const _CurlyBracePainter({required this.colors, required this.isRight});

  // Canonical brace geometry designed on a 25x87 grid and scaled to canvas size.
  static const double _designWidth = 25;
  static const double _designHeight = 87;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppStyles.borderColor
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;

    final sx = size.width / _designWidth;
    final sy = size.height / _designHeight;
    final path = _buildLeftBracePath(sx, sy);

    canvas.save();
    if (isRight) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
    canvas.restore();
  }

  Path _buildLeftBracePath(double sx, double sy) {
    const t = 9.5;
    const nibProtrusion = 5.0;
    const stemInnerX = nibProtrusion + t;
    const outerR = 11.5;
    const innerR = outerR - t;
    const midY = _designHeight / 2;

    Offset p(double x, double y) => Offset(x * sx, y * sy);
    Radius r(double radius) => Radius.elliptical(radius * sx, radius * sy);

    return Path()
      ..moveTo(_designWidth * sx, 0)
      ..lineTo((nibProtrusion + outerR) * sx, 0)
      ..arcToPoint(
        p(nibProtrusion, outerR),
        radius: r(outerR),
        clockwise: false,
      )
      ..lineTo(nibProtrusion * sx, (midY - 6.8) * sy)
      ..quadraticBezierTo(
        nibProtrusion * sx,
        (midY - 5.0) * sy,
        (nibProtrusion - 1.5) * sx,
        (midY - 5.0) * sy,
      )
      ..lineTo(1.2 * sx, (midY - 5.0) * sy)
      ..quadraticBezierTo(0, (midY - 5.0) * sy, 0, (midY - 3.8) * sy)
      ..lineTo(0, (midY + 3.8) * sy)
      ..quadraticBezierTo(0, (midY + 5.0) * sy, 1.2 * sx, (midY + 5.0) * sy)
      ..lineTo((nibProtrusion - 1.5) * sx, (midY + 5.0) * sy)
      ..quadraticBezierTo(
        nibProtrusion * sx,
        (midY + 5.0) * sy,
        nibProtrusion * sx,
        (midY + 6.8) * sy,
      )
      ..lineTo(nibProtrusion * sx, (_designHeight - outerR) * sy)
      ..arcToPoint(
        p(nibProtrusion + outerR, _designHeight),
        radius: r(outerR),
        clockwise: false,
      )
      ..lineTo(_designWidth * sx, _designHeight * sy)
      ..lineTo(_designWidth * sx, (_designHeight - t) * sy)
      ..lineTo((nibProtrusion + outerR) * sx, (_designHeight - t) * sy)
      ..arcToPoint(
        p(stemInnerX, _designHeight - outerR),
        radius: r(innerR),
        clockwise: true,
      )
      ..lineTo(stemInnerX * sx, outerR * sy)
      ..arcToPoint(
        p(nibProtrusion + outerR, t),
        radius: r(innerR),
        clockwise: true,
      )
      ..lineTo(_designWidth * sx, t * sy)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _CurlyBracePainter oldDelegate) =>
      oldDelegate.isRight != isRight ||
      oldDelegate.colors.length != colors.length ||
      !_sameColors(oldDelegate.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
