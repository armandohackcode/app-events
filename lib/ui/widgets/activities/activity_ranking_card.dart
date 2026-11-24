import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Pop-brutalist ranking card with fixed trophy and podium illustration.
class ActivityRankingCard extends StatelessWidget {
  final VoidCallback onTap;

  const ActivityRankingCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 20,
      shadowOffset: 5,
      borderWidth: 2.5,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const _PodiumIllustration(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        AppStrings.homeTournamentGDG,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        AppStrings.activitiesRankingDescription,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: HardShadowBox(
                          color: AppStyles.activitiesRankingTagColor,
                          radius: 999,
                          shadowOffset: 3,
                          borderWidth: 2.5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.activitiesRankingAction,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppStyles.fontColor,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppStyles.fontColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumIllustration extends StatelessWidget {
  const _PodiumIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _PodiumBar(
                rank: 2,
                width: 36,
                height: 44,
                color: AppStyles.podiumSecondColor,
                textColor: AppStyles.onAccentColor,
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssetsPath.trophyIcon,
                    width: 48,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  const _PodiumBar(
                    rank: 1,
                    width: 40,
                    height: 62,
                    color: AppStyles.podiumFirstColor,
                    textColor: AppStyles.fontColor,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const _PodiumBar(
                rank: 3,
                width: 36,
                height: 32,
                color: AppStyles.podiumThirdColor,
                textColor: AppStyles.onAccentColor,
              ),
            ],
          ),
          Container(
            width: 132,
            height: 6,
            decoration: BoxDecoration(
              color: AppStyles.borderColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumBar extends StatelessWidget {
  final int rank;
  final double width;
  final double height;
  final Color color;
  final Color textColor;

  const _PodiumBar({
    required this.rank,
    required this.width,
    required this.height,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppStyles.borderColor, width: 2.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Text(
        rank.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}
