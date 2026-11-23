import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

enum SpinBulbMode { idle, spinning, win, nearMiss }

/// Perimeter ring of marquee bulbs painted by a single [CustomPainter].
class SpinBulbRing extends StatefulWidget {
  final int nx;
  final int ny;
  final double bulbSize;
  final double inset;
  final double borderWidth;
  final Color borderColor;
  final List<Color> palette;
  final SpinBulbMode mode;
  final Color? winColor;

  const SpinBulbRing({
    super.key,
    required this.nx,
    required this.ny,
    required this.bulbSize,
    required this.inset,
    required this.palette,
    this.borderWidth = 1.5,
    this.borderColor = AppStyles.borderColor,
    this.mode = SpinBulbMode.idle,
    this.winColor,
  });

  @override
  State<SpinBulbRing> createState() => _SpinBulbRingState();
}

class _SpinBulbRingState extends State<SpinBulbRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _periodForMode => switch (widget.mode) {
    SpinBulbMode.idle => const Duration(milliseconds: 1200),
    SpinBulbMode.spinning => const Duration(milliseconds: 300),
    SpinBulbMode.win ||
    SpinBulbMode.nearMiss => const Duration(milliseconds: 320),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _periodForMode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant SpinBulbRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _controller.duration = _periodForMode;
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating || _controller.duration != _periodForMode) {
      _controller
        ..duration = _periodForMode
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BulbRingPainter(
            animation: _controller,
            nx: widget.nx,
            ny: widget.ny,
            bulbSize: widget.bulbSize,
            inset: widget.inset,
            borderWidth: widget.borderWidth,
            borderColor: widget.borderColor,
            palette: widget.palette,
            mode: widget.mode,
            winColor: widget.winColor,
            reducedMotion: reducedMotion,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BulbRingPainter extends CustomPainter {
  final Animation<double> animation;
  final int nx;
  final int ny;
  final double bulbSize;
  final double inset;
  final double borderWidth;
  final Color borderColor;
  final List<Color> palette;
  final SpinBulbMode mode;
  final Color? winColor;
  final bool reducedMotion;

  _BulbRingPainter({
    required this.animation,
    required this.nx,
    required this.ny,
    required this.bulbSize,
    required this.inset,
    required this.borderWidth,
    required this.borderColor,
    required this.palette,
    required this.mode,
    required this.winColor,
    required this.reducedMotion,
  }) : super(repaint: animation);

  Size? _cachedSize;
  List<Offset> _cachedCenters = const [];

  @override
  void paint(Canvas canvas, Size size) {
    if (size != _cachedSize) {
      _cachedSize = size;
      final left = inset;
      final top = inset;
      final right = size.width - inset;
      final bottom = size.height - inset;
      final width = right - left;
      final height = bottom - top;
      _cachedCenters = width <= 0 || height <= 0
          ? const []
          : [
              for (var k = 0; k < nx; k++)
                Offset(left + width * (k + 0.5) / nx, top),
              for (var k = 0; k < ny; k++)
                Offset(right, top + height * (k + 0.5) / ny),
              for (var k = 0; k < nx; k++)
                Offset(right - width * (k + 0.5) / nx, bottom),
              for (var k = 0; k < ny; k++)
                Offset(left, bottom - height * (k + 0.5) / ny),
            ];
    }
    final centers = _cachedCenters;
    if (centers.isEmpty) return;

    final t = animation.value;
    final baseRadius = bulbSize / 2;
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = borderColor;

    for (var i = 0; i < centers.length; i++) {
      var scale = 1.0;
      var opacity = 1.0;
      var glowAlpha = 0.0;
      late Color color;

      if (mode == SpinBulbMode.win || mode == SpinBulbMode.nearMiss) {
        color = mode == SpinBulbMode.win
            ? (winColor ?? palette[i % palette.length])
            : AppStyles.podiumThirdColor;
        if (!reducedMotion) {
          final wave =
              0.5 + 0.5 * math.sin((t * 2 + (i.isEven ? 0.0 : 0.5)) * math.pi);
          scale = 0.72 + 0.43 * wave;
          opacity = 0.35 + 0.65 * wave;
          glowAlpha = 0.38 * wave;
        }
      } else {
        color = palette[i % palette.length];
        if (!reducedMotion) {
          final delayFraction = mode == SpinBulbMode.spinning
              ? (i * 0.05) / 0.3
              : (i * 0.09) / 1.2;
          final phase = (t + delayFraction) % 1.0;
          final wave = 0.5 + 0.5 * math.sin(phase * 2 * math.pi);
          scale = (mode == SpinBulbMode.spinning ? 0.62 : 0.68) + 0.44 * wave;
          opacity = (mode == SpinBulbMode.spinning ? 0.45 : 0.55) + 0.45 * wave;
          glowAlpha = (mode == SpinBulbMode.spinning ? 0.36 : 0.22) * wave;
        }
      }

      final radius = baseRadius * scale;
      if (glowAlpha > 0.12) {
        glowPaint.color = color.withValues(alpha: glowAlpha);
        canvas.drawCircle(centers[i], radius * 1.5, glowPaint);
      }
      fillPaint.color = color.withValues(alpha: opacity);
      strokePaint.color = borderColor.withValues(alpha: opacity);

      canvas.drawCircle(centers[i], radius, fillPaint);
      canvas.drawCircle(centers[i], radius, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BulbRingPainter oldDelegate) =>
      oldDelegate.nx != nx ||
      oldDelegate.ny != ny ||
      oldDelegate.bulbSize != bulbSize ||
      oldDelegate.inset != inset ||
      oldDelegate.borderWidth != borderWidth ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.palette != palette ||
      oldDelegate.mode != mode ||
      oldDelegate.winColor != winColor ||
      oldDelegate.reducedMotion != reducedMotion;
}
