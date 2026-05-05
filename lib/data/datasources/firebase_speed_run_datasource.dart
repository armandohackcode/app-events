import 'dart:io';

import 'package:app_events/domain/datasources/speed_run_datasource.dart';
import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseSpeedRunDatasource implements SpeedRunDatasource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  FirebaseSpeedRunDatasource(this._db, this._storage);

  @override
  Future<List<SpeedRunChallenge>> getChallenges() async {
    try {
      final data = await _db
          .collection('speedRunBuild')
          .orderBy('position')
          .get();
      return data.docs.map((e) {
        final json = e.data();
        json['id'] = e.id;
        return SpeedRunChallenge.fromJson(json);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addChallenge(
    SpeedRunChallenge challenge, {
    String? imagePath,
  }) async {
    String imageUrl = '';
    if (imagePath != null) {
      final ref = _storage
          .ref()
          .child('speedRunBuild/${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(File(imagePath));
      imageUrl = await ref.getDownloadURL();
    }
    final json = challenge.toJson()
      ..remove('id')
      ..['imageUrl'] = imageUrl;
    await _db.collection('speedRunBuild').add(json);
  }
}
