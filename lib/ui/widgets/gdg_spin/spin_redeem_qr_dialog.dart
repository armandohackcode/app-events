import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pop-brutalist prize redemption dialog with live status updates from
/// [GdgSpinProvider] (gracefully falls back to [initialWin] when unmounted).
class SpinRedeemQrDialog extends StatelessWidget {
  final String winId;
  final SpinWin initialWin;

  const SpinRedeemQrDialog({
    super.key,
    required this.winId,
    required this.initialWin,
  });

  static Future<void> show(BuildContext context, {required SpinWin win}) =>
      showDialog<void>(
        context: context,
        builder: (_) => SpinRedeemQrDialog(winId: win.id, initialWin: win),
      );

  @override
  Widget build(BuildContext context) {
    final spinProvider = maybeProvider<GdgSpinProvider>(context);
    var win = initialWin;
    if (spinProvider != null) {
      for (final candidate in spinProvider.myWins) {
        if (candidate.id == winId) {
          win = candidate;
          break;
        }
      }
    }

    final (statusText, statusColor) = switch (win.status) {
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: HardShadowBox(
                  color: AppStyles.cardColor,
                  radius: 22,
                  shadowOffset: 5,
                  borderWidth: 2.5,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppStyles.gamesBackgroundColor,
                              border: Border.all(
                                color: AppStyles.borderColor,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SpinPrizeThumbnail(
                              symbol: win.prizeSymbol,
                              imageUrl: win.prizeImageUrl,
                              size: 40,
                              fallbackSize: 30,
                              borderRadius: 10,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              win.prizeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppStyles.fontColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              border: Border.all(
                                color: AppStyles.borderColor,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppStyles.fontColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (win.status == SpinWinStatus.pending) ...[
                        HardShadowBox(
                          color: AppStyles.cardColor,
                          radius: 16,
                          shadowOffset: 3,
                          borderWidth: 2,
                          padding: const EdgeInsets.all(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 200,
                              maxHeight: 200,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: QrImageView(
                                data: win.qrPayload,
                                backgroundColor: AppStyles.cardColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          win.code,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: AppStyles.monospaceFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppStyles.fontColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          AppStrings.spinRedeemQrHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppStyles.fontSecondaryColor,
                          ),
                        ),
                      ] else ...[
                        HardShadowBox(
                          color: statusColor,
                          radius: 16,
                          shadowOffset: 3,
                          borderWidth: 2,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                win.status == SpinWinStatus.redeemed
                                    ? Icons.verified_rounded
                                    : Icons.block_rounded,
                                size: 42,
                                color: AppStyles.fontColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                win.status == SpinWinStatus.redeemed
                                    ? AppStrings.spinRedeemQrCompleted
                                    : AppStrings.spinRedeemQrRevoked,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppStyles.fontColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                win.code,
                                style: const TextStyle(
                                  fontFamily: AppStyles.monospaceFontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppStyles.fontColor,
                                ),
                              ),
                              if (win.status == SpinWinStatus.revoked &&
                                  (win.revokeReason?.trim().isNotEmpty ??
                                      false)) ...[
                                const SizedBox(height: 6),
                                Text(
                                  win.revokeReason!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppStyles.fontColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ChunkyButton(
                        label: AppStrings.commonWordClose,
                        color: AppStyles.colorBaseYellow,
                        expand: true,
                        minHeight: 44,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: TiltedTag(
                    text: AppStrings.spinRedeemQrTitle,
                    color: AppStyles.colorBaseYellow,
                    angleDegrees: -1.5,
                    compact: true,
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
