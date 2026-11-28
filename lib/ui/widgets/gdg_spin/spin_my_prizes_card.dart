import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Card listing prizes won by the player along with redemption codes and status.
class SpinMyPrizesCard extends StatelessWidget {
  final List<SpinWin> prizes;
  final ValueChanged<SpinWin>? onPrizeTap;

  const SpinMyPrizesCard({super.key, required this.prizes, this.onPrizeTap});

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
                  _WonPrizeRow(
                    prize: prizes[i],
                    onTap: onPrizeTap == null
                        ? null
                        : () => onPrizeTap!(prizes[i]),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  AppStrings.spinTapToShowQr,
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
  final SpinWin prize;
  final VoidCallback? onTap;

  const _WonPrizeRow({required this.prize, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (prize.status) {
      SpinWinStatus.pending => (
        AppStrings.spinStatusPending,
        AppStyles.spinStatusPendingColor,
      ),
      SpinWinStatus.redeemed => (
        AppStrings.spinStatusRedeemed,
        AppStyles.spinStatusRedeemedColor,
      ),
      SpinWinStatus.revoked => (
        AppStrings.spinStatusRevoked,
        AppStyles.spinStatusRevokedColor,
      ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
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
                child: SpinPrizeThumbnail(
                  symbol: prize.prizeSymbol,
                  imageUrl: prize.prizeImageUrl,
                  size: 36,
                  fallbackSize: 28,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prize.prizeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
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
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  border: Border.all(color: AppStyles.borderColor, width: 1.5),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 18,
                  color: AppStyles.fontSecondaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
