import 'package:app_events/models/speaker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

class DataCenter with ChangeNotifier {
  bool _loadingNewSchedule = false;
  List<Speaker> _schedule = [];

  List<Speaker> get schedule => _schedule;

  set schedule(List<Speaker> list) {
    _schedule = list;
    notifyListeners();
  }

  bool get loadingNewSchedule => _loadingNewSchedule;
  set loadingNewSchedule(bool state) {
    _loadingNewSchedule = state;
    notifyListeners();
  }

  final _db = FirebaseFirestore.instance;

  /// metodo para añadir un nuevo speker o actividad al cronograma
  Future<void> addNewShedule(Speaker speaker) async {
    try {
      loadingNewSchedule = true;
      await _db.collection("schedule").doc().set(speaker.toJson());
      loadingNewSchedule = false;
    } catch (e) {
      loadingNewSchedule = false;
      if (kDebugMode) {
        print(e);
        print("Error al insertar un speaker");
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getListSchedule() async* {
    try {
      var ref = _db.collection('schedule').orderBy('position');
      yield* ref.snapshots();
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print("Error al traer cronograma");
      }
    }
  }
}
