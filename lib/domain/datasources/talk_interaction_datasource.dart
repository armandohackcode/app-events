import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/models/talk_rating.dart';

/// Backend data contract for speaker Q&A and talk star ratings.
abstract interface class TalkInteractionDatasource {
  Stream<List<TalkQuestion>> watchQuestions(String eventId, String speakerUuid);

  Stream<TalkRating?> watchMyRating(
    String eventId,
    String speakerUuid,
    String uid,
  );

  Future<TalkQuestionSubmitResult> submitQuestion({
    required String eventId,
    required String speakerUuid,
    required String text,
  });

  Future<TalkRatingSubmitResult> submitRating({
    required String eventId,
    required String speakerUuid,
    required int stars,
    String comment = '',
  });
}
