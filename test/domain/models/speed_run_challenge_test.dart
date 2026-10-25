import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('ChallengeState', () {
    test('fromValue maps known values', () {
      expect(ChallengeState.fromValue('active'), ChallengeState.active);
      expect(ChallengeState.fromValue('inactive'), ChallengeState.inactive);
    });

    test('fromValue defaults to inactive for unknown or null values', () {
      expect(ChallengeState.fromValue(null), ChallengeState.inactive);
      expect(ChallengeState.fromValue('ACTIVE'), ChallengeState.inactive);
    });
  });

  group('SpeedRunChallenge', () {
    test('fromJson uses safe defaults for missing fields', () {
      final challenge = SpeedRunChallenge.fromJson({});

      expect(challenge.id, '');
      expect(challenge.title, '');
      expect(challenge.position, 0);
      expect(challenge.state, ChallengeState.inactive);
    });

    test('round-trip toJson → fromJson preserves data', () {
      final original = makeChallenge(position: 3, imageUrl: 'https://x/y.png');

      final restored = SpeedRunChallenge.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
    });

    test('toJson serializes state as its string value', () {
      final json = makeChallenge(state: ChallengeState.inactive).toJson();

      expect(json['state'], 'inactive');
    });

    test('copyWith only replaces the given fields', () {
      final original = makeChallenge();

      final updated = original.copyWith(state: ChallengeState.inactive);

      expect(updated.state, ChallengeState.inactive);
      expect(updated.id, original.id);
      expect(updated.title, original.title);
    });
  });
}
