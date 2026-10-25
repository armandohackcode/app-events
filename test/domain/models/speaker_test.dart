import 'package:app_events/domain/models/speaker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  group('EventTypeSpeaker', () {
    test('fromValue is case insensitive', () {
      expect(EventTypeSpeaker.fromValue('Workshop'), EventTypeSpeaker.workshop);
      expect(EventTypeSpeaker.fromValue('PANEL'), EventTypeSpeaker.panel);
    });

    test('fromValue defaults to unknown', () {
      expect(EventTypeSpeaker.fromValue(null), EventTypeSpeaker.unknown);
      expect(EventTypeSpeaker.fromValue('keynote'), EventTypeSpeaker.unknown);
    });
  });

  group('Speaker', () {
    test('round-trip toJson → fromJson preserves data', () {
      final original = makeSpeaker().copyWith(limit: 30, current: 5);

      final restored = Speaker.fromJson(original.toJson());

      expect(restored.uuid, original.uuid);
      expect(restored.limit, 30);
      expect(restored.current, 5);
      expect(restored.socialNetwork.single.type, 'github');
    });

    test('serializes social networks under the "SocialNetwork" key', () {
      // Firestore documents use this capitalized key; renaming it breaks data.
      final json = makeSpeaker().toJson();

      expect(json.containsKey('SocialNetwork'), isTrue);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final speaker = Speaker.fromJson({'SocialNetwork': []});

      expect(speaker.name, '');
      expect(speaker.position, 0);
      expect(speaker.limit, 0);
      expect(speaker.socialNetwork, isEmpty);
    });

    test('fromJson tolerates documents without SocialNetwork', () {
      expect(() => Speaker.fromJson({}), returnsNormally);
    });
  });
}
