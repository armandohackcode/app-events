import 'dart:math' as math;

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/home/particle_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Decorative background of the home screen: soft color glows, a dotted
/// pattern and floating particles behind [child]. The decoration never blocks
/// touches and stays fixed while the content scrolls.
class HomeBackdrop extends StatelessWidget {
  final Widget child;
  const HomeBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppStyles.homeBackgroundColor,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(child: IgnorePointer(child: _Glows())),
          Positioned.fill(child: ParticleField(child: child)),
        ],
      ),
    );
  }
}

class _Glows extends StatelessWidget {
  const _Glows();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        _Glow(
          top: -60,
          left: -60,
          size: 220,
          color: AppStyles.backdropBlueColor,
          alpha: 0.35,
          fadeStop: 0.7,
        ),
        _Glow(
          bottom: -80,
          left: -60,
          size: 260,
          color: AppStyles.colorBaseGreen,
          alpha: 0.35,
          fadeStop: 0.6,
        ),
        _Glow(
          bottom: -40,
          left: 10,
          size: 200,
          color: AppStyles.colorBaseRed,
          alpha: 0.3,
          fadeStop: 0.6,
        ),
        _Glow(
          top: 120,
          right: -70,
          size: 240,
          color: AppStyles.backdropBlueColor,
          alpha: 0.3,
          fadeStop: 0.65,
        ),
        Positioned(
          top: -20,
          right: -30,
          child: SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(painter: _DotsPainter()),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double alpha;
  final double fadeStop;

  const _Glow({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.alpha,
    required this.fadeStop,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
            stops: [0, fadeStop],
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppStyles.backdropBlueColor.withValues(alpha: 0.25);
    for (var x = 5.0; x < size.width; x += 10) {
      for (var y = 5.0; y < size.height; y += 10) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Sparkle and yellow bars drawn around the header. They belong to the scrolled
/// content, so they move away with it instead of staying on screen.
class HomeHeaderDecoration extends StatelessWidget {
  final Widget child;
  const HomeHeaderDecoration({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 4,
          left: -12,
          child: IgnorePointer(
            child: SvgPicture.asset(
              AppAssetsPath.backdropSparkle,
              width: 22,
              height: 22,
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -5,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: 8 * math.pi / 180,
              child: SvgPicture.asset(
                AppAssetsPath.backdropBars,
                width: 68,
                height: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
