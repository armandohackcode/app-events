import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Question box of the live talk card. It is visual only: nothing is sent yet.
class QuestionBox extends StatelessWidget {
  const QuestionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppStyles.cardColor,
            border: Border.all(color: AppStyles.borderColor, width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
            ],
          ),
          child: const Row(
            children: [
              Icon(
                Icons.question_mark_rounded,
                size: 14,
                color: AppStyles.fontSecondaryColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: TextStyle(fontSize: 12.5, color: AppStyles.fontColor),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: AppStrings.homeLiveQuestionHint,
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.send_outlined,
                size: 16,
                color: AppStyles.colorBaseBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
