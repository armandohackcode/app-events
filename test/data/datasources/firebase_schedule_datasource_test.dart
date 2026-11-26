import 'package:app_events/data/datasources/firebase_schedule_datasource.dart';
import 'package:app_events/domain/models/live_activity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

// Integration tests of the schedule datasource against an in-memory fake of
// Firestore: they check where the activities are stored and how the live flag
// travels between Firestore documents and the domain model.
void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseScheduleDatasource datasource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    datasource = FirebaseScheduleDatasource(firestore, MockFirebaseStorage());
  });

  DocumentReference<Map<String, dynamic>> scheduleDoc(String uuid) => firestore
      .collection('events')
      .doc('evt-1')
      .collection('schedule')
      .doc(uuid);

  Future<Map<String, dynamic>> stored(String uuid) async =>
      (await scheduleDoc(uuid).get()).data()!;

  test('a new activity is saved as not live', () async {
    await datasource.addNewSchedule('evt-1', makeSpeaker(uuid: 'a'));

    expect((await stored('a'))['isLive'], isFalse);
  });

  test('an activity saved without the flag reads as not live', () async {
    final data = makeSpeaker(uuid: 'old').toJson()..remove('isLive');
    await scheduleDoc('old').set(data);

    final schedule = await datasource.getListSchedule('evt-1');

    expect(schedule.single.isLive, isFalse);
  });

  test('getListSchedule reads the live flag', () async {
    await scheduleDoc('a').set(makeSpeaker(uuid: 'a').toJson());
    await scheduleDoc('b').set(makeSpeaker(uuid: 'b', isLive: true).toJson());

    final schedule = await datasource.getListSchedule('evt-1');

    expect(schedule.liveActivity?.uuid, 'b');
  });

  test('the schedule stream reports when the live flag changes', () async {
    await scheduleDoc('a').set(makeSpeaker(uuid: 'a', position: 1).toJson());
    await scheduleDoc('b').set(makeSpeaker(uuid: 'b', position: 2).toJson());

    final lives = <String?>[];
    final subscription = datasource
        .getListScheduleStream('evt-1')
        .listen((schedule) => lives.add(schedule.liveActivity?.uuid));
    await pumpEventQueue();

    await scheduleDoc('a').update({'isLive': true});
    await pumpEventQueue();
    await scheduleDoc('a').update({'isLive': false});
    await scheduleDoc('b').update({'isLive': true});
    await pumpEventQueue();
    await scheduleDoc('b').update({'isLive': false});
    await pumpEventQueue();
    await subscription.cancel();

    expect(lives.first, isNull);
    expect(lives, containsAllInOrder([null, 'a', 'b', null]));
  });

  test('editing an activity does not overwrite the live flag', () async {
    await scheduleDoc('a').set(makeSpeaker(uuid: 'a', title: 'Old').toJson());
    // The edit form loaded the activity while it was not live...
    final loaded = makeSpeaker(uuid: 'a', title: 'Old');
    // ...and then it went live in Firebase before the admin saved the edit.
    await scheduleDoc('a').update({'isLive': true});

    await datasource.updateSchedule('evt-1', loaded.copyWith(title: 'New'));

    final data = await stored('a');
    expect(data['title'], 'New');
    expect(data['isLive'], isTrue);
  });

  test('editing an activity does not turn the live flag on', () async {
    await scheduleDoc('a').set(makeSpeaker(uuid: 'a').toJson());

    await datasource.updateSchedule(
      'evt-1',
      makeSpeaker(uuid: 'a', isLive: true),
    );

    expect((await stored('a'))['isLive'], isFalse);
  });
}
