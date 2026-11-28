import 'package:app_events/data/repositories/talk_interaction_repository_impl.dart';
import 'package:app_events/domain/datasources/talk_interaction_datasource.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/models/talk_rating.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTalkInteractionDatasource extends Mock
    implements TalkInteractionDatasource {}

void main() {
  late _MockTalkInteractionDatasource datasource;
  late TalkInteractionRepositoryImpl repository;

  const eventId = 'evt-1';
  const speakerUuid = 'spk-1';

  setUp(() {
    datasource = _MockTalkInteractionDatasource();
    repository = TalkInteractionRepositoryImpl(datasource);
  });

  test('delegates streams and mutations to datasource', () async {
    const question = TalkQuestion(id: 'q1', uid: 'u1', text: 'Question?');
    const rating = TalkRating(uid: 'u1', stars: 5, comment: 'Great');
    const qRes = TalkQuestionSubmitResult(questionId: 'q1');
    const rRes = TalkRatingSubmitResult(saved: true);

    when(
      () => datasource.watchQuestions(eventId, speakerUuid),
    ).thenAnswer((_) => Stream.value([question]));
    when(
      () => datasource.watchMyRating(eventId, speakerUuid, 'u1'),
    ).thenAnswer((_) => Stream.value(rating));
    when(
      () => datasource.submitQuestion(
        eventId: eventId,
        speakerUuid: speakerUuid,
        text: 'Question text',
      ),
    ).thenAnswer((_) async => qRes);
    when(
      () => datasource.submitRating(
        eventId: eventId,
        speakerUuid: speakerUuid,
        stars: 5,
        comment: 'Great',
      ),
    ).thenAnswer((_) async => rRes);

    expect(await repository.watchQuestions(eventId, speakerUuid).first, [
      question,
    ]);
    expect(
      await repository.watchMyRating(eventId, speakerUuid, 'u1').first,
      rating,
    );
    expect(
      await repository.submitQuestion(
        eventId: eventId,
        speakerUuid: speakerUuid,
        text: 'Question text',
      ),
      qRes,
    );
    expect(
      await repository.submitRating(
        eventId: eventId,
        speakerUuid: speakerUuid,
        stars: 5,
        comment: 'Great',
      ),
      rRes,
    );
  });

  test('propagates datasource errors asynchronously', () {
    when(
      () => datasource.submitQuestion(
        eventId: eventId,
        speakerUuid: speakerUuid,
        text: 'Too fast question',
      ),
    ).thenAnswer(
      (_) async => throw const SpinException(
        reason: SpinErrorReason.rateLimited,
        code: 'failed-precondition',
        message: 'Cooldown',
      ),
    );

    expect(
      repository.submitQuestion(
        eventId: eventId,
        speakerUuid: speakerUuid,
        text: 'Too fast question',
      ),
      throwsA(isA<SpinException>()),
    );
  });
}
