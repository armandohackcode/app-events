import 'package:app_events/domain/models/user_competitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fullJson = {
    'uuid': 'u-1',
    'name': 'Grace',
    'photoUrl': 'https://img/u.png',
    'profession': 'Dev',
    'aboutMe': 'Hi',
    'tokenAuthorization': 'tok',
    'score': 120,
    'scoreProfile': true,
    'currentEventId': 'evt-1',
    'socialNetwork': [
      {'type': 'linkedin', 'link': 'https://linkedin.com/in/grace'},
    ],
    'friends': [
      {'uuid': 'u-2', 'name': 'Alan', 'token': 't2', 'photoUrl': ''},
    ],
    'treasures': ['t-1', 't-2'],
    'badges': [
      {
        'eventId': 'evt-0',
        'eventName': 'DevFest 2024',
        'eventDate': '2024-11-15T00:00:00.000',
        'finalScore': 300,
        'rank': 2,
        'assetPath': 'assets/img/badge.png',
      },
    ],
  };

  group('UserCompetitor.fromJson', () {
    test('parses nested lists', () {
      final user = UserCompetitor.fromJson(fullJson);

      expect(user.score, 120);
      expect(user.socialNetwork.single.type, 'linkedin');
      expect(user.friends.single.name, 'Alan');
      expect(user.treasures, ['t-1', 't-2']);
      expect(user.badges.single.rank, 2);
      expect(user.badges.single.eventDate, DateTime(2024, 11, 15));
    });

    test('uses defaults when optional fields are missing', () {
      final user = UserCompetitor.fromJson({'uuid': 'u-1', 'name': 'Grace'});

      expect(user.score, 0);
      expect(user.scoreProfile, isFalse);
      expect(user.currentEventId, isNull);
      expect(user.socialNetwork, isEmpty);
      expect(user.friends, isEmpty);
      expect(user.treasures, isEmpty);
      expect(user.badges, isEmpty);
    });
  });

  test('round-trip fromJson → toJson preserves data', () {
    final json = UserCompetitor.fromJson(fullJson).toJson();

    expect(json, fullJson);
  });

  test('copyWith keeps nested lists when not replaced', () {
    final user = UserCompetitor.fromJson(fullJson);

    final updated = user.copyWith(score: 500);

    expect(updated.score, 500);
    expect(updated.friends, same(user.friends));
    expect(updated.badges, same(user.badges));
  });
}
