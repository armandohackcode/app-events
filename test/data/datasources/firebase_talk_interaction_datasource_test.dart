import 'package:app_events/data/datasources/firebase_talk_interaction_datasource.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockFirebaseFunctions functions;
  late FirebaseTalkInteractionDatasource datasource;

  const eventId = 'evt-1';
  const speakerUuid = 'spk-1';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    functions = _MockFirebaseFunctions();
    datasource = FirebaseTalkInteractionDatasource(firestore, functions);
  });

  test(
    'watchQuestions filters hidden=false and orders by createdAt descending',
    () async {
      final col = firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .collection('questions');

      await col.doc('q1').set({
        'uid': 'u1',
        'authorName': 'Ada',
        'text': 'First question?',
        'answered': false,
        'hidden': false,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 10)),
      });
      await col.doc('q2').set({
        'uid': 'u2',
        'authorName': 'Grace',
        'text': 'Second question?',
        'answered': false,
        'hidden': false,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 11)),
      });
      await col.doc('q3').set({
        'uid': 'u3',
        'authorName': 'Hidden',
        'text': 'Moderated out',
        'answered': false,
        'hidden': true,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 12)),
      });

      final questions = await datasource
          .watchQuestions(eventId, speakerUuid)
          .first;
      expect(questions.map((q) => q.id), ['q2', 'q1']);
    },
  );

  test(
    'watchMyRating emits null when missing and rating when present',
    () async {
      expect(
        await datasource.watchMyRating(eventId, speakerUuid, 'u1').first,
        isNull,
      );

      await firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .collection('ratings')
          .doc('u1')
          .set({
            'stars': 5,
            'comment': 'Awesome talk',
            'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 12)),
            'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 28, 12)),
          });

      final rating = await datasource
          .watchMyRating(eventId, speakerUuid, 'u1')
          .first;
      expect(rating?.uid, 'u1');
      expect(rating?.stars, 5);
      expect(rating?.comment, 'Awesome talk');
    },
  );

  test(
    'submitQuestion and submitRating invoke callables and map errors',
    () async {
      final qCallable = _MockHttpsCallable();
      final qResult = _MockHttpsCallableResult();
      when(() => qResult.data).thenReturn({
        'questionId': 'q-99',
        'missionRewarded': true,
        'ticketsAwarded': 1,
        'ticketsAfter': 4,
        'ticketSerial': 'Q1234567',
      });
      when(
        () => functions.httpsCallable('spinSubmitTalkQuestion'),
      ).thenReturn(qCallable);
      when(
        () => qCallable.call<dynamic>(any()),
      ).thenAnswer((_) async => qResult);

      final qRes = await datasource.submitQuestion(
        eventId: eventId,
        speakerUuid: speakerUuid,
        text: 'How do you test transactions?',
      );
      expect(qRes.questionId, 'q-99');
      expect(qRes.missionRewarded, isTrue);

      final rCallable = _MockHttpsCallable();
      final rResult = _MockHttpsCallableResult();
      when(() => rResult.data).thenReturn({
        'saved': true,
        'missionRewarded': false,
        'ticketsAwarded': 0,
        'ticketsAfter': 4,
        'ticketSerial': null,
      });
      when(
        () => functions.httpsCallable('spinSubmitTalkRating'),
      ).thenReturn(rCallable);
      when(
        () => rCallable.call<dynamic>(any()),
      ).thenAnswer((_) async => rResult);

      final rRes = await datasource.submitRating(
        eventId: eventId,
        speakerUuid: speakerUuid,
        stars: 5,
        comment: 'Loved it',
      );
      expect(rRes.saved, isTrue);

      when(() => qCallable.call<dynamic>(any())).thenThrow(
        // ignore: invalid_use_of_protected_member
        FirebaseFunctionsException(
          message: 'Too fast',
          code: 'failed-precondition',
          details: {'reason': 'RATE_LIMITED'},
        ),
      );
      await expectLater(
        datasource.submitQuestion(
          eventId: eventId,
          speakerUuid: speakerUuid,
          text: 'Another question here',
        ),
        throwsA(
          isA<SpinException>().having(
            (e) => e.reason,
            'reason',
            SpinErrorReason.rateLimited,
          ),
        ),
      );
    },
  );
}
