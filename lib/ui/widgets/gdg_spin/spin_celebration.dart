import 'dart:async';
import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_dot_pattern.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/star_path.dart';
import 'package:flutter/material.dart';

/// Full-cabinet celebration overlay for win, bonus, and near-miss states.
class SpinCelebration extends StatefulWidget {
  final SpinPhase phase;
  final SpinOutcome? outcome;
  final VoidCallback onFinished;

  const SpinCelebration({
    super.key,
    required this.phase,
    required this.outcome,
    required this.onFinished,
  });

  @override
  State<SpinCelebration> createState() => _SpinCelebrationState();
}

class _SpinCelebrationState extends State<SpinCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _raysController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _opacityAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _raysController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );
    const entryCurve = Cubic(0.34, 1.56, 0.64, 1);
    _scaleAnimation = Tween<double>(
      begin: 1.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _entryController, curve: entryCurve));
    _rotationAnimation = Tween<double>(
      begin: 10 * math.pi / 180,
      end: 0,
    ).animate(CurvedAnimation(parent: _entryController, curve: entryCurve));
    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restart();
  }

  @override
  void didUpdateWidget(covariant SpinCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.outcome != widget.outcome) {
      _restart();
    }
  }

  void _restart() {
    _dismissTimer?.cancel();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _entryController.value = 1.0;
      _raysController.stop();
      _raysController.value = 0;
    } else {
      _entryController.forward(from: 0);
      _raysController.repeat();
    }

    final durationMs = reduced
        ? 300
        : switch (widget.phase) {
            SpinPhase.win => 1800,
            SpinPhase.bonus => 1300,
            SpinPhase.nearMiss => 900,
            _ => 900,
          };

    _dismissTimer = Timer(Duration(milliseconds: durationMs), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _entryController.dispose();
    _raysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (
      title,
      symbol,
      imageUrl,
      subtitle,
      accentColor,
    ) = switch (widget.phase) {
      SpinPhase.win when widget.outcome is SpinPrizeOutcome => (
        AppStrings.spinWinTitle,
        (widget.outcome as SpinPrizeOutcome).prize.symbol,
        (widget.outcome as SpinPrizeOutcome).prize.imageUrl,
        (widget.outcome as SpinPrizeOutcome).prize.name,
        (widget.outcome as SpinPrizeOutcome).prize.symbol.accentColor,
      ),
      SpinPhase.bonus when widget.outcome is SpinBonusOutcome => (
        AppStrings.spinBonusTitle,
        SpinSymbol.mysteryBox,
        null,
        AppStrings.spinReward((widget.outcome as SpinBonusOutcome).tickets),
        AppStyles.gdgBrandPalette[1],
      ),
      _ => (
        AppStrings.spinNearTitle,
        null,
        null,
        null,
        AppStyles.spinNearMissColor,
      ),
    };

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: AppStyles.gamesBackgroundColor,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(child: SpinDotPattern()),
              OverflowBox(
                maxWidth: 640,
                maxHeight: 640,
                child: RotationTransition(
                  turns: _raysController,
                  child: _CelebrationRays(color: accentColor),
                ),
              ),
              if (symbol != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _CelebrationSparkles(
                      animation: _raysController,
                      reducedMotion: MediaQuery.disableAnimationsOf(context),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, child) => Opacity(
                      opacity: _opacityAnimation.value.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: -4 * math.pi / 180,
                          child: HardShadowBox(
                            color: AppStyles.cardColor,
                            radius: 14,
                            shadowOffset: 5,
                            borderWidth: 2.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                title,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppStyles.fontColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (symbol != null) ...[
                          const SizedBox(height: 12),
                          HardShadowBox(
                            color: AppStyles.cardColor,
                            radius: 26,
                            shadowOffset: 6,
                            borderWidth: 2.5,
                            child: SizedBox(
                              width: 108,
                              height: 108,
                              child: Center(
                                child: SpinPrizeThumbnail(
                                  symbol: symbol,
                                  imageUrl: imageUrl,
                                  size: 92,
                                  fallbackSize: 78,
                                  borderRadius: 20,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (subtitle != null) ...[
                          const SizedBox(height: 12),
                          Transform.rotate(
                            angle: 2 * math.pi / 180,
                            child: HardShadowBox(
                              color: AppStyles.spinBezelColor,
                              radius: 12,
                              shadowOffset: 4,
                              borderWidth: 2.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              child: Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppStyles.fontColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

class _CelebrationRays extends StatelessWidget {
  final Color color;
  const _CelebrationRays({required this.color});

  static List<Color> _buildColors(Color color) {
    final tinted = color.withValues(alpha: 0.72);
    return [
      for (var i = 0; i < 15; i++) ...[
        tinted,
        tinted,
        Colors.transparent,
        Colors.transparent,
      ],
    ];
  }

  static final List<double> _stops = [
    for (var i = 0; i < 15; i++) ...[
      (i * 24) / 360.0,
      (i * 24 + 10) / 360.0,
      (i * 24 + 10) / 360.0,
      math.min(1.0, (i + 1) * 24 / 360.0),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 640,
      height: 640,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: _buildColors(color), stops: _stops),
        ),
      ),
    );
  }
}

class _CelebrationSparkles extends StatelessWidget {
  final Animation<double> animation;
  final bool reducedMotion;

  const _CelebrationSparkles({
    required this.animation,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    if (reducedMotion) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _SparklesPainter(progress: animation.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SparklesPainter extends CustomPainter {
  final double progress;

  const _SparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = math.min(size.width, size.height) * 0.34;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final phase = (progress * 3 + i / 12) % 1.0;
      final pulse = 0.55 + 0.45 * math.sin(phase * 2 * math.pi);
      final angle = (i * math.pi * 2 / 12) + progress * math.pi * 2;
      final orbit = baseRadius + math.sin(phase * math.pi * 2) * 14;
      final pos = Offset(
        center.dx + math.cos(angle) * orbit,
        center.dy + math.sin(angle) * orbit,
      );
      final color =
          AppStyles.gdgBrandPalette[i % AppStyles.gdgBrandPalette.length];
      paint.color = color.withValues(alpha: (0.45 + 0.5 * pulse).clamp(0, 1));
      final r = 4.0 + 3.5 * pulse;
      drawScaledFourPointStar(canvas, paint, pos.dx, pos.dy, r);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
