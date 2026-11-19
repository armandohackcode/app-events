import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Top siren beacon on the slot cabinet with cycling colors and optional beam.
class SpinBeacon extends StatefulWidget {
  final bool fast;
  final bool compact;

  const SpinBeacon({super.key, this.fast = false, this.compact = false});

  @override
  State<SpinBeacon> createState() => _SpinBeaconState();
}

class _SpinBeaconState extends State<SpinBeacon> with TickerProviderStateMixin {
  late final AnimationController _beamController;
  late final AnimationController _colorController;

  Duration get _beamPeriod => widget.fast
      ? const Duration(milliseconds: 900)
      : const Duration(milliseconds: 4000);

  Duration get _colorPeriod {
    if (widget.compact) return const Duration(milliseconds: 2000);
    return widget.fast
        ? const Duration(milliseconds: 600)
        : const Duration(milliseconds: 2000);
  }

  @override
  void initState() {
    super.initState();
    _beamController = AnimationController(vsync: this, duration: _beamPeriod);
    _colorController = AnimationController(vsync: this, duration: _colorPeriod);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant SpinBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fast != widget.fast || oldWidget.compact != widget.compact) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _beamController.stop();
      _colorController.stop();
      _beamController.value = 0;
      _colorController.value = 0;
      return;
    }

    if (widget.compact) {
      _beamController.stop();
    } else if (!_beamController.isAnimating ||
        _beamController.duration != _beamPeriod) {
      _beamController
        ..duration = _beamPeriod
        ..repeat();
    }

    if (!_colorController.isAnimating ||
        _colorController.duration != _colorPeriod) {
      _colorController
        ..duration = _colorPeriod
        ..repeat();
    }
  }

  @override
  void dispose() {
    _beamController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 30.0 : 50.0;
    final height = widget.compact ? 22.0 : 38.0;
    final domePadding = widget.compact
        ? const EdgeInsets.fromLTRB(3, 0, 3, 5)
        : const EdgeInsets.fromLTRB(5, 0, 5, 8);
    final domeRadius = widget.compact
        ? const BorderRadius.vertical(
            top: Radius.circular(14),
            bottom: Radius.circular(3),
          )
        : const BorderRadius.vertical(
            top: Radius.circular(22),
            bottom: Radius.circular(4),
          );
    final baseHeight = widget.compact ? 7.0 : 10.0;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (!widget.compact)
                Positioned(
                  top: -115,
                  left: -105,
                  child: IgnorePointer(
                    child: RotationTransition(
                      turns: _beamController,
                      child: const _BeaconBeam(),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: domePadding,
                  child: AnimatedBuilder(
                    animation: _colorController,
                    builder: (context, _) {
                      final index = (_colorController.value * 4).floor() % 4;
                      return Container(
                        decoration: BoxDecoration(
                          color: AppStyles.gdgBrandPalette[index],
                          border: Border.all(
                            color: AppStyles.borderColor,
                            width: 2.5,
                          ),
                          borderRadius: domeRadius,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: widget.compact ? 8 : 13,
                top: widget.compact ? 4 : 6,
                child: Container(
                  width: widget.compact ? 5 : 7,
                  height: widget.compact ? 6 : 9,
                  decoration: const BoxDecoration(
                    color: AppStyles.onAccentColor,
                    borderRadius: BorderRadius.all(Radius.elliptical(7, 9)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: baseHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppStyles.cardColor,
                    border: Border.all(
                      color: AppStyles.borderColor,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeaconBeam extends StatelessWidget {
  const _BeaconBeam();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: SizedBox(
        width: 260,
        height: 260,
        child: CustomPaint(painter: _BeaconBeamPainter()),
      ),
    );
  }
}

class _BeaconBeamPainter extends CustomPainter {
  const _BeaconBeamPainter();

  static const _size = 260.0;
  static const _center = Offset(_size / 2, _size / 2);
  static const _radius = _size * 0.44;
  static final List<Path> _wedgeGroups = _buildWedgeGroups();
  static final List<Paint> _groupPaints = _buildGroupPaints();

  static List<Path> _buildWedgeGroups() {
    final paths = List.generate(4, (_) => Path());
    const wedgeSweep = 11 * math.pi / 180;
    for (var i = 0; i < 12; i++) {
      final startAngle = i * 30 * math.pi / 180;
      paths[i % 4]
        ..moveTo(_center.dx, _center.dy)
        ..arcTo(
          Rect.fromCircle(center: _center, radius: _radius),
          startAngle,
          wedgeSweep,
          false,
        )
        ..close();
    }
    return paths;
  }

  static List<Paint> _buildGroupPaints() {
    final bounds = Rect.fromCircle(center: _center, radius: _radius);
    return [
      for (var c = 0; c < 4; c++)
        Paint()
          ..style = PaintingStyle.fill
          ..shader = RadialGradient(
            colors: [
              AppStyles.gdgBrandPalette[c].withValues(alpha: 0.55),
              AppStyles.gdgBrandPalette[c].withValues(alpha: 0.0),
            ],
            stops: const [0.2, 1.0],
          ).createShader(bounds),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var c = 0; c < _wedgeGroups.length; c++) {
      canvas.drawPath(_wedgeGroups[c], _groupPaints[c]);
    }
  }

  @override
  bool shouldRepaint(covariant _BeaconBeamPainter oldDelegate) => false;
}
