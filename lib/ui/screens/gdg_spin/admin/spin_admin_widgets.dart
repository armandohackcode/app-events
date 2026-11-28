import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Maps a thrown admin mutation/load error to a localized Spanish user message.
String mapSpinAdminError(Object error) {
  if (error is SpinException) {
    return switch (error.reason) {
      SpinErrorReason.permissionDenied ||
      SpinErrorReason.unauthenticated => AppStrings.spinAdminPermissionDenied,
      SpinErrorReason.configNotFound =>
        AppStrings.spinAdminConfigNotInitialized,
      SpinErrorReason.alreadyRedeemed =>
        AppStrings.spinAdminAlreadyRedeemedError,
      SpinErrorReason.alreadyRevoked => AppStrings.spinAdminAlreadyRevokedError,
      SpinErrorReason.invalidStockAdjustment =>
        AppStrings.spinAdminStockNegativeError,
      SpinErrorReason.stockImmutableOnUpdate =>
        AppStrings.spinAdminStockImmutableError,
      SpinErrorReason.manualGrantCapReached =>
        AppStrings.spinAdminManualGrantCapError,
      SpinErrorReason.codeAlreadyExists =>
        AppStrings.spinAdminCodeDuplicateError,
      SpinErrorReason.notFound => AppStrings.spinAdminWinNotFoundError,
      SpinErrorReason.invalidCodeFormat => AppStrings.spinCodeInvalidFormat,
      SpinErrorReason.network => AppStrings.spinNetworkError,
      _ =>
        error.message.trim().isNotEmpty
            ? error.message.trim()
            : AppStrings.spinAdminGenericError,
    };
  }
  return AppStrings.spinAdminGenericError;
}

/// Shows a consistent feedback SnackBar inside the admin panel.
void showSpinAdminFeedback(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!context.mounted) return;
  customSnackbar(
    context,
    message,
    color: isError
        ? AppStyles.spinAdminDangerColor
        : AppStyles.spinAdminSuccessColor,
  );
}

/// Returns localized display label for [rarity].
String spinRarityLabel(PrizeRarity rarity) => switch (rarity) {
  PrizeRarity.common => AppStrings.spinRarityCommon,
  PrizeRarity.rare => AppStrings.spinRarityRare,
  PrizeRarity.epic => AppStrings.spinRarityEpic,
  PrizeRarity.legendary => AppStrings.spinRarityLegendary,
};

/// Returns semantic tag background color for [rarity].
Color spinRarityColor(PrizeRarity rarity) => switch (rarity) {
  PrizeRarity.common => AppStyles.rarityCommonColor,
  PrizeRarity.rare => AppStyles.rarityRareColor,
  PrizeRarity.epic => AppStyles.rarityEpicColor,
  PrizeRarity.legendary => AppStyles.rarityLegendaryColor,
};

/// Returns `(label, color)` for [status].
(String, Color) spinWinStatusVisuals(SpinWinStatus status) => switch (status) {
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

/// Pop-brutalist section container with tilted tag header.
class SpinAdminSectionCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final double angleDegrees;
  final Color cardColor;
  final Widget child;

  const SpinAdminSectionCard({
    super.key,
    required this.tag,
    required this.tagColor,
    required this.child,
    this.angleDegrees = -1,
    this.cardColor = AppStyles.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return TaggedCard(
      tag: tag,
      tagColor: tagColor,
      angleDegrees: angleDegrees,
      compact: true,
      child: HardShadowBox(
        color: cardColor,
        radius: 18,
        shadowOffset: 4,
        borderWidth: 2.5,
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }
}

/// Consistent pop-brutalist input decoration used across admin forms.
InputDecoration spinAdminInputDecoration({
  required String labelText,
  String? hintText,
  Widget? suffixIcon,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppStyles.borderColor, width: 2),
  );
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppStyles.gamesBackgroundColor,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    labelStyle: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: AppStyles.fontSecondaryColor,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppStyles.colorBaseBlue, width: 2.5),
    ),
  );
}

/// Compact pill badge used in admin lists and KPI chips.
class SpinAdminBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const SpinAdminBadge({
    super.key,
    required this.text,
    required this.color,
    this.textColor = AppStyles.fontColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppStyles.borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

/// Opens a date + time picker returning a local [DateTime], or `null` if cancelled.
Future<DateTime?> pickSpinAdminDateTime(
  BuildContext context, {
  DateTime? initialValue,
}) async {
  final now = DateTime.now();
  final base = (initialValue ?? now).toLocal();
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: base,
    firstDate: DateTime(2024),
    lastDate: DateTime(2035),
  );
  if (pickedDate == null || !context.mounted) return null;

  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(base),
  );
  if (pickedTime == null) {
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      base.hour,
      base.minute,
    );
  }
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}

/// Selectable date/time tile with clear button for optional schedule fields.
class SpinAdminDateTimeTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const SpinAdminDateTimeTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value == null
        ? AppStrings.spinAdminNotConfigured
        : dateFormat.format(value!.toLocal());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.gamesBackgroundColor,
        border: Border.all(color: AppStyles.borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: AppStyles.fontSecondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await pickSpinAdminDateTime(
                  context,
                  initialValue: value,
                );
                if (picked != null) {
                  onChanged(picked);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                  Text(
                    formatted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (value != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(null),
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact banner shown above dirty admin forms when a newer remote config arrives.
class SpinAdminRemoteConfigBanner extends StatelessWidget {
  final VoidCallback onReload;

  const SpinAdminRemoteConfigBanner({super.key, required this.onReload});

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.spinBannerPausedColor,
      radius: 14,
      shadowOffset: 3,
      borderWidth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, size: 18, color: AppStyles.fontColor),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              AppStrings.spinAdminRemoteConfigUpdated,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppStyles.fontColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ChunkyButton(
            label: AppStrings.spinAdminReloadConfig,
            color: AppStyles.colorBaseYellow,
            minHeight: 34,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            onPressed: onReload,
          ),
        ],
      ),
    );
  }
}
