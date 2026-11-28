import 'package:app_events/domain/models/spin_mission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinMissionType', () {
    test('fromValue maps known values and defaults to profileComplete', () {
      expect(
        SpinMissionType.fromValue('profile_complete'),
        SpinMissionType.profileComplete,
      );
      expect(
        SpinMissionType.fromValue('workshop_register'),
        SpinMissionType.workshopRegister,
      );
      expect(
        SpinMissionType.fromValue('ask_speaker'),
        SpinMissionType.askSpeaker,
      );
      expect(SpinMissionType.fromValue('rate_talk'), SpinMissionType.rateTalk);
      expect(SpinMissionType.fromValue('trivia'), SpinMissionType.trivia);
      expect(SpinMissionType.fromValue(null), SpinMissionType.profileComplete);
      expect(
        SpinMissionType.fromValue('unknown'),
        SpinMissionType.profileComplete,
      );
    });
  });

  group('SpinMission', () {
    test('fromJson uses safe defaults for empty map', () {
      final mission = SpinMission.fromJson({});

      expect(mission.id, '');
      expect(mission.type, SpinMissionType.profileComplete);
      expect(mission.title, '');
      expect(mission.description, '');
      expect(mission.reward, 0);
      expect(mission.rewardTickets, 0);
      expect(mission.targetCount, 1);
      expect(mission.maxCompletionsPerUser, 1);
      expect(mission.done, isFalse);
      expect(mission.completions, 0);
      expect(mission.actionLabel, isNull);
      expect(mission.active, isTrue);
      expect(mission.order, 0);
      expect(mission.startsAt, isNull);
      expect(mission.endsAt, isNull);
      expect(mission.triviaQuestion, isNull);
      expect(mission.triviaOptions, isEmpty);
      expect(mission.minAboutMeLength, isNull);
      expect(mission.updatedAt, isNull);
      expect(mission.isTrivia, isFalse);
    });

    test('parses backend rewardTickets and nested config fields', () {
      final mission = SpinMission.fromJson({
        'id': 'trivia_am',
        'type': 'trivia',
        'title': 'Morning trivia',
        'description': 'Pick the right SDK',
        'rewardTickets': 2,
        'targetCount': 1,
        'maxCompletionsPerUser': 1,
        'actionLabel': 'Play',
        'active': true,
        'order': 4,
        'startsAt': '2026-11-28T10:00:00.000Z',
        'endsAt': '2026-11-28T11:00:00.000Z',
        'config': {
          'question': 'Which Firebase SDK?',
          'options': ['Firebase AI Logic', 'Crashlytics'],
          'minAboutMeLength': 150,
        },
        'updatedAt': '2026-11-28T09:00:00.000Z',
      });

      expect(mission.type, SpinMissionType.trivia);
      expect(mission.isTrivia, isTrue);
      expect(mission.reward, 2);
      expect(mission.rewardTickets, 2);
      expect(mission.triviaQuestion, 'Which Firebase SDK?');
      expect(mission.triviaOptions, ['Firebase AI Logic', 'Crashlytics']);
      expect(mission.minAboutMeLength, 150);
      expect(mission.startsAt, DateTime.utc(2026, 11, 28, 10));
      expect(mission.endsAt, DateTime.utc(2026, 11, 28, 11));
    });

    test('supports legacy reward and isTrivia keys', () {
      final mission = SpinMission.fromJson({
        'id': 'legacy_trivia',
        'title': 'Legacy',
        'reward': 3,
        'done': true,
        'isTrivia': true,
      });

      expect(mission.reward, 3);
      expect(mission.done, isTrue);
      expect(mission.isTrivia, isTrue);
      expect(mission.type, SpinMissionType.trivia);
    });

    test('round-trip toJson and fromJson preserves data and keys', () {
      final startsAt = DateTime.utc(2026, 11, 28, 10);
      final endsAt = DateTime.utc(2026, 11, 28, 12);
      final updatedAt = DateTime.utc(2026, 11, 28, 9);
      final original = SpinMission(
        id: 'trivia',
        type: SpinMissionType.trivia,
        title: 'Break trivia',
        description: 'Answer to win',
        reward: 1,
        targetCount: 1,
        maxCompletionsPerUser: 1,
        done: true,
        completions: 1,
        actionLabel: 'Play',
        active: true,
        order: 2,
        startsAt: startsAt,
        endsAt: endsAt,
        triviaQuestion: 'What is Dart?',
        triviaOptions: const ['Language', 'Database'],
        minAboutMeLength: 200,
        updatedAt: updatedAt,
      );

      final json = original.toJson();
      expect(json.keys, {
        'id',
        'type',
        'title',
        'description',
        'rewardTickets',
        'targetCount',
        'maxCompletionsPerUser',
        'done',
        'completions',
        'actionLabel',
        'active',
        'order',
        'startsAt',
        'endsAt',
        'config',
        'updatedAt',
      });

      final restored = SpinMission.fromJson(json);
      expect(restored.toJson(), json);
      expect(restored.isTrivia, isTrue);
    });

    test('copyWith updates only given fields and supports clear flags', () {
      final original = SpinMission(
        id: 'ask',
        type: SpinMissionType.askSpeaker,
        title: 'Ask a speaker',
        reward: 1,
        done: false,
        actionLabel: 'Ask',
        startsAt: DateTime.utc(2026, 11, 28, 10),
        endsAt: DateTime.utc(2026, 11, 28, 18),
        triviaQuestion: 'Q?',
        minAboutMeLength: 200,
        updatedAt: DateTime.utc(2026, 11, 28, 8),
      );

      final updated = original.copyWith(
        done: true,
        completions: 1,
        clearActionLabel: true,
        clearStartsAt: true,
        clearEndsAt: true,
        clearTriviaQuestion: true,
        clearMinAboutMeLength: true,
        clearUpdatedAt: true,
      );

      expect(updated.done, isTrue);
      expect(updated.completions, 1);
      expect(updated.type, SpinMissionType.askSpeaker);
      expect(updated.actionLabel, isNull);
      expect(updated.startsAt, isNull);
      expect(updated.endsAt, isNull);
      expect(updated.triviaQuestion, isNull);
      expect(updated.minAboutMeLength, isNull);
      expect(updated.updatedAt, isNull);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.reward, original.reward);
    });
  });
}
