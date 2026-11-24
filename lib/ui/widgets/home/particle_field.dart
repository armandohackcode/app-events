import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/star_path.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Ambient particles drawn behind [child]. They drift and twinkle, move away
/// from the pointer and a tap makes a small burst. With the system "reduce
/// animations" setting they are drawn still.
class ParticleField extends StatefulWidget {
  final Widget child;
  const ParticleField({super.key, required this.child});

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  static const int _count = 140;
  static const int _reducedCount = 64;
  static const int _maxBursts = 45;
  static const double _pointerRadius = 185;
  static const List<Color> _palette = [
    AppStyles.particleBlueColor,
    AppStyles.particleDeepBlueColor,
    AppStyles.particleLightBlueColor,
    AppStyles.particleBlueColor,
    AppStyles.particleDeepBlueColor,
    AppStyles.colorBaseRed,
    AppStyles.colorBaseYellow,
    AppStyles.colorBaseGreen,
  ];
  static const List<Color> _burstPalette = [
    AppStyles.particleBlueColor,
    AppStyles.colorBaseRed,
    AppStyles.colorBaseYellow,
    AppStyles.colorBaseGreen,
    AppStyles.onAccentColor,
  ];

  final math.Random _random = math.Random();
  final List<_Particle> _particles = [];
  final List<_Burst> _bursts = [];
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker;
  Size _size = Size.zero;
  Offset? _pointer;
  Duration _lastTick = Duration.zero;
  double _time = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced != _reduced) {
      _reduced = reduced;
      _size = Size.zero;
    }
    if (_reduced) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _seed() {
    _particles.clear();
    final total = _reduced ? _reducedCount : _count;
    for (var i = 0; i < total; i++) {
      final x = _random.nextDouble() * _size.width;
      final y = _random.nextDouble() * _size.height;
      _particles.add(
        _Particle(
          anchorX: x,
          anchorY: y,
          radius: 1.1 + _random.nextDouble() * 1.9,
          baseOpacity: 0.34 + _random.nextDouble() * 0.48,
          phase: _random.nextDouble() * math.pi * 2,
          speed: 0.32 + _random.nextDouble() * 0.5,
          color: _palette[i % _palette.length],
          star: i % 4 == 0,
        ),
      );
    }
  }

  void _spawnBurst(Offset at) {
    if (_bursts.length >= _maxBursts) {
      _bursts.removeRange(0, _bursts.length - _maxBursts + 14);
    }
    const total = 14;
    for (var i = 0; i < total; i++) {
      final angle = (math.pi * 2 * i) / total + _random.nextDouble() * 0.4;
      final speed = 2.0 + _random.nextDouble() * 3.0;
      _bursts.add(
        _Burst(
          x: at.dx,
          y: at.dy,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          radius: 1.4 + _random.nextDouble() * 2.2,
          decay: 0.02 + _random.nextDouble() * 0.018,
          color: _burstPalette[i % _burstPalette.length],
          star: i % 2 == 0,
        ),
      );
    }
  }

  void _onTick(Duration elapsed) {
    // Physics are tuned for 60 fps; dt rescales them for other frame rates.
    final dt = ((elapsed - _lastTick).inMicroseconds / 16667).clamp(0.0, 3.0);
    _lastTick = elapsed;
    _time = elapsed.inMicroseconds / 1000000;
    final damping = math.pow(0.85, dt).toDouble();
    final pointer = _pointer;

    for (final p in _particles) {
      var targetX = p.anchorX + math.sin(_time * p.speed + p.phase) * 11;
      var targetY = p.anchorY + math.cos(_time * p.speed * 0.8 + p.phase) * 11;
      if (pointer != null) {
        final dx = p.x - pointer.dx;
        final dy = p.y - pointer.dy;
        final distance = math.sqrt(dx * dx + dy * dy);
        if (distance > 0 && distance < _pointerRadius) {
          final force = (1 - distance / _pointerRadius) * 3.2;
          targetX = p.x + dx / distance * force * 22;
          targetY = p.y + dy / distance * force * 22;
        }
      }
      p.vx = (p.vx + (targetX - p.x) * 0.045 * dt) * damping;
      p.vy = (p.vy + (targetY - p.y) * 0.045 * dt) * damping;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }

    final burstDamping = math.pow(0.94, dt).toDouble();
    for (var i = _bursts.length - 1; i >= 0; i--) {
      final b = _bursts[i];
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.vx *= burstDamping;
      b.vy *= burstDamping;
      b.life -= b.decay * dt;
      if (b.life <= 0) _bursts.removeAt(i);
    }
    _frame.value++;
  }

  void _setPointer(PointerEvent event) => _pointer = event.localPosition;

  void _onPointerDown(PointerDownEvent event) {
    _pointer = event.localPosition;
    if (!_reduced) _spawnBurst(event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    // A finger leaves the screen on release; a mouse keeps hovering.
    if (event.kind == PointerDeviceKind.touch) _pointer = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _size) {
          _size = size;
          _seed();
        }
        return MouseRegion(
          onExit: (_) => _pointer = null,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: _setPointer,
            onPointerMove: _setPointer,
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: (_) => _pointer = null,
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ParticlePainter(this, _frame),
                      ),
                    ),
                  ),
                ),
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  final double anchorX;
  final double anchorY;
  final double radius;
  final double baseOpacity;
  final double phase;
  final double speed;
  final Color color;
  final bool star;
  double x;
  double y;
  double vx = 0;
  double vy = 0;

  _Particle({
    required this.anchorX,
    required this.anchorY,
    required this.radius,
    required this.baseOpacity,
    required this.phase,
    required this.speed,
    required this.color,
    required this.star,
  }) : x = anchorX,
       y = anchorY;
}

class _Burst {
  final double decay;
  final double radius;
  final Color color;
  final bool star;
  double x;
  double y;
  double vx;
  double vy;
  double life = 1;

  _Burst({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.decay,
    required this.color,
    required this.star,
  });
}

class _ParticlePainter extends CustomPainter {
  final _ParticleFieldState field;

  _ParticlePainter(this.field, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in field._particles) {
      final twinkle =
          0.7 + 0.3 * math.sin(field._time * p.speed * 1.3 + p.phase);
      paint.color = p.color.withValues(
        alpha: (p.baseOpacity * twinkle).clamp(0.0, 1.0),
      );
      _dot(canvas, paint, p.x, p.y, p.radius, p.star, 2.6);
    }
    for (final b in field._bursts) {
      paint.color = b.color.withValues(alpha: b.life.clamp(0.0, 1.0));
      _dot(canvas, paint, b.x, b.y, b.radius, b.star, 2.2);
    }
  }

  void _dot(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double radius,
    bool star,
    double starScale,
  ) {
    if (!star) {
      canvas.drawCircle(Offset(x, y), radius, paint);
      return;
    }
    drawScaledFourPointStar(canvas, paint, x, y, radius * starScale);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => false;
}
