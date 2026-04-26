import 'dart:io';

import 'package:app_events/domain/datasources/schedule_datasource.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseScheduleDatasource implements ScheduleDatasource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  FirebaseScheduleDatasource(this._db, this._storage);

  CollectionReference<Map<String, dynamic>> _scheduleRef(String eventId) =>
      _db.collection('events').doc(eventId).collection('schedule');

  @override
  Future<void> addNewSchedule(String eventId, Speaker speaker, {String? imagePath}) async {
    try {
      String photoUrl = speaker.photoUrl;
      if (imagePath != null && imagePath.isNotEmpty) {
        final storageRef = _storage
            .ref()
            .child('speakers')
            .child('${DateTime.now().millisecondsSinceEpoch}');
        await storageRef.putFile(File(imagePath));
        photoUrl = await storageRef.getDownloadURL();
      }
      await _scheduleRef(eventId)
          .doc(speaker.uuid)
          .set(speaker.copyWith(photoUrl: photoUrl).toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Speaker>> getListSchedule(String eventId) async {
    try {
      var data = await _scheduleRef(eventId).orderBy('position').get();
      return data.docs.map((e) => Speaker.fromJson(e.data())).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<Speaker>> getListScheduleStream(String eventId) {
    return _scheduleRef(eventId).orderBy('position').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((e) => Speaker.fromJson(e.data())).toList(),
        );
  }

  @override
  Stream<Speaker?> speakerStream(String eventId, String speakerUuid) {
    return _scheduleRef(eventId).doc(speakerUuid).snapshots().map(
          (e) => e.exists ? Speaker.fromJson(e.data()!) : null,
        );
  }
}
