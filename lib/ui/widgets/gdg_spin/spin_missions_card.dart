import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/dashed_border_box.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Card listing missions to earn spin tickets, including dynamic inline trivia
/// and sponsor/stand code redemption.
class SpinMissionsCard extends StatelessWidget {
  final List<SpinMission> missions;
  final String? openTriviaMissionId;
  final ValueChanged<SpinMission> onMissionTap;
  final void Function(String missionId, int optionIndex) onAnswerTrivia;
  final VoidCallback? onRedeemCodeTap;
  final bool busy;

  const SpinMissionsCard({
    super.key,
    required this.missions,
    required this.openTriviaMissionId,
    required this.onMissionTap,
    required this.onAnswerTrivia,
    this.onRedeemCodeTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 20,
      shadowOffset: 5,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (missions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                AppStrings.spinMissionsEmpty,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            )
          else
            for (var i = 0; i < missions.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _MissionRow(
                mission: missions[i],
                busy: busy,
                onTap: () => onMissionTap(missions[i]),
              ),
              if (missions[i].isTrivia &&
                  !missions[i].done &&
                  missions[i].id == openTriviaMissionId &&
                  missions[i].triviaOptions.isNotEmpty) ...[
                const SizedBox(height: 10),
                _TriviaPanel(
                  mission: missions[i],
                  busy: busy,
                  onAnswer: (index) => onAnswerTrivia(missions[i].id, index),
                ),
              ],
            ],
          if (onRedeemCodeTap != null) ...[
            const SizedBox(height: 12),
            ChunkyButton(
              label: AppStrings.spinHaveStandCode,
              color: AppStyles.activitiesRankingTagColor,
              expand: true,
              minHeight: 44,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 18,
                color: AppStyles.fontColor,
              ),
              onPressed: busy ? null : onRedeemCodeTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final SpinMission mission;
  final bool busy;
  final VoidCallback onTap;

  const _MissionRow({
    required this.mission,
    required this.busy,
    required this.onTap,
  });

  String _resolveActionLabel() {
    final custom = mission.actionLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (mission.type) {
      SpinMissionType.trivia => AppStrings.playLabel,
      SpinMissionType.askSpeaker => AppStrings.askLabel,
      SpinMissionType.rateTalk => AppStrings.rateLabel,
      SpinMissionType.profileComplete ||
      SpinMissionType.workshopRegister => AppStrings.spinMissionActionClaim,
    };
  }

  @override
  Widget build(BuildContext context) {
    final baseReward = mission.isTrivia && !mission.done
        ? (mission.reward == 1
              ? AppStrings.spinTriviaReward
              : AppStrings.spinTriviaRewardCount(mission.reward))
        : AppStrings.spinReward(mission.reward);

    final subtitle = mission.maxCompletionsPerUser > 1
        ? '$baseReward · ${AppStrings.spinMissionProgress(mission.completions, mission.maxCompletionsPerUser)}'
        : baseReward;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mission.done
                  ? AppStyles.spinMissionDoneColor
                  : AppStyles.cardColor,
              border: Border.all(color: AppStyles.borderColor, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: mission.done
                ? const Icon(Icons.check, size: 15, color: AppStyles.fontColor)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mission.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: mission.done
                        ? AppStyles.fontSecondaryColor
                        : AppStyles.fontColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (!mission.done) ...[
            const SizedBox(width: 8),
            ChunkyButton(
              label: _resolveActionLabel(),
              color: AppStyles.spinBezelColor,
              onPressed: busy ? null : onTap,
              minHeight: 40,
              minTapHeight: 44,
              radius: 12,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ],
        ],
      ),
    );
  }
}

class _TriviaPanel extends StatelessWidget {
  final SpinMission mission;
  final bool busy;
  final ValueChanged<int> onAnswer;

  const _TriviaPanel({
    required this.mission,
    required this.busy,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final questionText = (mission.triviaQuestion?.trim().isNotEmpty ?? false)
        ? mission.triviaQuestion!.trim()
        : mission.title;

    return DashedBorderBox(
      color: AppStyles.gamesBackgroundColor,
      radius: 12,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppStyles.fontColor,
            ),
          ),
          for (var i = 0; i < mission.triviaOptions.length; i++) ...[
            const SizedBox(height: 8),
            _TriviaOptionButton(
              label: mission.triviaOptions[i],
              onTap: busy ? null : () => onAnswer(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TriviaOptionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _TriviaOptionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppStyles.cardColor,
            border: Border.all(color: AppStyles.borderColor, width: 2),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: AppStyles.borderColor, offset: Offset(2, 2)),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppStyles.fontColor,
            ),
          ),
        ),
      ),
    );
  }
}
