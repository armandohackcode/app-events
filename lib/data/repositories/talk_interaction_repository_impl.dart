import 'package:app_events/domain/datasources/talk_interaction_datasource.dart';
import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/models/talk_rating.dart';
import 'package:app_events/domain/repositories/talk_interaction_repository.dart';

class TalkInteractionRepositoryImpl implements TalkInteractionRepository {
  final TalkInteractionDatasource _datasource;

  TalkInteractionRepositoryImpl(this._datasource);

  @override
  Stream<List<TalkQuestion>> watchQuestions(
    String eventId,
    String speakerUuid,
  ) => _datasource.watchQuestions(eventId, speakerUuid);

  @override
  Stream<TalkRating?> watchMyRating(
    String eventId,
    String speakerUuid,
    String uid,
  ) => _datasource.watchMyRating(eventId, speakerUuid, uid);

  @override
  Future<TalkQuestionSubmitResult> submitQuestion({
    required String eventId,
    required String speakerUuid,
    required String text,
  }) => _datasource.submitQuestion(
    eventId: eventId,
    speakerUuid: speakerUuid,
    text: text,
  );

  @override
  Future<TalkRatingSubmitResult> submitRating({
    required String eventId,
    required String speakerUuid,
    required int stars,
    String comment = '',
  }) => _datasource.submitRating(
    eventId: eventId,
    speakerUuid: speakerUuid,
    stars: stars,
    comment: comment,
  );
}
