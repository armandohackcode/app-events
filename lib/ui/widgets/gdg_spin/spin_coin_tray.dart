import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Coin tray at the bottom of the cabinet and pay-table jump button.
class SpinCoinTray extends StatelessWidget {
  final List<CoinDrop> coins;
  final VoidCallback onCollectCoins;
  final VoidCallback onScrollToPayTable;

  const SpinCoinTray({
    super.key,
    required this.coins,
    required this.onCollectCoins,
    required this.onScrollToPayTable,
  });

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return HardShadowBox(
      color: AppStyles.cardColor,
      shadowColor: AppStyles.spinCabinetInnerShadowColor,
      radius: 16,
      shadowOffset: 4,
      borderWidth: 2.5,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: AppStrings.spinTraySemantic,
            child: GestureDetector(
              onTap: onCollectCoins,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: Radius.circular(14),
                ),
                child: Container(
                  height: 44,
                  width: double.infinity,
                  color: AppStyles.borderColor,
                  child: coins.isEmpty
                      ? const Center(
                          child: Text(
                            AppStrings.spinCoinTray,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: AppStyles.onAccentColor,
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final usableWidth = math.max(
                              0.0,
                              constraints.maxWidth - 19,
                            );
                            return Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                for (var i = 0; i < coins.length; i++)
                                  _CoinSprite(
                                    coin: coins[i],
                                    left: coins[i].leftFraction * usableWidth,
                                    reducedMotion: reducedMotion,
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.spinFooterBrand,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: AppStyles.fontColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ChunkyButton(
                  label: AppStrings.spinPayTableLink,
                  color: AppStyles.spinBezelColor,
                  onPressed: onScrollToPayTable,
                  minHeight: 40,
                  minTapHeight: 44,
                  radius: 999,
                  fontSize: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinSprite extends StatelessWidget {
  final CoinDrop coin;
  final double left;
  final bool reducedMotion;

  const _CoinSprite({
    required this.coin,
    required this.left,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    final disk = Transform.rotate(
      angle: coin.rotation * math.pi / 180,
      child: Container(
        width: 19,
        height: 9,
        decoration: const BoxDecoration(
          color: AppStyles.spinCoinColor,
          borderRadius: BorderRadius.all(Radius.elliptical(19, 9)),
          boxShadow: [
            BoxShadow(
              color: AppStyles.spinCoinShadowColor,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );

    final animated = coin.isNew && !reducedMotion
        ? BounceInDown(
            from: 48,
            delay: Duration(milliseconds: coin.delayMs),
            duration: const Duration(milliseconds: 550),
            child: disk,
          )
        : disk;

    return Positioned(left: left, bottom: coin.bottom, child: animated);
  }
}
