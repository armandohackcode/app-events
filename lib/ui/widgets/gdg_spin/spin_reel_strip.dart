import 'dart:math';
import 'dart:ui';

import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/dashed_line.dart';
import 'package:flutter/material.dart';

/// Single animated reel column showing three square symbol cells.
class SpinReelStrip extends StatefulWidget {
  final int reelIndex;
  final double cellSize;
  final List<SpinSymbol> initialVisible;
  final List<SpinSymbol>? targetCombo;
  final int spinId;
  final bool tease;
  final bool teasingActive;
  final bool hit;
  final Color winColor;
  final ValueChanged<List<SpinSymbol>> onStopped;

  const SpinReelStrip({
    super.key,
    required this.reelIndex,
    required this.cellSize,
    required this.initialVisible,
    required this.targetCombo,
    required this.spinId,
    required this.tease,
    required this.teasingActive,
    required this.hit,
    required this.winColor,
    required this.onStopped,
  });

  @override
  State<SpinReelStrip> createState() => _SpinReelStripState();
}

class _SpinReelStripState extends State<SpinReelStrip>
    with TickerProviderStateMixin {
  final Random _random = Random();
  late AnimationController _spinController;
  late AnimationController _teaseController;
  late AnimationController _hitController;
  late Animation<double> _offsetAnimation;
  late List<SpinSymbol> _strip;
  late List<SpinSymbol> _finals;
  int _activeSpinId = 0;

  @override
  void initState() {
    super.initState();
    _strip = List<SpinSymbol>.from(widget.initialVisible);
    _finals = List<SpinSymbol>.from(widget.initialVisible);
    _spinController = AnimationController(vsync: this);
    _offsetAnimation = const AlwaysStoppedAnimation<double>(0);
    _teaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _hitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTeaseAndHit();
    if (widget.spinId > 0 &&
        widget.spinId != _activeSpinId &&
        widget.targetCombo != null) {
      _startSpin(setStateOnStart: false);
    }
  }

  @override
  void didUpdateWidget(covariant SpinReelStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinId != oldWidget.spinId &&
        widget.spinId != _activeSpinId &&
        widget.targetCombo != null) {
      _startSpin();
    }
    if (oldWidget.teasingActive != widget.teasingActive ||
        oldWidget.hit != widget.hit) {
      _syncTeaseAndHit();
    }
  }

  void _syncTeaseAndHit() {
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (widget.teasingActive && !reduced) {
      if (!_teaseController.isAnimating) {
        _teaseController.repeat();
      }
    } else {
      _teaseController.stop();
      _teaseController.value = 0;
    }

    if (widget.hit && !reduced) {
      if (!_hitController.isAnimating) {
        _hitController.repeat(reverse: true, count: 4);
      }
    } else {
      _hitController.stop();
      _hitController.value = 0;
    }
  }

  void _startSpin({bool setStateOnStart = true}) {
    _activeSpinId = widget.spinId;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final reel = widget.reelIndex;
    final isTeaseReel = reel == 2 && widget.tease;
    final length = (isTeaseReel ? 46 : 22) + reel * 8;

    final target = widget.targetCombo![reel];
    final current = _finals.length == 3 ? _finals : widget.initialVisible;
    final finals = [_randomFillSymbol(), target, _randomFillSymbol()];
    final middleCount = length - 6;
    final strip = <SpinSymbol>[
      ...finals,
      for (var i = 0; i < middleCount; i++) _randomFillSymbol(),
      ...current,
    ];

    final spinMs = reduced
        ? [350, 450, 550][reel]
        : [1300, 1800, isTeaseReel ? 4100 : 2300][reel];
    const settleMs = 220;

    _spinController.stop();
    _spinController.duration = Duration(milliseconds: spinMs + settleMs);
    final from = -(strip.length - 3) * widget.cellSize;

    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: from,
          end: 13.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: spinMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 13.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: settleMs.toDouble(),
      ),
    ]).animate(_spinController);

    if (setStateOnStart) {
      setState(() {
        _strip = strip;
        _finals = finals;
      });
    } else {
      _strip = strip;
      _finals = finals;
    }

    final launchedSpinId = _activeSpinId;
    _spinController.forward(from: 0).then((_) {
      if (!mounted || launchedSpinId != _activeSpinId) return;
      setState(() {
        _strip = List<SpinSymbol>.from(finals);
        _offsetAnimation = const AlwaysStoppedAnimation<double>(0);
      });
      widget.onStopped(finals);
    });
  }

  SpinSymbol _randomFillSymbol() {
    const pool = GdgSpinProvider.fillSymbols;
    return pool[_random.nextInt(pool.length)];
  }

  @override
  void dispose() {
    _spinController.dispose();
    _teaseController.dispose();
    _hitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final cell = widget.cellSize;

    return AnimatedBuilder(
      animation: Listenable.merge([_teaseController, _hitController]),
      builder: (context, child) {
        final teasePhase = widget.teasingActive && !reduced
            ? (_teaseController.value < 0.5)
            : false;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: teasePhase ? AppStyles.spinTeaseColor : AppStyles.cardColor,
            borderRadius: BorderRadius.circular(9),
            border: teasePhase
                ? Border.all(color: AppStyles.podiumThirdColor, width: 3)
                : null,
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: cell,
          height: cell * 3,
          child: Stack(
            children: [
              if (widget.hit)
                Positioned(
                  top: cell,
                  left: 0,
                  right: 0,
                  height: cell,
                  child: ColoredBox(
                    color: widget.winColor.withValues(alpha: 0.35),
                  ),
                ),
              RepaintBoundary(
                child: SizedBox(
                  width: cell,
                  height: cell * 3,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _spinController,
                      _hitController,
                    ]),
                    builder: (context, _) {
                      final fastSpin =
                          _spinController.isAnimating &&
                          _spinController.value < 0.72 &&
                          !reduced;
                      final hitValue = widget.hit && !reduced
                          ? _hitController.value
                          : 0.0;
                      final offsetY = _offsetAnimation.value;
                      final firstIdx = max(
                        0,
                        min(_strip.length - 1, (-offsetY / cell).floor()),
                      );
                      final lastIdx = min(_strip.length - 1, firstIdx + 4);

                      return Transform.scale(
                        scaleX: fastSpin ? 0.96 : 1.0,
                        scaleY: fastSpin ? 1.06 : 1.0,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (var i = firstIdx; i <= lastIdx; i++)
                              Positioned(
                                top: offsetY + i * cell,
                                left: 0,
                                right: 0,
                                height: cell,
                                child: _ReelCell(
                                  symbol: _strip[i],
                                  size: cell,
                                  slotIndex: widget.reelIndex,
                                  hitProgress: (widget.hit && i == 1)
                                      ? hitValue
                                      : 0.0,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: cell,
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(color: AppStyles.spinReelDimColor),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: DashedLine(strokeWidth: 2),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: cell,
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(color: AppStyles.spinReelDimColor),
                      ),
                      const Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: DashedLine(strokeWidth: 2),
                      ),
                    ],
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

class _ReelCell extends StatelessWidget {
  final SpinSymbol symbol;
  final double size;
  final int slotIndex;
  final double hitProgress;

  const _ReelCell({
    required this.symbol,
    required this.size,
    required this.slotIndex,
    required this.hitProgress,
  });

  @override
  Widget build(BuildContext context) {
    final easedHit = Curves.easeInOut.transform(hitProgress);
    final scale = lerpDouble(1.0, 1.32, easedHit) ?? 1.0;
    final angle = lerpDouble(0.0, -7 * pi / 180, easedHit) ?? 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: scale,
            child: SpinSymbolArt(
              symbol: symbol,
              size: size * 0.72,
              slotIndex: slotIndex,
            ),
          ),
        ),
      ),
    );
  }
}
