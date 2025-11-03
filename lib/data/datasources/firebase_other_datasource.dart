import 'dart:io';
import 'package:app_events/domain/datasources/other_datasource.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseOtherDatasource implements OtherDatasource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  FirebaseOtherDatasource(this._db, this._storage);

  @override
  Future<List<Organizer>> getOrganizer() async {
    try {
      var res = await _db
          .collection("organizers")
          .orderBy('type', descending: true)
          .get();
      var info = res.docs.map((e) => Organizer.fromJson(e.data())).toList();
      return info;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<UserCompetitor>> getRanking() async* {
    try {
      var data = _db
          .collection("competitors")
          .where('score', isGreaterThan: 20)
          .orderBy("score", descending: true)
          .limit(10)
          .snapshots();
      var res = data.map((snapshot) =>
          snapshot.docs.map((e) => UserCompetitor.fromJson(e.data())).toList());
      yield* res;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Sponsor>> getSponsors() async {
    try {
      var res = await _db
          .collection("sponsors")
          .orderBy("createdAt", descending: false)
          .get();
      var info = res.docs.map((e) => Sponsor.fromJson(e.data())).toList();
      return info;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addSponsor(Map<String, dynamic> sponsorData, String? sponsorImagePath) async {
    String photoUrl = sponsorData['photoUrl'] ?? '';

    if (sponsorImagePath != null && sponsorImagePath.isNotEmpty) {
      final imageFile = File(sponsorImagePath);
      final storageRef = _storage
          .ref()
          .child('sponsors')
          .child('${DateTime.now().millisecondsSinceEpoch}');

      await storageRef.putFile(imageFile);
      photoUrl = await storageRef.getDownloadURL();
    }

    sponsorData['photoUrl'] = photoUrl;
    sponsorData['createdAt'] = FieldValue.serverTimestamp();

    await _db.collection('sponsors').add(sponsorData);
    
  }
}
