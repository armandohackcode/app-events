import 'package:app_events/domain/datasources/other_datasource.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseOtherDatasource implements OtherDatasource {
  final FirebaseFirestore _db;
  FirebaseOtherDatasource(this._db);
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
          .orderBy("position", descending: false)
          .get();
      var info = res.docs.map((e) => Sponsor.fromJson(e.data())).toList();
      return info;
    } catch (e) {
      rethrow;
    }
  }
}
