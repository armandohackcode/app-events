import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Title of the schedule section with the number of activities.
class ScheduleHeader extends StatelessWidget {
  final int count;
  const ScheduleHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    final unit = count == 1
        ? AppStrings.scheduleActivitySingular
        : AppStrings.scheduleActivityPlural;
    return Row(
      children: [
        const HardShadowBox(
          color: AppStyles.colorBaseYellow,
          radius: 999,
          shadowOffset: 2,
          borderWidth: 2,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.calendar_today_rounded,
              size: 19,
              color: AppStyles.fontColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            AppStrings.scheduleSchedule,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppStyles.fontColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        HardShadowBox(
          radius: 999,
          shadowOffset: 2,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            '$count $unit',
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppStyles.monospaceFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppStyles.fontColor,
            ),
          ),
        ),
      ],
    );
  }
}
