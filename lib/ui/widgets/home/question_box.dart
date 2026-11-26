import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Question box of the live talk card. It is visual only: nothing is sent yet.
class QuestionBox extends StatelessWidget {
  /// First name of the speaker the question is for.
  final String speakerName;
  const QuestionBox({super.key, required this.speakerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        border: Border.all(color: AppStyles.borderColor, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.question_mark_rounded,
            size: 14,
            color: AppStyles.fontSecondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(
                fontSize: 12.5,
                color: AppStyles.fontColor,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText:
                    '${AppStrings.homeLiveQuestionHintPrefix}$speakerName...',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.send_outlined,
            size: 16,
            color: AppStyles.colorBaseBlue,
          ),
        ],
      ),
    );
  }
}
