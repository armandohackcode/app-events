import 'package:app_events/ui/widgets/shared/icon_tag.dart';
import 'package:app_events/ui/widgets/shared/time_pill.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Schedule on the left; technology and activity-type tags on the right. They
/// wrap to a second line when the width is too narrow. Parts that are empty
/// are left out.
class TimeAndTags extends StatelessWidget {
  final String schedule;
  final String technologyType;
  final String type;

  const TimeAndTags({
    super.key,
    required this.schedule,
    required this.technologyType,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final hasTags = technologyType.isNotEmpty || type.isNotEmpty;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        if (schedule.isNotEmpty) TimePill(text: schedule),
        if (hasTags)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (technologyType.isNotEmpty)
                Flexible(
                  child: IconTag(
                    text: technologyType,
                    icon: technologyIcon(technologyType),
                    color: technologyColor(technologyType),
                  ),
                ),
              if (technologyType.isNotEmpty && type.isNotEmpty)
                const SizedBox(width: 8),
              if (type.isNotEmpty)
                Flexible(
                  child: IconTag(
                    text: eventTypeLabel(type),
                    icon: eventTypeIcon(type),
                    color: eventTypeColor(type),
                    foregroundColor: eventTypeForegroundColor(type),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
