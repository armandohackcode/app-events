import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Pop-brutalist card for the Treasure Hunt activity with segmented progress.
class ActivityTreasureCard extends StatelessWidget {
  final int? found;
  final int? total;
  final VoidCallback onTap;

  const ActivityTreasureCard({
    super.key,
    required this.onTap,
    this.found,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final showProgress = found != null && total != null && total! > 0;

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
              Container(
                width: 84,
                height: 84,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppStyles.gamesBackgroundColor,
                  border: Border.all(color: AppStyles.borderColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  AppAssetsPath.firePedExplorerIcon,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.activitiesTreasureTag,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppStrings.activitiesTreasureDescription,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.activitiesTreasureProgress(found!, total!),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var i = 0; i < total!; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: i < found!
                            ? AppStyles.treasureFoundColor
                            : AppStyles.cardColor,
                        border: Border.all(
                          color: AppStyles.borderColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          ChunkyButton(
            label: AppStrings.activitiesTreasureAction,
            color: AppStyles.activitiesTreasureTagColor,
            expand: true,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}
