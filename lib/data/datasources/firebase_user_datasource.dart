import 'package:app_events/domain/datasources/user_datasource.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseUserDatasource implements UserDatasource {
  final FirebaseFirestore _db;
  FirebaseUserDatasource(this._db);
  @override
  Future<UserCompetitor?> addNewFriend(
      String token, UserCompetitor userCompetitor) async {
    try {
      var friends = userCompetitor.friends;

      if (friends.where((element) => element.uuid == token).isNotEmpty ||
          token == userCompetitor.uuid) {
        return null;
      }
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      var res = await _db
          .collection("competitors")
          .where('uuid', isEqualTo: token)
          .get();
      if (res.docs.isNotEmpty) {
        var user = UserCompetitor.fromJson(res.docs.first.data());
        friends.add(
          Friend(
            uuid: user.uuid,
            name: user.name,
            token: user.tokenAuthorization,
            photoUrl: user.photoUrl,
          ),
        );
        await _db.collection("competitors").doc(uuid).update({
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

  @override
  Future<void> addScoreAdmin(String uuid) async {
    try {
      await _db.collection("competitors").doc(uuid).update({
        'score': FieldValue.increment(10),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> addWorkshop(String uuid, UserCompetitor userCompetitor) async {
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
                  uuid: userCompetitor.uuid,
                  name: userCompetitor.name,
                  token: userCompetitor.tokenAuthorization,
                  photoUrl: userCompetitor.photoUrl)
              .toJson());

      return true;
    } catch (e) {
      if (kDebugMode) {
        print("addWorkshop failed");
        print(e);
      }
      return false;
    }
  }

  @override
  Future<UserCompetitor?> addCompetitor(UserCompetitor user) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      final res = await getUserInfo(uuid);
      if (res != null) {
        return res;
      } else {
        user = user.copyWith(uuid: uuid);
        await _db.collection("competitors").doc(user.uuid).set(user.toJson());
        return user;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> editCompetitor(UserCompetitor user) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      await _db.collection("competitors").doc(uuid).update(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserCompetitor?> getUserInfo(String uuid) async {
    try {
      var data = await _db
          .collection("competitors")
          .where('uuid', isEqualTo: uuid)
          .get();
      if (data.docs.isNotEmpty) {
        return UserCompetitor.fromJson(data.docs.first.data());
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserCompetitor>> searchAttendees({String? param}) async {
    try {
      var res = await _db.collection("competitors").get();
      var attendees =
          res.docs.map((e) => UserCompetitor.fromJson(e.data())).toList();
      var data = attendees;
      if ((param ?? "").isNotEmpty) {
        data = attendees
            .where((element) => element.name
                .toLowerCase()
                .contains((param ?? "").toLowerCase()))
            .toList();
      }

      return data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserCompetitor>> getAttendees() async {
    var res = await _db.collection("competitors").get();
    return res.docs.map((e) => UserCompetitor.fromJson(e.data())).toList();
  }

  @override
  Future<bool> searchUserInWorkShop(
      String uuid, UserCompetitor userCompetitor) async {
    try {
      var res = await _db
          .collection("schedule")
          .doc(uuid)
          .collection("workshow")
          .where("uuid", isEqualTo: userCompetitor.uuid)
          .get();
      // print("paso..");
      if (res.docs.isNotEmpty) {
        // print("paso..");
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

  @override
  Stream<UserCompetitor?> streamInfoUser(UserCompetitor userCompetitor) async* {
    var res = _db
        .collection("competitors")
        .doc(userCompetitor.uuid)
        .snapshots()
        .map((snapshot) =>
            snapshot.exists ? UserCompetitor.fromJson(snapshot.data()!) : null);
    yield* res;
  }

  @override
  Future<void> updateToken(String token) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      await _db
          .collection("competitors")
          .doc(uuid)
          .update({"tokenAuthorization": token});
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Future<bool> validateIsAdmin(String uuid) async {
    try {
      var res = await _db
          .collection("users-admin")
          .where('uuid', isEqualTo: uuid)
          .get();
      if (res.docs.isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print("Error querying admin information");
      }
      return false;
    }
  }
}
