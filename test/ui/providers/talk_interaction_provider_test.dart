import 'dart:async';

import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/models/talk_rating.dart';
import 'package:app_events/domain/repositories/talk_interaction_repository.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTalkInteractionRepository extends Mock
    implements TalkInteractionRepository {}

void main() {
  late _MockTalkInteractionRepository repository;
  late TalkInteractionProvider provider;

  setUp(() {
    repository = _MockTalkInteractionRepository();
    provider = TalkInteractionProvider(repository);
  });

  tearDown(() => provider.dispose());

  test('delegates watchQuestions and watchMyRating streams', () async {
    final questions = [
      const TalkQuestion(
        id: 'q1',
        uid: 'u1',
        text: 'How does Cloud Run scale?',
      ),
    ];
    const rating = TalkRating(uid: 'u1', stars: 5, comment: 'Great talk');

    when(
      () => repository.watchQuestions('evt-1', 'spk-1'),
    ).thenAnswer((_) => Stream.value(questions));
    when(
      () => repository.watchMyRating('evt-1', 'spk-1', 'u1'),
    ).thenAnswer((_) => Stream.value(rating));

    await expectLater(
      provider.watchQuestions('evt-1', 'spk-1'),
      emits(questions),
    );
    await expectLater(
      provider.watchMyRating('evt-1', 'spk-1', 'u1'),
      emits(rating),
    );
  });

  test(
    'submitQuestion toggles submittingQuestion and resets in finally',
    () async {
      final completer = Completer<TalkQuestionSubmitResult>();
      when(
        () => repository.submitQuestion(
          eventId: 'evt-1',
          speakerUuid: 'spk-1',
          text: 'What about cold starts?',
        ),
      ).thenAnswer((_) => completer.future);

      final states = <bool>[];
      provider.addListener(() => states.add(provider.submittingQuestion));

      final future = provider.submitQuestion(
        eventId: 'evt-1',
        speakerUuid: 'spk-1',
        text: 'What about cold starts?',
      );
      expect(provider.submittingQuestion, isTrue);

      completer.complete(
        const TalkQuestionSubmitResult(
          questionId: 'q1',
          missionRewarded: true,
          ticketsAwarded: 1,
          ticketsAfter: 3,
          ticketSerial: 'Q1234567',
        ),
      );
      final result = await future;

      expect(result.questionId, 'q1');
      expect(result.missionRewarded, isTrue);
      expect(provider.submittingQuestion, isFalse);
      expect(states, [true, false]);
    },
  );

  test('submitQuestion resets loading flag and rethrows on error', () async {
    when(
      () => repository.submitQuestion(
        eventId: 'evt-1',
        speakerUuid: 'spk-1',
        text: 'Rate limited question',
      ),
    ).thenAnswer(
      (_) async => throw const SpinException(
        reason: SpinErrorReason.rateLimited,
        code: 'resource-exhausted',
        message: 'too fast',
      ),
    );

    await expectLater(
      provider.submitQuestion(
        eventId: 'evt-1',
        speakerUuid: 'spk-1',
        text: 'Rate limited question',
      ),
      throwsA(isA<SpinException>()),
    );
    expect(provider.submittingQuestion, isFalse);
  });

  test(
    'submitRating toggles submittingRating and resets on success and failure',
    () async {
      when(
        () => repository.submitRating(
          eventId: 'evt-1',
          speakerUuid: 'spk-1',
          stars: 5,
          comment: 'Loved the demo',
        ),
      ).thenAnswer(
        (_) async => const TalkRatingSubmitResult(
          saved: true,
          missionRewarded: true,
          ticketsAwarded: 1,
          ticketsAfter: 4,
          ticketSerial: 'R9988776',
        ),
      );

      final result = await provider.submitRating(
        eventId: 'evt-1',
        speakerUuid: 'spk-1',
        stars: 5,
        comment: 'Loved the demo',
      );
      expect(result.saved, isTrue);
      expect(provider.submittingRating, isFalse);

      when(
        () => repository.submitRating(
          eventId: 'evt-1',
          speakerUuid: 'spk-1',
          stars: 4,
          comment: '',
        ),
      ).thenAnswer((_) async => throw Exception('offline'));

      await expectLater(
        provider.submitRating(eventId: 'evt-1', speakerUuid: 'spk-1', stars: 4),
        throwsException,
      );
      expect(provider.submittingRating, isFalse);
    },
  );
}
