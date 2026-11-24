import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/live_badge.dart';
import 'package:flutter/material.dart';

/// Highlights an activity of the schedule: a yellow frame around [child] and
/// the LIVE badge on its corner. When [active] is false it only shows [child].
class LiveMarker extends StatelessWidget {
  final bool active;
  final Widget child;

  const LiveMarker({super.key, required this.active, required this.child});

  static const double _frame = 4;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppStyles.colorBaseYellow,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(padding: const EdgeInsets.all(_frame), child: child),
        ),
        const Positioned(top: -10, right: 14, child: LiveBadge(angle: 8)),
      ],
    );
  }
}
