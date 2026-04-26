import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
