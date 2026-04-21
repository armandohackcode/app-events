import 'package:app_events/domain/datasources/user_datasource.dart';
import 'package:app_events/domain/models/event_badge.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseUserDatasource implements UserDatasource {
  final FirebaseFirestore _db;
  FirebaseUserDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _competitors =>
      _db.collection('competitors');

  CollectionReference<Map<String, dynamic>> _workshopRef(
    String eventId,
    String speakerUuid,
  ) =>
      _db
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .collection('workshow');

  @override
  Future<UserCompetitor?> joinEvent(
    String eventId,
    UserCompetitor user,
  ) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      final existing = await getUserInfo(uuid);
      if (existing != null) {
        await _competitors.doc(uuid).update({'currentEventId': eventId});
        return existing.copyWith(currentEventId: eventId);
      } else {
        user = user.copyWith(uuid: uuid, currentEventId: eventId);
        await _competitors.doc(uuid).set(user.toJson());
        return user;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserCompetitor?> addNewFriend(
    String token,
    UserCompetitor userCompetitor,
  ) async {
    try {
      var friends = userCompetitor.friends;
      if (friends.where((e) => e.uuid == token).isNotEmpty ||
          token == userCompetitor.uuid) {
        return null;
      }
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      var res =
          await _competitors.where('uuid', isEqualTo: token).get();
      if (res.docs.isNotEmpty) {
        var user = UserCompetitor.fromJson(res.docs.first.data());
        friends.add(Friend(
          uuid: user.uuid,
          name: user.name,
          token: user.tokenAuthorization,
          photoUrl: user.photoUrl,
        ));
        await _competitors.doc(uuid).update({
          'score': FieldValue.increment(10),
          'friends': List<dynamic>.from(friends.map((x) => x.toJson())),
        });
        return user;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print(e);
      return null;
    }
  }

  @override
  Future<void> addScoreAdmin(String uuid) async {
    try {
      await _competitors.doc(uuid).update({
        'score': FieldValue.increment(10),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> addWorkshop(
    String eventId,
    String speakerUuid,
    UserCompetitor userCompetitor,
  ) async {
    try {
      await _db
          .collection('events')
          .doc(eventId)
          .collection('schedule')
          .doc(speakerUuid)
          .update({'current': FieldValue.increment(1)});
      await _workshopRef(eventId, speakerUuid).doc().set(
            Friend(
              uuid: userCompetitor.uuid,
              name: userCompetitor.name,
              token: userCompetitor.tokenAuthorization,
              photoUrl: userCompetitor.photoUrl,
            ).toJson(),
          );
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('addWorkshop failed: $e');
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
      if (res != null) return res;
      user = user.copyWith(uuid: uuid);
      await _competitors.doc(uuid).set(user.toJson());
      return user;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> editCompetitor(UserCompetitor user) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      await _competitors.doc(uuid).update(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserCompetitor?> getUserInfo(String uuid) async {
    try {
      var data =
          await _competitors.where('uuid', isEqualTo: uuid).get();
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
      var res = await _competitors.get();
      var attendees =
          res.docs.map((e) => UserCompetitor.fromJson(e.data())).toList();
      if ((param ?? "").isEmpty) return attendees;
      return attendees
          .where((e) =>
              e.name.toLowerCase().contains(param!.toLowerCase()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<UserCompetitor>> getAttendees() async {
    var res = await _competitors.get();
    return res.docs.map((e) => UserCompetitor.fromJson(e.data())).toList();
  }

  @override
  Future<bool> searchUserInWorkShop(
    String eventId,
    String speakerUuid,
    UserCompetitor userCompetitor,
  ) async {
    try {
      var res = await _workshopRef(eventId, speakerUuid)
          .where('uuid', isEqualTo: userCompetitor.uuid)
          .get();
      return res.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }

  @override
  Stream<UserCompetitor?> streamInfoUser(UserCompetitor userCompetitor) {
    return _competitors.doc(userCompetitor.uuid).snapshots().map(
          (snapshot) => snapshot.exists
              ? UserCompetitor.fromJson(snapshot.data()!)
              : null,
        );
  }

  @override
  Future<void> updateToken(String token) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      await _competitors.doc(uuid).update({'tokenAuthorization': token});
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  @override
  Future<bool> validateIsAdmin(String uuid) async {
    try {
      var res = await _db
          .collection('users-admin')
          .where('uuid', isEqualTo: uuid)
          .get();
      return res.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print(e);
        print('Error querying admin information');
      }
      return false;
    }
  }

  @override
  Future<UserCompetitor?> addItemTreasure(UserCompetitor userCompetitor) async {
    try {
      var storage = await SharedPreferences.getInstance();
      var uuid = storage.getString('uid_user') ?? "";
      var treasures = userCompetitor.treasures;
      await _competitors.doc(uuid).update({
        'treasures': List<dynamic>.from(treasures.map((x) => x)),
        'score': FieldValue.increment(100),
      });
      return userCompetitor.copyWith(treasures: treasures);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> awardBadge(String competitorUuid, EventBadge badge) async {
    try {
      await _competitors.doc(competitorUuid).update({
        'badges': FieldValue.arrayUnion([badge.toJson()]),
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetAllCompetitors() async {
    try {
      final batch = _db.batch();
      final docs = await _competitors.get();
      for (final doc in docs.docs) {
        batch.update(doc.reference, {
          'score': 0,
          'friends': [],
          'treasures': [],
          'scoreProfile': false,
          'currentEventId': null,
        });
      }
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}
