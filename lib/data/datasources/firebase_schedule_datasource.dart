import 'package:app_events/domain/datasources/schedule_datasource.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseScheduleDatasource implements ScheduleDatasource {
  final FirebaseFirestore _db;
  FirebaseScheduleDatasource(this._db);
  @override
  Future<void> addNewSchedule(Speaker speaker) async {
    try {
      await _db.collection("schedule").doc(speaker.uuid).set(speaker.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Speaker>> getListSchedule() async {
    try {
      var ref = _db.collection('schedule').orderBy('position');
      var data = await ref.get();
      var schedule = data.docs.map((e) => Speaker.fromJson(e.data())).toList();
      return schedule;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<List<Speaker>> getListScheduleStream() async* {
    try {
      var ref = _db.collection('schedule').orderBy('position');
      var res = ref.snapshots().map((snapshot) =>
          snapshot.docs.map((e) => Speaker.fromJson(e.data())).toList());
      yield* res;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<Speaker?> speakerStream(String uuid) {
    try {
      var res = _db.collection("schedule").doc(uuid).snapshots();
      return res.map((e) => e.exists ? Speaker.fromJson(e.data()!) : null);
    } catch (e) {
      rethrow;
    }
  }
}
