import 'package:app_events/domain/models/talk_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TalkQuestion', () {
    test('fromJson uses safe defaults for empty map', () {
      final question = TalkQuestion.fromJson({});

      expect(question.id, '');
      expect(question.uid, '');
      expect(question.authorName, '');
      expect(question.authorPhotoUrl, '');
      expect(question.text, '');
      expect(question.answered, isFalse);
      expect(question.hidden, isFalse);
      expect(question.createdAt, isNull);
    });

    test('round-trip toJson and fromJson preserves all fields', () {
      final original = TalkQuestion(
        id: 'q-1',
        uid: 'u-1',
        authorName: 'Ada',
        authorPhotoUrl: 'https://example.com/ada.jpg',
        text: 'How do you manage Cloud Run cold starts?',
        answered: true,
        hidden: false,
        createdAt: DateTime.utc(2026, 11, 28, 10, 15),
      );

      final json = original.toJson();
      final restored = TalkQuestion.fromJson(json);

      expect(restored.toJson(), json);
    });

    test('copyWith updates given fields and clears createdAt', () {
      final original = TalkQuestion(
        id: 'q-1',
        uid: 'u-1',
        text: 'Question text',
        createdAt: DateTime.utc(2026, 11, 28, 10),
      );

      final updated = original.copyWith(answered: true, clearCreatedAt: true);

      expect(updated.answered, isTrue);
      expect(updated.createdAt, isNull);
    });
  });

  group('TalkQuestionSubmitResult', () {
    test('fromJson and toJson round-trip cleanly', () {
      final original = TalkQuestionSubmitResult.fromJson({
        'questionId': 'q-1',
        'missionRewarded': true,
        'ticketsAwarded': 1,
        'ticketsAfter': 4,
        'ticketSerial': 'Q1234567',
      });

      expect(original.questionId, 'q-1');
      expect(original.missionRewarded, isTrue);
      expect(original.ticketsAwarded, 1);
      expect(original.ticketsAfter, 4);
      expect(original.ticketSerial, 'Q1234567');
      expect(
        TalkQuestionSubmitResult.fromJson(original.toJson()).toJson(),
        original.toJson(),
      );
      expect(TalkQuestionSubmitResult.fromJson({}).missionRewarded, isFalse);
    });
  });
}
