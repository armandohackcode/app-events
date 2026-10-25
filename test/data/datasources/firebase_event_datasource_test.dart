import 'dart:io';

import 'package:app_events/data/datasources/firebase_event_datasource.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

// Integration tests of the Firebase datasource against in-memory fakes of
// Firestore and Storage: they check collection names, document shape and
// the mapping between Firestore documents and domain models.
void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseEventDatasource datasource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    datasource = FirebaseEventDatasource(firestore, MockFirebaseStorage());
  });

  Future<Map<String, dynamic>> storedEvent(String id) async =>
      (await firestore.collection('events').doc(id).get()).data()!;

  test('getEvents returns events ordered by startDate with doc ids', () async {
    await firestore
        .collection('events')
        .doc('late')
        .set(makeEvent(startDate: DateTime(2025, 12)).toJson()..remove('id'));
    await firestore
        .collection('events')
        .doc('early')
        .set(makeEvent(startDate: DateTime(2025, 1)).toJson()..remove('id'));

    final events = await datasource.getEvents();

    expect(events.map((e) => e.id), ['early', 'late']);
  });

  test('addEvent stores the document using the generated id', () async {
    await datasource.addEvent(makeEvent(id: '', title: 'New'));

    final docs = (await firestore.collection('events').get()).docs;
    expect(docs, hasLength(1));
    expect(docs.single.data()['id'], docs.single.id);
    expect(docs.single.data()['title'], 'New');
  });

  test('addEvent uploads the image and stores its download url', () async {
    final dir = Directory.systemTemp.createTempSync('event_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final image = File('${dir.path}/cover.jpg')..writeAsBytesSync([1, 2, 3]);

    await datasource.addEvent(makeEvent(id: ''), imagePath: image.path);

    final doc = (await firestore.collection('events').get()).docs.single;
    expect(doc.data()['imageUrl'], isNotEmpty);
  });

  test('updateEvent updates fields without writing the id', () async {
    await firestore.collection('events').doc('evt-1').set({
      ...makeEvent().toJson()..remove('id'),
    });

    await datasource.updateEvent(makeEvent(title: 'Renamed'));

    final data = await storedEvent('evt-1');
    expect(data['title'], 'Renamed');
    expect(data.containsKey('id'), isFalse);
  });

  test('updateEventStatus stores the status string value', () async {
    await firestore.collection('events').doc('evt-1').set(makeEvent().toJson());

    await datasource.updateEventStatus('evt-1', EventStatus.active);

    expect((await storedEvent('evt-1'))['status'], 'active');
  });

  test('getEventsStream emits changes in real time', () async {
    final stream = datasource.getEventsStream();

    expect(stream.map((events) => events.length), emitsInOrder([0, 1]));
    await firestore.collection('events').add(makeEvent().toJson());
  });
}
