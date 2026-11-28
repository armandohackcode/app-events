import 'dart:io';

import 'package:app_events/data/datasources/firestore_normalizer.dart';
import 'package:app_events/domain/datasources/spin_datasource.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_json_helpers.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase implementation of [SpinDatasource] backed by Cloud Firestore streams,
/// Cloud Functions v2 callables, and Firebase Storage for prize artwork.
class FirebaseSpinDatasource implements SpinDatasource {
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  FirebaseSpinDatasource(this._db, this._functions, this._storage);

  DocumentReference<Map<String, dynamic>> _eventDoc(String eventId) =>
      _db.collection('events').doc(eventId);

  CollectionReference<Map<String, dynamic>> _prizesCol(String eventId) =>
      _eventDoc(eventId).collection('spinPrizes');

  CollectionReference<Map<String, dynamic>> _missionsCol(String eventId) =>
      _eventDoc(eventId).collection('spinMissions');

  CollectionReference<Map<String, dynamic>> _winsCol(String eventId) =>
      _eventDoc(eventId).collection('spinWins');

  Map<String, dynamic> _docDataWithFallbackId(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    String idKey = 'id',
  }) {
    final normalized = normalizeFirestoreMap(doc.data());
    final currentId = normalized[idKey];
    if (currentId is! String || currentId.isEmpty) {
      normalized[idKey] = doc.id;
    }
    return normalized;
  }

  @override
  Stream<SpinConfig?> watchConfig(String eventId) {
    return _eventDoc(
      eventId,
    ).collection('spinConfig').doc('main').snapshots().map((snapshot) {
      final raw = snapshot.data();
      if (!snapshot.exists || raw == null) return null;
      return SpinConfig.fromJson(normalizeFirestoreMap(raw));
    });
  }

  @override
  Stream<List<SpinPrize>> watchPrizes(
    String eventId, {
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _prizesCol(eventId);
    if (activeOnly) {
      query = query.where('active', isEqualTo: true);
    }
    return query.orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SpinPrize.fromJson(_docDataWithFallbackId(doc)))
          .toList(growable: false);
    });
  }

  @override
  Stream<List<SpinMission>> watchMissions(
    String eventId, {
    bool activeOnly = true,
  }) {
    Query<Map<String, dynamic>> query = _missionsCol(eventId);
    if (activeOnly) {
      query = query.where('active', isEqualTo: true);
    }
    return query.orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SpinMission.fromJson(_docDataWithFallbackId(doc)))
          .toList(growable: false);
    });
  }

  @override
  Stream<SpinPlayer?> watchPlayer(String eventId, String uid) {
    return _eventDoc(
      eventId,
    ).collection('spinPlayers').doc(uid).snapshots().map((snapshot) {
      final raw = snapshot.data();
      if (!snapshot.exists || raw == null) return null;
      final normalized = normalizeFirestoreMap(raw);
      final currentUid = normalized['uid'];
      if (currentUid is! String || currentUid.isEmpty) {
        normalized['uid'] = snapshot.id;
      }
      return SpinPlayer.fromJson(normalized);
    });
  }

  @override
  Stream<List<SpinWin>> watchMyWins(String eventId, String uid) {
    return _winsCol(eventId)
        .where('uid', isEqualTo: uid)
        .orderBy('wonAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SpinWin.fromJson(_docDataWithFallbackId(doc)))
              .toList(growable: false);
        });
  }

  @override
  Stream<List<SpinMissionClaim>> watchMyMissionClaims(
    String eventId,
    String uid,
  ) {
    return _eventDoc(eventId)
        .collection('spinMissionClaims')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => SpinMissionClaim.fromJson(
                  normalizeFirestoreMap(doc.data()),
                ),
              )
              .toList(growable: false);
        });
  }

  @override
  Stream<List<SpinWin>> watchAllWins(String eventId, {SpinWinStatus? status}) {
    Query<Map<String, dynamic>> query = _winsCol(eventId);
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }
    return query.orderBy('wonAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SpinWin.fromJson(_docDataWithFallbackId(doc)))
          .toList(growable: false);
    });
  }

  @override
  Stream<List<SpinTicketCode>> watchTicketCodes(String eventId) {
    return _eventDoc(eventId)
        .collection('spinTicketCodes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => SpinTicketCode.fromJson(_docDataWithFallbackId(doc)),
              )
              .toList(growable: false);
        });
  }

  @override
  Future<SpinInitPlayerResult> initPlayer(String eventId) async {
    final data = await callFunctionsMap(_functions, 'spinInitPlayer', {
      'eventId': eventId,
    });
    return SpinInitPlayerResult.fromJson(data);
  }

  @override
  Future<SpinPullResult> pull({
    required String eventId,
    required String spinRequestId,
  }) async {
    final data = await callFunctionsMap(_functions, 'spinPull', {
      'eventId': eventId,
      'spinRequestId': spinRequestId,
    });
    return SpinPullResult.fromJson(data);
  }

  @override
  Future<SpinClaimMissionResult> claimMission({
    required String eventId,
    required String missionId,
  }) async {
    final data = await callFunctionsMap(_functions, 'spinClaimMission', {
      'eventId': eventId,
      'missionId': missionId,
    });
    return SpinClaimMissionResult.fromJson(data);
  }

  @override
  Future<SpinSubmitTriviaResult> submitTrivia({
    required String eventId,
    required String missionId,
    required int selectedIndex,
  }) async {
    final data = await callFunctionsMap(_functions, 'spinSubmitTrivia', {
      'eventId': eventId,
      'missionId': missionId,
      'selectedIndex': selectedIndex,
    });
    return SpinSubmitTriviaResult.fromJson(data);
  }

  @override
  Future<SpinRedeemTicketCodeResult> redeemTicketCode({
    required String eventId,
    required String code,
  }) async {
    final data = await callFunctionsMap(_functions, 'spinRedeemTicketCode', {
      'eventId': eventId,
      'code': code,
    });
    return SpinRedeemTicketCodeResult.fromJson(data);
  }

  @override
  Future<SpinConfig> updateConfig({
    required String eventId,
    required Map<String, dynamic> patch,
  }) async {
    final data = await callFunctionsMap(_functions, 'adminUpdateSpinConfig', {
      'eventId': eventId,
      'patch': patch,
    });
    return SpinConfig.fromJson(parseDynamicMap(data['config']));
  }

  @override
  Future<AdminUpsertPrizeResult> upsertPrize({
    required String eventId,
    required Map<String, dynamic> prizeData,
    String? imagePath,
  }) async {
    final payload = Map<String, dynamic>.from(prizeData);
    final rawId = payload['id'];
    var prizeId = rawId is String && rawId.trim().isNotEmpty
        ? rawId.trim()
        : null;

    if (imagePath != null && imagePath.isNotEmpty) {
      prizeId ??= _prizesCol(eventId).doc().id;
      payload['id'] = prizeId;
      payload['imageUrl'] = await uploadPrizeImage(
        eventId: eventId,
        prizeId: prizeId,
        imagePath: imagePath,
      );
    } else if (prizeId == null) {
      payload.remove('id');
    }

    final data = await callFunctionsMap(_functions, 'adminUpsertSpinPrize', {
      'eventId': eventId,
      'prize': payload,
    });
    return AdminUpsertPrizeResult.fromJson(data);
  }

  @override
  Future<SpinPrize> adjustPrizeStock({
    required String eventId,
    required String prizeId,
    required int delta,
    int? releasedDelta,
    required String reason,
  }) async {
    final data = await callFunctionsMap(_functions, 'adminAdjustPrizeStock', {
      'eventId': eventId,
      'prizeId': prizeId,
      'delta': delta,
      'releasedDelta': ?releasedDelta,
      'reason': reason,
    });
    return SpinPrize.fromJson(parseDynamicMap(data['prize']));
  }

  @override
  Future<AdminUpsertMissionResult> upsertMission({
    required String eventId,
    required Map<String, dynamic> missionData,
    int? correctOptionIndex,
    String? explanation,
  }) async {
    final missionPayload = Map<String, dynamic>.from(missionData);
    final rawId = missionPayload['id'];
    if (rawId is! String || rawId.trim().isEmpty) {
      missionPayload.remove('id');
    }

    final data = await callFunctionsMap(_functions, 'adminUpsertSpinMission', {
      'eventId': eventId,
      'mission': missionPayload,
      if (correctOptionIndex != null)
        'secret': {
          'correctOptionIndex': correctOptionIndex,
          'explanation': ?explanation,
        },
    });
    return AdminUpsertMissionResult.fromJson(data);
  }

  @override
  Future<AdminUpsertTicketCodeResult> upsertTicketCode({
    required String eventId,
    required Map<String, dynamic> codeData,
  }) async {
    final codePayload = Map<String, dynamic>.from(codeData);
    final rawId = codePayload['id'];
    if (rawId is! String || rawId.trim().isEmpty) {
      codePayload.remove('id');
    }

    final data = await callFunctionsMap(_functions, 'adminUpsertTicketCode', {
      'eventId': eventId,
      'codeConfig': codePayload,
    });
    return AdminUpsertTicketCodeResult.fromJson(data);
  }

  @override
  Future<AdminGrantTicketsResult> grantTickets({
    required String eventId,
    required String targetUid,
    required int amount,
    required String reason,
    required String requestId,
  }) async {
    final data = await callFunctionsMap(_functions, 'adminGrantTickets', {
      'eventId': eventId,
      'targetUid': targetUid,
      'amount': amount,
      'reason': reason,
      'requestId': requestId,
    });
    return AdminGrantTicketsResult.fromJson(data);
  }

  @override
  Future<AdminImportRegistrationsResult> importRegistrations({
    required String eventId,
    required List<SpinRegistrationRow> rows,
    bool replaceAll = false,
  }) async {
    final data =
        await callFunctionsMap(_functions, 'adminImportRegistrations', {
          'eventId': eventId,
          'rows': rows.map((row) => row.toJson()).toList(growable: false),
          'replaceAll': replaceAll,
        });
    return AdminImportRegistrationsResult.fromJson(data);
  }

  @override
  Future<AdminLookupWinResult> lookupWinByCode({
    required String eventId,
    required String codeOrQr,
  }) async {
    final data = await callFunctionsMap(_functions, 'adminLookupWinByCode', {
      'eventId': eventId,
      'codeOrQr': codeOrQr,
    });
    return AdminLookupWinResult.fromJson(data);
  }

  @override
  Future<SpinWin> redeemWin({
    required String eventId,
    required String winId,
  }) async {
    final data = await callFunctionsMap(_functions, 'adminRedeemWin', {
      'eventId': eventId,
      'winId': winId,
    });
    return SpinWin.fromJson(parseDynamicMap(data['win']));
  }

  @override
  Future<SpinWin> revokeWin({
    required String eventId,
    required String winId,
    required bool returnToStock,
    required String reason,
  }) async {
    final data = await callFunctionsMap(_functions, 'adminRevokeWin', {
      'eventId': eventId,
      'winId': winId,
      'returnToStock': returnToStock,
      'reason': reason,
    });
    return SpinWin.fromJson(parseDynamicMap(data['win']));
  }

  @override
  Future<SpinDashboardStats> getDashboard(String eventId) async {
    final data = await callFunctionsMap(_functions, 'adminGetSpinDashboard', {
      'eventId': eventId,
    });
    return SpinDashboardStats.fromJson(data);
  }

  @override
  Future<String> uploadPrizeImage({
    required String eventId,
    required String prizeId,
    required String imagePath,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = _storage
        .ref()
        .child('events')
        .child(eventId)
        .child('spin-prizes')
        .child(prizeId)
        .child('$timestamp');
    await storageRef.putFile(File(imagePath));
    return storageRef.getDownloadURL();
  }
}
