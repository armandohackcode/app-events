import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Pill that tells whether an event is upcoming, active or finished, with a
/// dot in the color of the status.
class EventStatusBadge extends StatelessWidget {
  final EventStatus status;
  const EventStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EventStatus.upcoming => (
        AppStrings.eventStatusUpcoming,
        AppStyles.colorBaseYellow,
      ),
      EventStatus.active => (
        AppStrings.eventStatusActive,
        AppStyles.colorBaseGreen,
      ),
      EventStatus.finished => (
        AppStrings.eventStatusFinished,
        AppStyles.fontSecondaryColor,
      ),
    };
    return HardShadowBox(
      radius: 999,
      shadowOffset: 2,
      borderWidth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: AppStyles.fontColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
