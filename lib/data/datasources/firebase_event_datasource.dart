import 'dart:io';

import 'package:app_events/domain/datasources/event_datasource.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseEventDatasource implements EventDatasource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  FirebaseEventDatasource(this._db, this._storage);

  @override
  Future<List<Event>> getEvents() async {
    try {
      var ref = _db.collection('events').orderBy('startDate');
      var data = await ref.get();
      return data.docs.map((e) {
        final json = e.data();
        json['id'] = e.id;
        return Event.fromJson(json);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<Event>> getEventsStream() {
    var ref = _db.collection('events').orderBy('startDate');
    return ref.snapshots().map(
      (snapshot) => snapshot.docs.map((e) {
        final json = e.data();
        json['id'] = e.id;
        return Event.fromJson(json);
      }).toList(),
    );
  }

  @override
  Future<void> addEvent(Event event, {String? imagePath}) async {
    try {
      String imageUrl = event.imageUrl;
      if (imagePath != null && imagePath.isNotEmpty) {
        final storageRef = _storage
            .ref()
            .child('events')
            .child('${DateTime.now().millisecondsSinceEpoch}');
        await storageRef.putFile(File(imagePath));
        imageUrl = await storageRef.getDownloadURL();
      }
      final docRef = _db.collection('events').doc();
      final json = event.copyWith(id: docRef.id, imageUrl: imageUrl).toJson();
      await docRef.set(json);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateEvent(Event event, {String? imagePath}) async {
    try {
      String imageUrl = event.imageUrl;
      if (imagePath != null && imagePath.isNotEmpty) {
        final storageRef = _storage
            .ref()
            .child('events')
            .child('${DateTime.now().millisecondsSinceEpoch}');
        await storageRef.putFile(File(imagePath));
        imageUrl = await storageRef.getDownloadURL();
      }
      final json = event.copyWith(imageUrl: imageUrl).toJson();
      json.remove('id');
      await _db.collection('events').doc(event.id).update(json);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    try {
      await _db.collection('events').doc(eventId).update({
        'status': status.value,
      });
    } catch (e) {
      rethrow;
    }
  }
}
