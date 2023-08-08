import 'package:app_events/models/organizer.dart';
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
  bool _loadingSchedule = false;

  bool _activeWeb = false;
  bool _activeMobile = false;
  bool _activeCloud = false;
  bool _activeIA = false;

  bool _loadingResource = false;

  Speaker? _currentSpeaker;

  List<Speaker> _schedule = [];
  List<ResourceLibrary> _resources = [];
  List<Sponsor> _sponsors = [];
  List<Organizer> _organizers = [];
  List<UserCompetitor> _ranking = [];

  Speaker? get currentSpeaker => _currentSpeaker;
  set currentSpeaker(Speaker? data) {
    _currentSpeaker = data;
    notifyListeners();
  }

  bool get loadingResource => _loadingResource;
  set loadingResource(bool state) {
    _loadingResource = state;
    notifyListeners();
  }

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

  bool get loadingSchedule => _loadingSchedule;
  set loadingSchedule(bool state) {
    _loadingSchedule = state;
    notifyListeners();
  }

  final _db = FirebaseFirestore.instance;

  /// metodo para añadir un nuevo speaker o actividad al cronograma
  Future<void> addNewShedule(Speaker speaker) async {
    try {
      loadingNewSchedule = true;
      await _db.collection("schedule").doc(speaker.uuid).set(speaker.toJson());
      loadingNewSchedule = false;
    } catch (e) {
      loadingNewSchedule = false;
      if (kDebugMode) {
        print(e);
        print("Error al insertar un speaker");
      }
    }
  }

  /// metodo para escuchar los cambios en la Agenda
  Stream<QuerySnapshot<Map<String, dynamic>>> getListScheduleStream() async* {
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

  /// metodo para ontener la información de la Agenda
  Future<void> getListSchedule() async {
    try {
      loadingSchedule = true;
      var ref = _db.collection('schedule').orderBy('position');
      var data = await ref.get();
      schedule = data.docs.map((e) => Speaker.fromJson(e.data())).toList();
      loadingSchedule = false;
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
        // print('El usuario es un admin');
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

  /// Update token de autorización
  Future<void> updateToken(String token) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      await _db
          .collection("competidores")
          .doc(uuid)
          .update({"tokenAutorization": token});
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  /// Metodo para añadir un amigo
  Future<UserCompetitor?> addNewFriend(String token) async {
    try {
      var friends = userCompetitor!.friends;
      if (token.isEmpty) {
        return null;
      }

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

  /// Añadir participante de taller
  Future<bool> addWorkshop(String uuid) async {
    try {
      await _db.collection("schedule").doc(uuid).update({
        'current': FieldValue.increment(1),
      });
      await _db
          .collection("schedule")
          .doc(uuid)
          .collection("workshow")
          .doc()
          .set(Friend(
                  uuid: userCompetitor!.uuid,
                  name: userCompetitor!.name,
                  token: userCompetitor!.tokenAutorization,
                  photoUrl: userCompetitor!.photoUrl)
              .toJson());

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("falla");
        print(e);
      }
      return false;
    }
  }

  ///Escuchar datos de los cambios del speaker
  Stream<DocumentSnapshot<Map<String, dynamic>>> speakerStream(
      String uuid) async* {
    yield* _db.collection("schedule").doc(uuid).snapshots();
  }

  /// buscar si el participante esta inscrito
  Future<bool> searchUserInWorkShop(String uuid) async {
    try {
      var res = await _db
          .collection("schedule")
          .doc(uuid)
          .collection("workshow")
          .where("uuid", isEqualTo: userCompetitor?.uuid ?? "")
          .get();
      print("paso..");
      if (res.docs.isNotEmpty) {
        print("paso..");
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false;
    }
  }

  /// Agregar un nuevo recurso a la biblioteca
  Future<void> addResources(ResourceLibrary data) async {
    await _db.collection("resource-library").doc().set(data.toJson());
  }

  /// Se obtiene la información del competidor como usuario, y si no existe se crea
  Future<void> addCompetitor(
      {required String name,
      required String token,
      required String photoUrl}) async {
    var storage = await SharedPreferences.getInstance();
    var uuid = storage.getString('uid_user') ?? "";
    var data = await _db
        .collection("competidores")
        .where('uuid', isEqualTo: uuid)
        .get();
    if (data.docs.isNotEmpty) {
      userCompetitor = UserCompetitor.fromJson(data.docs.first.data());
    } else {
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
      userCompetitor = user;
    }
  }

  /// trae la información de un usuario con su UUID
  Future<UserCompetitor?> getUserInfo(String uuid) async {
    var data = await _db
        .collection("competidores")
        .where('uuid', isEqualTo: uuid)
        .get();
    if (data.docs.isNotEmpty) {
      return UserCompetitor.fromJson(data.docs.first.data());
    }
    return null;
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
    loadingResource = true;
    var res = await _db.collection("resource-library").get();
    var info = res.docs.map((e) => ResourceLibrary.fromJson(e.data())).toList();
    resources = info;
    loadingResource = false;
  }

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
