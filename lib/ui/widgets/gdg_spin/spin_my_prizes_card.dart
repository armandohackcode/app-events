import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Card listing prizes won by the player along with their redemption codes.
class SpinMyPrizesCard extends StatelessWidget {
  final List<WonPrize> prizes;

  const SpinMyPrizesCard({super.key, required this.prizes});

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 20,
      shadowOffset: 5,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(16),
      child: prizes.isEmpty
          ? const SizedBox(
              width: double.infinity,
              child: Text(
                AppStrings.spinMyPrizesEmpty,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < prizes.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _WonPrizeRow(prize: prizes[i]),
                ],
                const SizedBox(height: 8),
                const Text(
                  AppStrings.spinRedeemHint,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
              ],
            ),
    );
  }
}

class _WonPrizeRow extends StatelessWidget {
  final WonPrize prize;

  const _WonPrizeRow({required this.prize});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppStyles.gamesBackgroundColor,
            border: Border.all(color: AppStyles.borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SpinSymbolArt(symbol: prize.symbol, size: 28),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prize.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                prize.code,
                style: const TextStyle(
                  fontFamily: AppStyles.monospaceFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
