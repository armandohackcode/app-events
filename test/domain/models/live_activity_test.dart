import 'package:app_events/domain/models/live_activity.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('liveActivity', () {
    test('is null for an empty schedule', () {
      expect(<Speaker>[].liveActivity, isNull);
    });

    test('is null when no activity is live', () {
      final schedule = [makeSpeaker(uuid: 'a'), makeSpeaker(uuid: 'b')];

      expect(schedule.liveActivity, isNull);
    });

    test('is the activity marked as live', () {
      final live = makeSpeaker(uuid: 'b', isLive: true);
      final schedule = [makeSpeaker(uuid: 'a'), live, makeSpeaker(uuid: 'c')];

      expect(schedule.liveActivity, same(live));
    });

    test('picks the earliest one when several are live', () {
      final first = makeSpeaker(uuid: 'a', position: 1, isLive: true);
      final second = makeSpeaker(uuid: 'b', position: 2, isLive: true);

      expect([second, first].liveActivity, same(first));
      expect([first, second].liveActivity, same(first));
    });

    test('ignores the order of the list', () {
      final late = makeSpeaker(uuid: 'late', position: 9, isLive: true);
      final early = makeSpeaker(uuid: 'early', position: 3, isLive: true);

      expect([late, early].liveActivity?.uuid, 'early');
    });
  });
}
