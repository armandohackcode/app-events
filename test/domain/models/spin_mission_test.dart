import 'package:app_events/domain/models/spin_mission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinMission', () {
    test('fromJson uses safe defaults for empty map', () {
      final mission = SpinMission.fromJson({});

      expect(mission.id, '');
      expect(mission.title, '');
      expect(mission.reward, 0);
      expect(mission.done, isFalse);
      expect(mission.actionLabel, isNull);
      expect(mission.isTrivia, isFalse);
    });

    test('round-trip toJson and fromJson preserves data and keys', () {
      const original = SpinMission(
        id: 'trivia',
        title: 'Break trivia',
        reward: 1,
        done: true,
        actionLabel: 'Play',
        isTrivia: true,
      );

      final json = original.toJson();
      expect(json.keys, {
        'id',
        'title',
        'reward',
        'done',
        'actionLabel',
        'isTrivia',
      });

      final restored = SpinMission.fromJson(json);
      expect(restored.toJson(), json);
    });

    test('copyWith updates only the given fields', () {
      const original = SpinMission(
        id: 'ask',
        title: 'Ask a speaker',
        reward: 1,
        done: false,
        actionLabel: 'Ask',
      );

      final updated = original.copyWith(done: true);

      expect(updated.done, isTrue);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.reward, original.reward);
      expect(updated.actionLabel, original.actionLabel);
      expect(updated.isTrivia, isFalse);
    });
  });
}
