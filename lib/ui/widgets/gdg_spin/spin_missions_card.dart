import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/dashed_border_box.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Card listing missions to earn spin tickets, including the inline break trivia.
class SpinMissionsCard extends StatelessWidget {
  final List<SpinMission> missions;
  final bool triviaOpen;
  final ValueChanged<SpinMission> onMissionTap;
  final ValueChanged<bool> onAnswerTrivia;

  const SpinMissionsCard({
    super.key,
    required this.missions,
    required this.triviaOpen,
    required this.onMissionTap,
    required this.onAnswerTrivia,
  });

  @override
  Widget build(BuildContext context) {
    final triviaPending = missions.any((m) => m.isTrivia && !m.done);

    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 20,
      shadowOffset: 5,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < missions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _MissionRow(
              mission: missions[i],
              onTap: () => onMissionTap(missions[i]),
            ),
          ],
          if (triviaOpen && triviaPending) ...[
            const SizedBox(height: 10),
            _TriviaPanel(onAnswer: onAnswerTrivia),
          ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  final SpinMission mission;
  final VoidCallback onTap;

  const _MissionRow({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rewardLabel = mission.isTrivia && !mission.done
        ? AppStrings.spinTriviaReward
        : AppStrings.spinReward(mission.reward);

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
                  rewardLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (!mission.done && mission.actionLabel != null) ...[
            const SizedBox(width: 8),
            ChunkyButton(
              label: mission.actionLabel!,
              color: AppStyles.spinBezelColor,
              onPressed: onTap,
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
  final ValueChanged<bool> onAnswer;

  const _TriviaPanel({required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return DashedBorderBox(
      color: AppStyles.gamesBackgroundColor,
      radius: 12,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.spinTriviaQuestion,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppStyles.fontColor,
            ),
          ),
          const SizedBox(height: 8),
          _TriviaOptionButton(
            label: AppStrings.spinTriviaOptionA,
            onTap: () => onAnswer(true),
          ),
          const SizedBox(height: 8),
          _TriviaOptionButton(
            label: AppStrings.spinTriviaOptionB,
            onTap: () => onAnswer(false),
          ),
          const SizedBox(height: 8),
          _TriviaOptionButton(
            label: AppStrings.spinTriviaOptionC,
            onTap: () => onAnswer(false),
          ),
        ],
      ),
    );
  }
}

class _TriviaOptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TriviaOptionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
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
