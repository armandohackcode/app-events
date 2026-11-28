import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_result.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';

/// Backend data contract for GDG SPIN streams, player callables, and admin
/// operations.
abstract interface class SpinDatasource {
  Stream<SpinConfig?> watchConfig(String eventId);

  Stream<List<SpinPrize>> watchPrizes(String eventId, {bool activeOnly = true});

  Stream<List<SpinMission>> watchMissions(
    String eventId, {
    bool activeOnly = true,
  });

  Stream<SpinPlayer?> watchPlayer(String eventId, String uid);

  Stream<List<SpinWin>> watchMyWins(String eventId, String uid);

  Stream<List<SpinMissionClaim>> watchMyMissionClaims(
    String eventId,
    String uid,
  );

  Stream<List<SpinWin>> watchAllWins(String eventId, {SpinWinStatus? status});

  Stream<List<SpinTicketCode>> watchTicketCodes(String eventId);

  Future<SpinInitPlayerResult> initPlayer(String eventId);

  Future<SpinPullResult> pull({
    required String eventId,
    required String spinRequestId,
  });

  Future<SpinClaimMissionResult> claimMission({
    required String eventId,
    required String missionId,
  });

  Future<SpinSubmitTriviaResult> submitTrivia({
    required String eventId,
    required String missionId,
    required int selectedIndex,
  });

  Future<SpinRedeemTicketCodeResult> redeemTicketCode({
    required String eventId,
    required String code,
  });

  Future<SpinConfig> updateConfig({
    required String eventId,
    required Map<String, dynamic> patch,
  });

  Future<AdminUpsertPrizeResult> upsertPrize({
    required String eventId,
    required Map<String, dynamic> prizeData,
    String? imagePath,
  });

  Future<SpinPrize> adjustPrizeStock({
    required String eventId,
    required String prizeId,
    required int delta,
    int? releasedDelta,
    required String reason,
  });

  Future<AdminUpsertMissionResult> upsertMission({
    required String eventId,
    required Map<String, dynamic> missionData,
    int? correctOptionIndex,
    String? explanation,
  });

  Future<AdminUpsertTicketCodeResult> upsertTicketCode({
    required String eventId,
    required Map<String, dynamic> codeData,
  });

  Future<AdminGrantTicketsResult> grantTickets({
    required String eventId,
    required String targetUid,
    required int amount,
    required String reason,
    required String requestId,
  });

  Future<AdminImportRegistrationsResult> importRegistrations({
    required String eventId,
    required List<SpinRegistrationRow> rows,
    bool replaceAll = false,
  });

  Future<AdminLookupWinResult> lookupWinByCode({
    required String eventId,
    required String codeOrQr,
  });

  Future<SpinWin> redeemWin({required String eventId, required String winId});

  Future<SpinWin> revokeWin({
    required String eventId,
    required String winId,
    required bool returnToStock,
    required String reason,
  });

  Future<SpinDashboardStats> getDashboard(String eventId);

  Future<String> uploadPrizeImage({
    required String eventId,
    required String prizeId,
    required String imagePath,
  });
}
