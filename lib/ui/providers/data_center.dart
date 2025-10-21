import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DataCenter with ChangeNotifier {
  List<Sponsor> _sponsors = [];
  List<Organizer> _organizers = [];
  List<UserCompetitor> _ranking = [];

  List<Organizer> get organizers => _organizers;
  set organizers(List<Organizer> list) {
    _organizers = list;
    notifyListeners();
  }

  List<UserCompetitor> get ranking => _ranking;
  set ranking(List<UserCompetitor> list) {
    _ranking = list;
    notifyListeners();
  }

  List<Sponsor> get sponsors => _sponsors;
  set sponsors(List<Sponsor> list) {
    _sponsors = list;
    notifyListeners();
  }

  final _db = FirebaseFirestore.instance;

  ///Trae la lista de sponsors
  Future<void> getSponsors() async {
    var res = await _db
        .collection("sponsors")
        .orderBy("position", descending: false)
        .get();
    var info = res.docs.map((e) => Sponsor.fromJson(e.data())).toList();
    sponsors = info;
  }

  /// Organizers
  Future<void> getOrganizer() async {
    var res = await _db
        .collection("organizers")
        .orderBy('type', descending: true)
        .get();
    var info = res.docs.map((e) => Organizer.fromJson(e.data())).toList();
    organizers = info;
  }

  /// Ranking de posisiones
  Stream<QuerySnapshot<Map<String, dynamic>>> getRanking() async* {
    yield* _db
        .collection("competidores")
        .where('score', isGreaterThan: 20)
        .orderBy("score", descending: true)
        .limit(10)
        .snapshots();
  }
}
