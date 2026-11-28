import 'package:app_events/data/datasources/firebase_user_datasource.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

// cspell:ignore workshow
void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseUserDatasource datasource;

  const eventId = 'evt-1';
  const speakerUuid = 'spk-1';

  final competitor = UserCompetitor(
    uuid: 'uid-1',
    name: 'Ada Lovelace',
    photoUrl: 'https://example.com/ada.jpg',
    profession: 'Engineer',
    aboutMe: 'Loves compilers',
    tokenAuthorization: 'fcm-token',
    score: 0,
    socialNetwork: const [],
    friends: const [],
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    datasource = FirebaseUserDatasource(firestore);
    await firestore
        .collection('events')
        .doc(eventId)
        .collection('schedule')
        .doc(speakerUuid)
        .set(makeSpeaker(uuid: speakerUuid).toJson());
  });

  test(
    'addWorkshop enrolls under doc(uid) and atomically increments current',
    () async {
      final enrolled = await datasource.addWorkshop(
        eventId,
        speakerUuid,
        competitor,
      );

      expect(enrolled, isTrue);

      final scheduleSnap = await firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .get();
      expect(scheduleSnap.data()?['current'], 1);

      final workshowCol = firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .collection('workshow');
      final enrollmentSnap = await workshowCol.doc('uid-1').get();
      expect(enrollmentSnap.exists, isTrue);
      expect(enrollmentSnap.data(), {
        'uuid': 'uid-1',
        'name': 'Ada Lovelace',
        'token': 'fcm-token',
        'photoUrl': 'https://example.com/ada.jpg',
      });
    },
  );

  test(
    'addWorkshop prevents duplicate enrollment when doc(uid) already exists',
    () async {
      await datasource.addWorkshop(eventId, speakerUuid, competitor);
      final secondCall = await datasource.addWorkshop(
        eventId,
        speakerUuid,
        competitor,
      );

      expect(secondCall, isTrue);

      final scheduleSnap = await firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .get();
      expect(scheduleSnap.data()?['current'], 1);

      final enrollments = await firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .collection('workshow')
          .get();
      expect(enrollments.docs, hasLength(1));
    },
  );

  test(
    'addWorkshop prevents duplicate enrollment when legacy auto-id doc exists',
    () async {
      await firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .collection('workshow')
          .add({
            'uuid': 'uid-1',
            'name': 'Ada Lovelace',
            'token': 'fcm-token',
            'photoUrl': 'https://example.com/ada.jpg',
          });

      final result = await datasource.addWorkshop(
        eventId,
        speakerUuid,
        competitor,
      );

      expect(result, isTrue);
      final scheduleSnap = await firestore
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .get();
      expect(scheduleSnap.data()?['current'], 0);
    },
  );

  test('addWorkshop returns false when competitor uuid is empty', () async {
    final result = await datasource.addWorkshop(
      eventId,
      speakerUuid,
      competitor.copyWith(uuid: ''),
    );

    expect(result, isFalse);
  });
}
