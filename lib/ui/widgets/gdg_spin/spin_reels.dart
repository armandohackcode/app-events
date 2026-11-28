import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_combo.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_bulb_ring.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_reel_strip.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Bezel, bulb ring, payline, and three synchronized [SpinReelStrip] columns.
class SpinReels extends StatefulWidget {
  final double cellSize;
  final List<List<SpinSymbol>> visible;
  final List<SpinSymbol>? pendingCombo;
  final int spinId;
  final bool spinning;
  final bool teasing;
  final bool hit;
  final Color winColor;
  final SpinBulbMode bulbMode;
  final VoidCallback onSecondStopped;
  final ValueChanged<List<List<SpinSymbol>>> onAllStopped;

  const SpinReels({
    super.key,
    required this.cellSize,
    required this.visible,
    required this.pendingCombo,
    required this.spinId,
    required this.spinning,
    required this.teasing,
    required this.hit,
    required this.winColor,
    required this.bulbMode,
    required this.onSecondStopped,
    required this.onAllStopped,
  });

  @override
  State<SpinReels> createState() => _SpinReelsState();
}

class _SpinReelsState extends State<SpinReels> {
  final Map<int, List<SpinSymbol>> _stoppedReels = {};
  late int _currentSpinId;

  @override
  void initState() {
    super.initState();
    _currentSpinId = widget.spinId;
  }

  @override
  void didUpdateWidget(covariant SpinReels oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinId != oldWidget.spinId) {
      _currentSpinId = widget.spinId;
      _stoppedReels.clear();
    }
  }

  void _handleReelStopped(int reelIndex, List<SpinSymbol> finals) {
    if (widget.spinId != _currentSpinId) return;
    _stoppedReels[reelIndex] = finals;
    if (reelIndex == 1) {
      widget.onSecondStopped();
    }
    if (_stoppedReels.length == 3) {
      final result = [_stoppedReels[0]!, _stoppedReels[1]!, _stoppedReels[2]!];
      _stoppedReels.clear();
      widget.onAllStopped(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final combo = widget.pendingCombo;
    final teasePlan =
        combo != null &&
        SpinCombo.canStillWin(combo[0], combo[1]) &&
        !reducedMotion;

    final middleNames = [
      widget.visible[0][1].accessibleName,
      widget.visible[1][1].accessibleName,
      widget.visible[2][1].accessibleName,
    ].join(', ');

    return Semantics(
      label: widget.spinning
          ? AppStrings.spinReelsSpinning
          : AppStrings.spinReelsSemantic(middleNames),
      child: HardShadowBox(
        color: AppStyles.spinBezelColor,
        shadowColor: AppStyles.spinCabinetInnerShadowColor,
        radius: 22,
        shadowOffset: 4,
        borderWidth: 2.5,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: SpinBulbRing(
                nx: 16,
                ny: 15,
                bulbSize: 7,
                inset: 5,
                borderWidth: 1,
                palette: AppStyles.spinBezelBulbPalette,
                mode: widget.bulbMode,
                winColor: widget.winColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppStyles.borderColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var r = 0; r < 3; r++) ...[
                          if (r > 0) const SizedBox(width: 5),
                          SpinReelStrip(
                            reelIndex: r,
                            cellSize: widget.cellSize,
                            initialVisible: widget.visible[r],
                            targetCombo: combo,
                            spinId: widget.spinId,
                            tease: teasePlan,
                            teasingActive: r == 2 && widget.teasing,
                            hit: widget.hit,
                            winColor: widget.winColor,
                            onStopped: (finals) =>
                                _handleReelStopped(r, finals),
                          ),
                        ],
                      ],
                    ),
                    Positioned(
                      left: 1,
                      right: 1,
                      child: IgnorePointer(child: _Payline(hit: widget.hit)),
                    ),
                    const Positioned(
                      left: -4,
                      child: IgnorePointer(
                        child: _PaylineArrow(pointsRight: true),
                      ),
                    ),
                    const Positioned(
                      right: -4,
                      child: IgnorePointer(
                        child: _PaylineArrow(pointsRight: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Payline extends StatelessWidget {
  final bool hit;
  const _Payline({required this.hit});

  @override
  Widget build(BuildContext context) {
    if (hit) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppStyles.spinPaylineHitColor,
          border: Border.all(color: AppStyles.borderColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return Container(
      height: 4,
      color: AppStyles.spinPaylineColor.withValues(alpha: 0.9),
    );
  }
}

class _PaylineArrow extends StatelessWidget {
  final bool pointsRight;
  const _PaylineArrow({required this.pointsRight});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 18),
      painter: _TrianglePainter(pointsRight: pointsRight),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final bool pointsRight;
  const _TrianglePainter({required this.pointsRight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppStyles.borderColor
      ..style = PaintingStyle.fill;
    final path = Path();
    if (pointsRight) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.pointsRight != pointsRight;
}
