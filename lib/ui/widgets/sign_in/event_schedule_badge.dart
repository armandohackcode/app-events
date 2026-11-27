import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Top capsule badge displaying the upcoming event date and schedule.
class EventScheduleBadge extends StatelessWidget {
  const EventScheduleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 999,
      borderWidth: 2,
      shadowOffset: 3,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9.5,
            height: 9.5,
            decoration: BoxDecoration(
              color: AppStyles.colorBaseYellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppStyles.borderColor, width: 1.4),
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppStrings.signInEventSchedule,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppStyles.monospaceFontFamily,
                  fontFamilyFallback: ['monospace'],
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: AppStyles.fontColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
