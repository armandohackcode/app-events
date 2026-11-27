import 'package:app_events/domain/models/speaker.dart';

/// Single rule that decides which activity of a schedule is live, shared by
/// every screen so they never disagree.
extension LiveSchedule on Iterable<Speaker> {
  /// The activity marked as live, or null when none is. Only one activity of
  /// an event should be marked; if several are, the earliest in the schedule
  /// (lowest [Speaker.position]) is chosen.
  Speaker? get liveActivity {
    Speaker? live;
    for (final activity in this) {
      if (!activity.isLive) continue;
      if (live == null || activity.position < live.position) live = activity;
    }
    return live;
  }
}
