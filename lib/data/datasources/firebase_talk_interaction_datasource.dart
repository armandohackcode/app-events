import 'package:app_events/data/datasources/firestore_normalizer.dart';
import 'package:app_events/domain/datasources/talk_interaction_datasource.dart';
import 'package:app_events/domain/models/talk_question.dart';
import 'package:app_events/domain/models/talk_rating.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Firebase implementation of [TalkInteractionDatasource] using Firestore streams
/// and Cloud Functions v2 callables.
class FirebaseTalkInteractionDatasource implements TalkInteractionDatasource {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  FirebaseTalkInteractionDatasource(this._db, this._functions);

  DocumentReference<Map<String, dynamic>> _speakerDoc(
    String eventId,
    String speakerUuid,
  ) => _db
      .collection('events')
      .doc(eventId)
      .collection('schedule')
      .doc(speakerUuid);

  @override
  Stream<List<TalkQuestion>> watchQuestions(
    String eventId,
    String speakerUuid,
  ) {
    return _speakerDoc(eventId, speakerUuid)
        .collection('questions')
        .where('hidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = normalizeFirestoreMap(doc.data());
                final currentId = data['id'];
                if (currentId is! String || currentId.isEmpty) {
                  data['id'] = doc.id;
                }
                return TalkQuestion.fromJson(data);
              })
              .toList(growable: false);
        });
  }

  @override
  Stream<TalkRating?> watchMyRating(
    String eventId,
    String speakerUuid,
    String uid,
  ) {
    return _speakerDoc(
      eventId,
      speakerUuid,
    ).collection('ratings').doc(uid).snapshots().map((snapshot) {
      final raw = snapshot.data();
      if (!snapshot.exists || raw == null) return null;
      final data = normalizeFirestoreMap(raw);
      final currentUid = data['uid'];
      if (currentUid is! String || currentUid.isEmpty) {
        data['uid'] = snapshot.id;
      }
      return TalkRating.fromJson(data);
    });
  }

  @override
  Future<TalkQuestionSubmitResult> submitQuestion({
    required String eventId,
    required String speakerUuid,
    required String text,
  }) async {
    final data = await callFunctionsMap(_functions, 'spinSubmitTalkQuestion', {
      'eventId': eventId,
      'speakerUuid': speakerUuid,
      'text': text,
    });
    return TalkQuestionSubmitResult.fromJson(data);
  }

  @override
  Future<TalkRatingSubmitResult> submitRating({
    required String eventId,
    required String speakerUuid,
    required int stars,
    String comment = '',
  }) async {
    final data = await callFunctionsMap(_functions, 'spinSubmitTalkRating', {
      'eventId': eventId,
      'speakerUuid': speakerUuid,
      'stars': stars,
      'comment': comment,
    });
    return TalkRatingSubmitResult.fromJson(data);
  }
}
