import 'package:app_events/domain/datasources/spin_datasource.dart';
import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';
import 'package:app_events/domain/repositories/spin_repository.dart';

class SpinRepositoryImpl implements SpinRepository {
  final SpinDatasource _datasource;

  SpinRepositoryImpl(this._datasource);

  @override
  Stream<SpinConfig?> watchConfig(String eventId) =>
      _datasource.watchConfig(eventId);

  @override
  Stream<List<SpinPrize>> watchPrizes(
    String eventId, {
    bool activeOnly = true,
  }) => _datasource.watchPrizes(eventId, activeOnly: activeOnly);

  @override
  Stream<List<SpinMission>> watchMissions(
    String eventId, {
    bool activeOnly = true,
  }) => _datasource.watchMissions(eventId, activeOnly: activeOnly);

  @override
  Stream<SpinPlayer?> watchPlayer(String eventId, String uid) =>
      _datasource.watchPlayer(eventId, uid);

  @override
  Stream<List<SpinWin>> watchMyWins(String eventId, String uid) =>
      _datasource.watchMyWins(eventId, uid);

  @override
  Stream<List<SpinMissionClaim>> watchMyMissionClaims(
    String eventId,
    String uid,
  ) => _datasource.watchMyMissionClaims(eventId, uid);

  @override
  Stream<List<SpinWin>> watchAllWins(String eventId, {SpinWinStatus? status}) =>
      _datasource.watchAllWins(eventId, status: status);

  @override
  Stream<List<SpinTicketCode>> watchTicketCodes(String eventId) =>
      _datasource.watchTicketCodes(eventId);

  @override
  Future<SpinInitPlayerResult> initPlayer(String eventId) =>
      _datasource.initPlayer(eventId);

  @override
  Future<SpinPullResult> pull({
    required String eventId,
    required String spinRequestId,
  }) => _datasource.pull(eventId: eventId, spinRequestId: spinRequestId);

  @override
  Future<SpinClaimMissionResult> claimMission({
    required String eventId,
    required String missionId,
  }) => _datasource.claimMission(eventId: eventId, missionId: missionId);

  @override
  Future<SpinSubmitTriviaResult> submitTrivia({
    required String eventId,
    required String missionId,
    required int selectedIndex,
  }) => _datasource.submitTrivia(
    eventId: eventId,
    missionId: missionId,
    selectedIndex: selectedIndex,
  );

  @override
  Future<SpinRedeemTicketCodeResult> redeemTicketCode({
    required String eventId,
    required String code,
  }) => _datasource.redeemTicketCode(eventId: eventId, code: code);

  @override
  Future<SpinConfig> updateConfig({
    required String eventId,
    required Map<String, dynamic> patch,
  }) => _datasource.updateConfig(eventId: eventId, patch: patch);

  @override
  Future<AdminUpsertPrizeResult> upsertPrize({
    required String eventId,
    required Map<String, dynamic> prizeData,
    String? imagePath,
  }) => _datasource.upsertPrize(
    eventId: eventId,
    prizeData: prizeData,
    imagePath: imagePath,
  );

  @override
  Future<SpinPrize> adjustPrizeStock({
    required String eventId,
    required String prizeId,
    required int delta,
    int? releasedDelta,
    required String reason,
  }) => _datasource.adjustPrizeStock(
    eventId: eventId,
    prizeId: prizeId,
    delta: delta,
    releasedDelta: releasedDelta,
    reason: reason,
  );

  @override
  Future<AdminUpsertMissionResult> upsertMission({
    required String eventId,
    required Map<String, dynamic> missionData,
    int? correctOptionIndex,
    String? explanation,
  }) => _datasource.upsertMission(
    eventId: eventId,
    missionData: missionData,
    correctOptionIndex: correctOptionIndex,
    explanation: explanation,
  );

  @override
  Future<AdminUpsertTicketCodeResult> upsertTicketCode({
    required String eventId,
    required Map<String, dynamic> codeData,
  }) => _datasource.upsertTicketCode(eventId: eventId, codeData: codeData);

  @override
  Future<AdminGrantTicketsResult> grantTickets({
    required String eventId,
    required String targetUid,
    required int amount,
    required String reason,
    required String requestId,
  }) => _datasource.grantTickets(
    eventId: eventId,
    targetUid: targetUid,
    amount: amount,
    reason: reason,
    requestId: requestId,
  );

  @override
  Future<AdminImportRegistrationsResult> importRegistrations({
    required String eventId,
    required List<SpinRegistrationRow> rows,
    bool replaceAll = false,
  }) => _datasource.importRegistrations(
    eventId: eventId,
    rows: rows,
    replaceAll: replaceAll,
  );

  @override
  Future<AdminLookupWinResult> lookupWinByCode({
    required String eventId,
    required String codeOrQr,
  }) => _datasource.lookupWinByCode(eventId: eventId, codeOrQr: codeOrQr);

  @override
  Future<SpinWin> redeemWin({required String eventId, required String winId}) =>
      _datasource.redeemWin(eventId: eventId, winId: winId);

  @override
  Future<SpinWin> revokeWin({
    required String eventId,
    required String winId,
    required bool returnToStock,
    required String reason,
  }) => _datasource.revokeWin(
    eventId: eventId,
    winId: winId,
    returnToStock: returnToStock,
    reason: reason,
  );

  @override
  Future<SpinDashboardStats> getDashboard(String eventId) =>
      _datasource.getDashboard(eventId);

  @override
  Future<String> uploadPrizeImage({
    required String eventId,
    required String prizeId,
    required String imagePath,
  }) => _datasource.uploadPrizeImage(
    eventId: eventId,
    prizeId: prizeId,
    imagePath: imagePath,
  );
}
