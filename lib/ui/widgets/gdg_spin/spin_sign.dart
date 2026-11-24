import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_bulb_ring.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Marquee header displaying animated tilted GDG SPIN letter tiles inside a lit bezel.
class SpinSign extends StatefulWidget {
  final bool compact;
  final SpinBulbMode bulbMode;
  final Color winColor;

  const SpinSign({
    super.key,
    this.compact = false,
    this.bulbMode = SpinBulbMode.idle,
    this.winColor = AppStyles.colorBaseYellow,
  });

  @override
  State<SpinSign> createState() => _SpinSignState();
}

class _SpinSignState extends State<SpinSign>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _tilePalette = [
    _TileStyle(
      bg: AppStyles.backdropBlueColor,
      shadow: AppStyles.borderColor,
      angleDeg: -4,
      dy: 0,
    ),
    _TileStyle(
      bg: AppStyles.podiumThirdColor,
      shadow: AppStyles.borderColor,
      angleDeg: 3,
      dy: -1,
    ),
    _TileStyle(
      bg: AppStyles.colorBaseYellow,
      shadow: AppStyles.borderColor,
      angleDeg: -2,
      dy: 0,
    ),
    _TileStyle(
      bg: AppStyles.borderColor,
      shadow: AppStyles.podiumSecondColor,
      angleDeg: 2,
      dy: 0,
    ),
    _TileStyle(
      bg: AppStyles.borderColor,
      shadow: AppStyles.podiumSecondColor,
      angleDeg: -3,
      dy: 0,
    ),
    _TileStyle(
      bg: AppStyles.borderColor,
      shadow: AppStyles.podiumSecondColor,
      angleDeg: 2,
      dy: -1,
    ),
    _TileStyle(
      bg: AppStyles.borderColor,
      shadow: AppStyles.podiumSecondColor,
      angleDeg: -2,
      dy: 0,
    ),
  ];

  Duration get _period => switch (widget.bulbMode) {
    SpinBulbMode.idle => const Duration(milliseconds: 2400),
    SpinBulbMode.spinning => const Duration(milliseconds: 750),
    SpinBulbMode.win ||
    SpinBulbMode.nearMiss => const Duration(milliseconds: 650),
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant SpinSign oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bulbMode != widget.bulbMode) {
      _controller.duration = _period;
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
      return;
    }
    if (!_controller.isAnimating || _controller.duration != _period) {
      _controller
        ..duration = _period
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
    final compact = widget.compact;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final letters = AppStrings.spinTitle.replaceAll(' ', '');
    final width = compact ? 24.0 : 30.0;
    final height = compact ? 30.0 : 36.0;
    final fontSize = compact ? 15.0 : 20.0;
    final letterRadius = compact ? 6.0 : 7.0;
    final letterBorder = compact ? 1.5 : 2.0;
    final letterShadow = compact ? 1.5 : 2.0;
    final gap = compact ? 2.0 : 3.0;
    final wordGap = compact ? 5.0 : 7.0;

    final staticTiles = [
      for (var i = 0; i < _tilePalette.length; i++)
        _LetterTile(
          letter: letters[i],
          style: _tilePalette[i],
          width: width,
          height: height,
          fontSize: fontSize,
          radius: letterRadius,
          borderWidth: letterBorder,
          shadowOffset: letterShadow,
        ),
    ];

    return Semantics(
      header: true,
      container: true,
      excludeSemantics: true,
      label: AppStrings.spinTitle,
      child: HardShadowBox(
        color: AppStyles.cardColor,
        borderColor: AppStyles.borderColor,
        shadowColor: AppStyles.borderColor,
        radius: compact ? 14 : 18,
        shadowOffset: compact ? 3 : 4,
        borderWidth: compact ? 2 : 2.5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: SpinBulbRing(
                nx: compact ? 16 : 20,
                ny: 3,
                bulbSize: compact ? 5 : 7,
                inset: compact ? 4 : 6,
                borderWidth: 1,
                palette: AppStyles.gdgBrandPalette,
                mode: widget.bulbMode,
                winColor: widget.winColor,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: compact ? 11 : 16,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = reducedMotion ? 0.0 : _controller.value;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < staticTiles.length; i++) ...[
                            if (i > 0) SizedBox(width: i == 3 ? wordGap : gap),
                            _transformTile(
                              index: i,
                              progress: t,
                              reducedMotion: reducedMotion,
                              compact: compact,
                              child: staticTiles[i],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transformTile({
    required int index,
    required double progress,
    required bool reducedMotion,
    required bool compact,
    required Widget child,
  }) {
    if (reducedMotion) return child;

    final phase = (progress + index * 0.13) % 1.0;
    final wave = math.sin(phase * 2 * math.pi);
    final amplitude = compact ? 0.72 : 1.0;

    final (double dy, double dAngle, double scale) = switch (widget.bulbMode) {
      SpinBulbMode.idle => (
        wave * 2.4 * amplitude,
        wave * 0.032,
        1.0 + 0.03 * math.max(0.0, wave),
      ),
      SpinBulbMode.spinning => (
        wave * 3.5 * amplitude,
        wave * 0.055,
        1.0 + 0.06 * (0.5 + 0.5 * wave),
      ),
      SpinBulbMode.win || SpinBulbMode.nearMiss => (
        -wave.abs() * 4.2 * amplitude,
        wave * 0.06,
        1.0 + 0.08 * (0.5 + 0.5 * wave),
      ),
    };

    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: dAngle,
        child: Transform.scale(scale: scale, child: child),
      ),
    );
  }
}

class _TileStyle {
  final Color bg;
  final Color shadow;
  final double angleDeg;
  final double dy;

  const _TileStyle({
    required this.bg,
    required this.shadow,
    required this.angleDeg,
    required this.dy,
  });
}

class _LetterTile extends StatelessWidget {
  final String letter;
  final _TileStyle style;
  final double width;
  final double height;
  final double fontSize;
  final double radius;
  final double borderWidth;
  final double shadowOffset;

  const _LetterTile({
    required this.letter,
    required this.style,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.radius,
    required this.borderWidth,
    required this.shadowOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, style.dy),
      child: Transform.rotate(
        angle: style.angleDeg * math.pi / 180,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: style.bg,
            border: Border.all(
              color: AppStyles.borderColor,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(
                color: style.shadow,
                offset: Offset(shadowOffset, shadowOffset),
              ),
            ],
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
              color: AppStyles.onAccentColor,
            ),
          ),
        ),
      ),
    );
  }
}
