import 'package:app_events/models/resource_library.dart';
import 'package:app_events/models/speaker.dart';
import 'package:app_events/models/sponsor.dart';
import 'package:app_events/models/user_competitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataCenter with ChangeNotifier {
  UserCompetitor? _userCompetitor;
  bool _isAdmin = false;

  bool _loadingNewSchedule = false;

  bool _activeWeb = false;
  bool _activeMobile = false;
  bool _activeCloud = false;
  bool _activeIA = false;

  List<Speaker> _schedule = [];
  List<ResourceLibrary> _resources = [];
  List<Sponsor> _sponsors = [];

  bool get isAdmin => _isAdmin;
  set isAdmin(bool state) {
    _isAdmin = state;
    notifyListeners();
  }

  UserCompetitor? get userCompetitor => _userCompetitor;

  bool get activeWeb => _activeWeb;
  bool get activeMobile => _activeMobile;
  bool get activeCloud => _activeCloud;
  bool get activeIA => _activeIA;

  set userCompetitor(UserCompetitor? data) {
    _userCompetitor = data;
    notifyListeners();
  }

  set activeWeb(bool state) {
    _activeWeb = state;
    notifyListeners();
  }

  set activeMobile(bool state) {
    _activeMobile = state;
    notifyListeners();
  }

  set activeCloud(bool state) {
    _activeCloud = state;
    notifyListeners();
  }

  set activeIA(bool state) {
    _activeIA = state;
    notifyListeners();
  }

  List<ResourceLibrary> get resources => _resources;
  set resources(List<ResourceLibrary> list) {
    _resources = list;
    notifyListeners();
  }

  List<Speaker> get schedule => _schedule;

  set schedule(List<Speaker> list) {
    _schedule = list;
    notifyListeners();
  }

  List<Sponsor> get sponsors => _sponsors;
  set sponsors(List<Sponsor> list) {
    _sponsors = list;
    notifyListeners();
  }

  bool get loadingNewSchedule => _loadingNewSchedule;
  set loadingNewSchedule(bool state) {
    _loadingNewSchedule = state;
    notifyListeners();
  }

  final _db = FirebaseFirestore.instance;

  /// metodo para añadir un nuevo speaker o actividad al cronograma
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

  /// Metodo para consultar si el usuario es un admin
  Future<void> validateIsAdmin(String uuid) async {
    try {
      var res = await _db
          .collection("users-admin")
          .where('uuid', isEqualTo: uuid)
          .get();
      if (res.docs.isNotEmpty) {
        isAdmin = true;
        print('El usuario es un admin');
      }
      var data = await _db
          .collection("competidores")
          .where('uuid', isEqualTo: uuid)
          .get();
      if (data.docs.isNotEmpty) {
        userCompetitor = UserCompetitor.fromJson(data.docs.first.data());
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print("Error al consultar información de admins");
      }
    }
  }

  /// Metodo para añadir un amigo
  Future<UserCompetitor?> addNewFriend(String token) async {
    try {
      var friends = userCompetitor!.friends;

      /// validar que no haya agregado al amigo 2 veces
      if (friends.where((element) => element.token == token).isNotEmpty ||
          token == userCompetitor?.tokenAutorization) {
        return null;
      }
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      var res = await _db
          .collection("competidores")
          .where('tokenAutorization', isEqualTo: token)
          .get();
      if (res.docs.isNotEmpty) {
        var user = UserCompetitor.fromJson(res.docs.first.data());
        friends.add(
          Friend(
            uuid: user.uuid,
            name: user.name,
            token: user.tokenAutorization,
            photoUrl: user.photoUrl,
          ),
        );
        await _db.collection("competidores").doc(uuid).update({
          'score': FieldValue.increment(10),
          'friends': List<dynamic>.from(friends.map((x) => x.toJson()))
        });
        return user;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  /// Agregar un nuevo recurso a la biblioteca
  Future<void> addResources(ResourceLibrary data) async {
    await _db.collection("resource-library").doc().set(data.toJson());
  }

  /// Habilitar competidor
  Future<void> addCompetitor(
      {required String name,
      required String token,
      required String photoUrl}) async {
    var storage = await SharedPreferences.getInstance();
    var uuid = storage.getString('uid_user') ?? "";
    var user = UserCompetitor(
        uuid: uuid,
        name: name,
        photoUrl: photoUrl,
        profession: "",
        aboutMe: "",
        tokenAutorization: token,
        score: 0,
        socialNetwork: [],
        friends: []);
    await _db.collection("competidores").doc(uuid).set(user.toJson());
  }

  /// Escuchar información del usuario
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamInfoUser() async* {
    yield* _db.collection("competidores").doc(userCompetitor!.uuid).snapshots();
  }

  /// Actualizar Editar Información
  Future<void> editCompetitor(UserCompetitor user) async {
    var storage = await SharedPreferences.getInstance();
    var uuid = storage.getString('uid_user');
    await _db.collection("competidores").doc(uuid).set(user.toJson());
  }

  /// Trae la lista de todos los recursos de la biblioteca
  Future<void> getResources() async {
    var res = await _db.collection("resource-library").get();
    var info = res.docs.map((e) => ResourceLibrary.fromJson(e.data())).toList();
    resources = info;
  }

  ///Trae la lista de sponsors
  Future<void> getSponsors() async {
    var res = await _db.collection("sponsors").get();
    var info = res.docs.map((e) => Sponsor.fromJson(e.data())).toList();
    sponsors = info;
  }

  /// Buscar un recurso de la biblioteca
  Future<void> searchResource({
    String? param,
  }) async {
    await getResources();
    var data = resources;
    if ((param ?? "").isNotEmpty) {
      data = resources
          .where((element) =>
              element.title.toLowerCase().contains((param ?? "").toLowerCase()))
          .toList();
    }

    if (activeWeb || activeMobile || activeCloud || activeIA) {
      data = data
          .where((element) =>
              (element.type == ("Web") && activeWeb) ||
              (element.type == ("Mobile") && activeMobile) ||
              (element.type == ("Cloud") && activeCloud) ||
              (element.type == ("IA") && activeIA))
          .toList();
    }

    resources = data;
  }

  cleanTag() {
    activeWeb = false;
    activeMobile = false;
    activeCloud = false;
    activeIA = false;
  }
}
