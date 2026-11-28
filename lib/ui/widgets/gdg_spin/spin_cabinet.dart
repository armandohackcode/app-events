import 'dart:async';
import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_beacon.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_bulb_ring.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_celebration.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_coin_tray.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_counters.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_dot_pattern.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_haptics.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_lever.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_reels.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_sign.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:flutter/material.dart';

/// Complete interactive slot machine cabinet for GDG SPIN.
class SpinCabinet extends StatefulWidget {
  final GdgSpinProvider provider;
  final VoidCallback onScrollToPayTable;

  const SpinCabinet({
    super.key,
    required this.provider,
    required this.onScrollToPayTable,
  });

  @override
  State<SpinCabinet> createState() => _SpinCabinetState();
}

class _SpinCabinetState extends State<SpinCabinet>
    with TickerProviderStateMixin {
  late final AnimationController _winBumpController;
  late final AnimationController _nearShakeController;
  SpinPhase _previousPhase = SpinPhase.idle;

  @override
  void initState() {
    super.initState();
    _winBumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _nearShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void didUpdateWidget(covariant SpinCabinet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkPhaseReaction();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPhaseReaction();
  }

  void _checkPhaseReaction() {
    final phase = widget.provider.phase;
    if (phase == _previousPhase) return;
    _previousPhase = phase;

    final reduced = MediaQuery.disableAnimationsOf(context);
    if (phase == SpinPhase.win || phase == SpinPhase.bonus) {
      unawaited(SpinHaptics.celebrateWin(isPrize: phase == SpinPhase.win));
      if (!reduced) {
        _winBumpController.repeat(reverse: true, count: 6);
      }
    } else if (phase == SpinPhase.nearMiss && !reduced) {
      _nearShakeController.repeat(reverse: true, count: 5);
    }
  }

  @override
  void dispose() {
    _winBumpController.dispose();
    _nearShakeController.dispose();
    super.dispose();
  }

  SpinBulbMode get _bulbMode => switch (widget.provider.phase) {
    SpinPhase.idle => SpinBulbMode.idle,
    SpinPhase.requesting || SpinPhase.spinning => SpinBulbMode.spinning,
    SpinPhase.win || SpinPhase.bonus => SpinBulbMode.win,
    SpinPhase.nearMiss => SpinBulbMode.nearMiss,
  };

  Color get _winAccent => switch (widget.provider.phase) {
    SpinPhase.win =>
      widget.provider.lastWinSymbol?.accentColor ??
          AppStyles.gdgBrandPalette[0],
    SpinPhase.bonus => AppStyles.gdgBrandPalette[1],
    _ => AppStyles.spinBezelColor,
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final spinning = p.phase == SpinPhase.spinning;
    final celebrating =
        p.phase == SpinPhase.win ||
        p.phase == SpinPhase.bonus ||
        p.phase == SpinPhase.nearMiss;
    final hit = p.phase == SpinPhase.win || p.phase == SpinPhase.bonus;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: AnimatedBuilder(
        animation: Listenable.merge([_winBumpController, _nearShakeController]),
        builder: (context, child) {
          final bump = _winBumpController.value;
          final dx = -4.0 * bump;
          final dy = -4.0 * bump;
          final shadow = 6.0 + 4.0 * bump;
          final shakeAngle = _nearShakeController.isAnimating
              ? ((_nearShakeController.value * 2 - 1) * 0.8 * math.pi / 180)
              : 0.0;

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: shakeAngle,
              child: Container(
                decoration: BoxDecoration(
                  color: AppStyles.spinCabinetColor,
                  border: Border.all(color: AppStyles.borderColor, width: 2.5),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.spinCabinetShadowColor,
                      offset: Offset(shadow, shadow),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27.5),
          child: Stack(
            children: [
              const Positioned.fill(
                child: SpinDotPattern(color: AppStyles.spinCabinetDotColor),
              ),
              Positioned.fill(
                child: SpinBulbRing(
                  nx: 15,
                  ny: 27,
                  bulbSize: 10,
                  inset: 10,
                  borderWidth: 1.5,
                  borderColor: AppStyles.spinCabinetBulbBorderColor,
                  palette: AppStyles.spinFrameBulbPalette,
                  mode: _bulbMode,
                  winColor: _winAccent,
                ),
              ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(child: SpinBeacon(fast: spinning || celebrating)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 54, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinSign(bulbMode: _bulbMode, winColor: _winAccent),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final reelsWidth = constraints.maxWidth - 50 - 8;
                        final cellSize =
                            ((reelsWidth - 2 * 13 - 2 * 2.5 - 2 * 5 - 2 * 5) /
                                    3)
                                .clamp(32.0, 96.0);
                        final reelsHeight =
                            cellSize * 3 + 2 * 5 + 2 * 13 + 2 * 2.5;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: SpinReels(
                                cellSize: cellSize,
                                visible: p.visible,
                                pendingCombo: p.pendingCombo,
                                spinId: p.spinId,
                                spinning: spinning,
                                teasing: p.teasing,
                                hit: hit,
                                winColor: _winAccent,
                                bulbMode: _bulbMode,
                                onSecondStopped: () =>
                                    p.secondReelStopped(reducedMotion: reduced),
                                onAllStopped: (finalVisible) =>
                                    p.reelsStopped(finalVisible: finalVisible),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SpinLever(
                              height: reelsHeight,
                              canPull: p.canPull,
                              tickets: p.tickets,
                              onPull: () => unawaited(p.pull()),
                              onBlockedPull: p.showBlockedPullHint,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SpinCounters(
                      tickets: p.tickets,
                      spins: p.spins,
                      message: p.message,
                      phase: p.phase,
                      lastOutcome: p.lastOutcome,
                      lastWinSymbol: p.lastWinSymbol,
                      customStatusMessage: p.customStatusMessage,
                    ),
                    const SizedBox(height: 12),
                    SpinCoinTray(
                      coins: p.coins,
                      onCollectCoins: p.collectCoins,
                      onScrollToPayTable: widget.onScrollToPayTable,
                    ),
                  ],
                ),
              ),
              if (celebrating)
                SpinCelebration(
                  phase: p.phase,
                  outcome: p.lastOutcome,
                  onFinished: p.celebrationDone,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
