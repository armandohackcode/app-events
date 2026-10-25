import 'package:app_events/data/datasources/firebase_speed_run_datasource.dart';
import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseSpeedRunDatasource datasource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    datasource = FirebaseSpeedRunDatasource(firestore, MockFirebaseStorage());
  });

  test('getChallenges reads speedRunBuild ordered by position', () async {
    final collection = firestore.collection('speedRunBuild');
    await collection.doc('b').set(makeChallenge(position: 2).toJson());
    await collection.doc('a').set(makeChallenge(position: 1).toJson());

    final challenges = await datasource.getChallenges();

    expect(challenges.map((c) => c.id), ['a', 'b']);
  });

  test('addChallenge without image stores an empty imageUrl', () async {
    await datasource.addChallenge(
      makeChallenge(id: 'ignored', state: ChallengeState.inactive),
    );

    final doc = (await firestore.collection('speedRunBuild').get()).docs.single;
    expect(doc.data()['imageUrl'], '');
    expect(doc.data()['state'], 'inactive');
    expect(doc.data().containsKey('id'), isFalse);
  });

  test('addChallenge treats an empty image path as no image', () async {
    // Same contract as the event and schedule datasources.
    await datasource.addChallenge(makeChallenge(), imagePath: '');

    final doc = (await firestore.collection('speedRunBuild').get()).docs;
    expect(doc.single.data()['imageUrl'], '');
  });
}
