import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_beacon.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_bulb_ring.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_dot_pattern.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_sign.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_tickets_pill.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Pop-brutalist entry card for GDG SPIN featuring a compact preview cabinet.
class ActivitySpinCard extends StatelessWidget {
  final int tickets;
  final VoidCallback onTap;

  const ActivitySpinCard({
    super.key,
    required this.tickets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 20,
      shadowOffset: 5,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.spinTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
              SpinTicketsPill(tickets: tickets),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.activitiesSpinDescription,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(onTap: onTap, child: const SpinMiniMachine()),
          const SizedBox(height: 12),
          ChunkyButton(
            label: AppStrings.playLabel,
            color: AppStyles.spinBezelColor,
            expand: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

/// Compact non-draggable miniature preview of the GDG SPIN cabinet.
class SpinMiniMachine extends StatelessWidget {
  const SpinMiniMachine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.spinCabinetColor,
        border: Border.all(color: AppStyles.borderColor, width: 2.5),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppStyles.spinCabinetShadowColor,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19.5),
        child: Stack(
          children: [
            const Positioned.fill(
              child: SpinDotPattern(color: AppStyles.spinCabinetDotColor),
            ),
            Positioned.fill(
              child: SpinBulbRing(
                nx: 10,
                ny: 14,
                bulbSize: 7,
                inset: 8,
                borderWidth: 1.5,
                borderColor: AppStyles.spinCabinetBulbBorderColor,
                palette: AppStyles.spinFrameBulbPalette,
              ),
            ),
            const Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(child: SpinBeacon(compact: true)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 34, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinSign(compact: true),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _MiniReels()),
                      const SizedBox(width: 8),
                      const _MiniLever(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniReels extends StatefulWidget {
  const _MiniReels();

  @override
  State<_MiniReels> createState() => _MiniReelsState();
}

class _MiniReelsState extends State<_MiniReels>
    with SingleTickerProviderStateMixin {
  static const _symbols = [
    SpinSymbol.seven,
    SpinSymbol.seven,
    SpinSymbol.seven,
  ];

  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _waveController.stop();
      _waveController.value = 0;
    } else if (!_waveController.isAnimating) {
      _waveController.repeat();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    return HardShadowBox(
      color: AppStyles.spinBezelColor,
      shadowColor: AppStyles.spinCabinetInnerShadowColor,
      radius: 16,
      shadowOffset: 3,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppStyles.borderColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cell = ((constraints.maxWidth - 8) / 3).clamp(28.0, 72.0);
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          _buildMiniReelCell(cell, i, reduced),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 3,
                  color: AppStyles.spinPaylineColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniReelCell(double cell, int index, bool reduced) {
    final wave = reduced
        ? 0.0
        : math.sin((_waveController.value + index * 0.22) * 2 * math.pi);
    final dy = wave * 2.5;
    final scale = 1.0 + wave * 0.04;

    return Container(
      width: cell,
      height: cell,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: SpinSymbolArt(
              symbol: _symbols[index],
              size: cell * 0.72,
              slotIndex: index,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniLever extends StatefulWidget {
  const _MiniLever();

  @override
  State<_MiniLever> createState() => _MiniLeverState();
}

class _MiniLeverState extends State<_MiniLever>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = 0;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: 36,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 4,
            child: Container(
              width: 22,
              height: 50,
              decoration: BoxDecoration(
                color: AppStyles.cardColor,
                border: Border.all(color: AppStyles.borderColor, width: 2),
                borderRadius: BorderRadius.circular(9),
                boxShadow: const [
                  BoxShadow(
                    color: AppStyles.spinCabinetInnerShadowColor,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            child: Container(
              width: 7,
              height: 48,
              decoration: BoxDecoration(
                color: AppStyles.spinLeverStickColor,
                border: Border.all(color: AppStyles.borderColor, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final ring = reduced
                    ? 0.0
                    : 4.0 * (0.5 - (_pulse.value - 0.5).abs()) * 2;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (ring > 0)
                      Container(
                        width: 28 + ring * 2,
                        height: 28 + ring * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppStyles.spinBezelColor,
                            width: ring,
                          ),
                        ),
                      ),
                    child!,
                  ],
                );
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.32, -0.4),
                    colors: [AppStyles.onAccentColor, AppStyles.spinKnobColor],
                    stops: [0.17, 0.18],
                  ),
                  border: Border.all(color: AppStyles.borderColor, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: AppStyles.spinCabinetInnerShadowColor,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
