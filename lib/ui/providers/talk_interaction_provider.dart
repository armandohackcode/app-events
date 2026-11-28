import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/models/talk_rating.dart';
import 'package:app_events/domain/repositories/talk_interaction_repository.dart';
import 'package:flutter/foundation.dart';

/// Presentation provider for speaker Q&A and attendee talk ratings.
class TalkInteractionProvider extends ChangeNotifier {
  final TalkInteractionRepository _repository;

  TalkInteractionProvider(this._repository);

  bool _submittingQuestion = false;
  bool _submittingRating = false;
  bool _disposed = false;

  bool get submittingQuestion => _submittingQuestion;
  bool get submittingRating => _submittingRating;

  Stream<List<TalkQuestion>> watchQuestions(
    String eventId,
    String speakerUuid,
  ) => _repository.watchQuestions(eventId, speakerUuid);

  Stream<TalkRating?> watchMyRating(
    String eventId,
    String speakerUuid,
    String uid,
  ) => _repository.watchMyRating(eventId, speakerUuid, uid);

  Future<TalkQuestionSubmitResult> submitQuestion({
    required String eventId,
    required String speakerUuid,
    required String text,
  }) async {
    _submittingQuestion = true;
    notifyListeners();
    try {
      return await _repository.submitQuestion(
        eventId: eventId,
        speakerUuid: speakerUuid,
        text: text,
      );
    } finally {
      _submittingQuestion = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<TalkRatingSubmitResult> submitRating({
    required String eventId,
    required String speakerUuid,
    required int stars,
    String comment = '',
  }) async {
    _submittingRating = true;
    notifyListeners();
    try {
      return await _repository.submitRating(
        eventId: eventId,
        speakerUuid: speakerUuid,
        stars: stars,
        comment: comment,
      );
    } finally {
      _submittingRating = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
