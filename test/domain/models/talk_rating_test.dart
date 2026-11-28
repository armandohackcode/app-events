import 'package:app_events/domain/models/talk_rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TalkRating', () {
    test('fromJson uses safe defaults for empty map', () {
      final rating = TalkRating.fromJson({});

      expect(rating.uid, '');
      expect(rating.stars, 0);
      expect(rating.comment, '');
      expect(rating.createdAt, isNull);
      expect(rating.updatedAt, isNull);
    });

    test('round-trip toJson and fromJson preserves all fields', () {
      final original = TalkRating(
        uid: 'u-1',
        stars: 5,
        comment: 'Great live demo!',
        createdAt: DateTime.utc(2026, 11, 28, 11),
        updatedAt: DateTime.utc(2026, 11, 28, 11, 5),
      );

      final json = original.toJson();
      final restored = TalkRating.fromJson(json);

      expect(restored.toJson(), json);
    });

    test('copyWith updates given fields and clears timestamps', () {
      final original = TalkRating(
        uid: 'u-1',
        stars: 4,
        comment: 'Good',
        createdAt: DateTime.utc(2026, 11, 28, 11),
        updatedAt: DateTime.utc(2026, 11, 28, 11, 5),
      );

      final updated = original.copyWith(
        stars: 5,
        clearCreatedAt: true,
        clearUpdatedAt: true,
      );

      expect(updated.stars, 5);
      expect(updated.createdAt, isNull);
      expect(updated.updatedAt, isNull);
    });
  });

  group('TalkRatingSubmitResult', () {
    test('fromJson and toJson round-trip cleanly', () {
      final original = TalkRatingSubmitResult.fromJson({
        'saved': true,
        'missionRewarded': true,
        'ticketsAwarded': 1,
        'ticketsAfter': 5,
        'ticketSerial': 'R1234567',
      });

      expect(original.saved, isTrue);
      expect(original.missionRewarded, isTrue);
      expect(original.ticketsAwarded, 1);
      expect(original.ticketsAfter, 5);
      expect(original.ticketSerial, 'R1234567');
      expect(
        TalkRatingSubmitResult.fromJson(original.toJson()).toJson(),
        original.toJson(),
      );
      expect(TalkRatingSubmitResult.fromJson({}).saved, isFalse);
    });
  });
}
