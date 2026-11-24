import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/schedule_screen/live_marker.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_general_card.dart';
import 'package:app_events/ui/widgets/schedule_screen/schedule_talk_card.dart';
import 'package:flutter/material.dart';

/// One entry of the event schedule. Breaks, lunch and networking get their own
/// card; every other activity is shown with its speaker. When [highlighted] is
/// true the card is marked as the one happening now.
class ScheduleActivityCard extends StatelessWidget {
  final Speaker item;
  final bool highlighted;
  final VoidCallback? onTap;

  const ScheduleActivityCard({
    super.key,
    required this.item,
    required this.highlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGeneral = EventTypeSpeaker.fromValue(item.type).isGeneralActivity;
    return LiveMarker(
      active: highlighted,
      child: isGeneral
          ? ScheduleGeneralCard(info: item)
          : ScheduleTalkCard(info: item, onTap: onTap),
    );
  }
}
