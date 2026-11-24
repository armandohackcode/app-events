import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Schedule of an activity: a clock icon and the time range in monospace,
/// inside a small pill with a hard shadow.
class TimePill extends StatelessWidget {
  final String text;
  const TimePill({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.homeBackgroundColor,
      radius: 999,
      shadowOffset: 2,
      borderWidth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 15,
            color: AppStyles.fontColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppStyles.monospaceFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppStyles.fontColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
