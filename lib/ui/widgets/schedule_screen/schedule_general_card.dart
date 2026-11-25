import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/dashed_border_box.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/time_pill.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Card of an activity without a speaker (break, lunch, networking). Each kind
/// has its own look: the break is dashed and grey, lunch is yellow and
/// networking is blue.
class ScheduleGeneralCard extends StatelessWidget {
  final Speaker info;
  const ScheduleGeneralCard({super.key, required this.info});

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(16, 14, 16, 14);

  @override
  Widget build(BuildContext context) {
    final type = EventTypeSpeaker.fromValue(info.type);
    final content = Row(
      children: [
        Expanded(child: _Texts(info: info)),
        const SizedBox(width: 12),
        _IconBadge(type: type, icon: eventTypeIcon(info.type)),
      ],
    );
    if (type == EventTypeSpeaker.breakTime) {
      return DashedBorderBox(
        color: AppStyles.windowChromeColor,
        radius: 20,
        padding: _padding,
        child: content,
      );
    }
    return HardShadowBox(
      color: type == EventTypeSpeaker.networking
          ? AppStyles.colorCardBlue
          : AppStyles.colorCardYellowOpaque,
      radius: 20,
      shadowOffset: 4,
      padding: _padding,
      child: content,
    );
  }
}

class _Texts extends StatelessWidget {
  final Speaker info;
  const _Texts({required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.schedule.isNotEmpty) ...[
          TimePill(text: info.schedule),
          const SizedBox(height: 10),
        ],
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: info.title.isEmpty
                    ? eventTypeLabel(info.type)
                    : info.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
              if (info.description.isNotEmpty)
                TextSpan(
                  text: ' · ${info.description}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
            ],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final EventTypeSpeaker type;
  final IconData icon;
  const _IconBadge({required this.type, required this.icon});

  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 22, color: AppStyles.fontColor);
    if (type == EventTypeSpeaker.breakTime) {
      return DashedBorderBox(
        circle: true,
        color: AppStyles.cardColor,
        child: SizedBox(width: _size, height: _size, child: iconWidget),
      );
    }
    return HardShadowBox(
      color: type == EventTypeSpeaker.networking
          ? AppStyles.colorCardBlue
          : AppStyles.colorBaseYellow,
      radius: _size,
      shadowOffset: 2,
      borderWidth: 2,
      child: SizedBox(width: _size, height: _size, child: iconWidget),
    );
  }
}
