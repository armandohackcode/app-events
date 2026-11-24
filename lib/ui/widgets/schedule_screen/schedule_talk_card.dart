import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/initials_avatar.dart';
import 'package:app_events/ui/widgets/shared/time_and_tags.dart';
import 'package:flutter/material.dart';

/// Card of a talk, workshop or panel in the schedule: time and tags, title and
/// the speaker. A panel is drawn on a blue background. Tapping calls [onTap]
/// when it is given.
class ScheduleTalkCard extends StatelessWidget {
  final Speaker info;
  final VoidCallback? onTap;

  const ScheduleTalkCard({super.key, required this.info, this.onTap});

  bool get _isPanel =>
      EventTypeSpeaker.fromValue(info.type) == EventTypeSpeaker.panel;

  @override
  Widget build(BuildContext context) {
    final textColor = _isPanel ? AppStyles.onAccentColor : AppStyles.fontColor;
    final subtitleColor = _isPanel
        ? AppStyles.onAccentColor
        : AppStyles.fontSecondaryColor;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: HardShadowBox(
        color: _isPanel ? AppStyles.colorBaseBlue : AppStyles.cardColor,
        radius: 20,
        shadowOffset: 4,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TimeAndTags(
              schedule: info.schedule,
              technologyType: info.technologyType,
              type: info.type,
            ),
            const SizedBox(height: 14),
            Text(
              info.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: textColor,
              ),
            ),
            if (info.name.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                height: 1.5,
                color: _isPanel
                    ? AppStyles.onAccentColor.withValues(alpha: 0.4)
                    : AppStyles.dividerColor,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  InitialsAvatar(
                    name: info.name,
                    photoUrl: info.photoUrl,
                    backgroundColor: AppStyles.colorBaseYellow,
                    foregroundColor: AppStyles.fontColor,
                    size: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        if (info.profession.isNotEmpty)
                          Text(
                            info.profession,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
