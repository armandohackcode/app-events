import 'package:app_events/domain/models/spin_json_helpers.dart';
import 'package:app_events/domain/models/spin_mission.dart';
import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/domain/models/spin_ticket_code.dart';
import 'package:app_events/domain/models/spin_win.dart';

/// Server outcome classification for a spin pull.
enum SpinOutcomeType {
  prize,
  bonus,
  lose;

  String get value => name;

  static SpinOutcomeType fromValue(String? text) {
    for (final type in values) {
      if (type.name == text) return type;
    }
    return SpinOutcomeType.lose;
  }
}

/// Typed error reasons matching all 24 backend `SpinErrorReason` codes plus
/// Firebase client/network fallbacks.
enum SpinErrorReason {
  gamePaused('GAME_PAUSED'),
  gameClosed('GAME_CLOSED'),
  insufficientTickets('INSUFFICIENT_TICKETS'),
  cooldownActive('COOLDOWN_ACTIVE'),
  prizeCapReached('PRIZE_CAP_REACHED'),
  playerNotInitialized('PLAYER_NOT_INITIALIZED'),
  configNotFound('CONFIG_NOT_FOUND'),
  requirementNotMet('REQUIREMENT_NOT_MET'),
  ticketCapReached('TICKET_CAP_REACHED'),
  triviaClosed('TRIVIA_CLOSED'),
  missionInactive('MISSION_INACTIVE'),
  codeDepleted('CODE_DEPLETED'),
  codeExpired('CODE_EXPIRED'),
  codeAlreadyExists('CODE_ALREADY_EXISTS'),
  rateLimited('RATE_LIMITED'),
  questionLimitReached('QUESTION_LIMIT_REACHED'),
  alreadyRedeemed('ALREADY_REDEEMED'),
  alreadyRevoked('ALREADY_REVOKED'),
  invalidStockAdjustment('INVALID_STOCK_ADJUSTMENT'),
  stockImmutableOnUpdate('STOCK_IMMUTABLE_ON_UPDATE'),
  manualGrantCapReached('MANUAL_GRANT_CAP_REACHED'),
  eventMismatch('EVENT_MISMATCH'),
  invalidCodeFormat('INVALID_CODE_FORMAT'),
  invalidSecret('INVALID_SECRET'),
  unknown('UNKNOWN'),
  network('NETWORK'),
  unauthenticated('UNAUTHENTICATED'),
  permissionDenied('PERMISSION_DENIED'),
  alreadyExists('ALREADY_EXISTS'),
  notFound('NOT_FOUND');

  final String value;
  const SpinErrorReason(this.value);

  static SpinErrorReason fromValue(String? text) {
    final normalized = text?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return SpinErrorReason.unknown;
    }
    for (final reason in values) {
      if (reason.value == normalized) return reason;
    }
    return SpinErrorReason.unknown;
  }
}

/// Domain exception produced by mapping Cloud Functions callable errors.
class SpinException implements Exception {
  final SpinErrorReason reason;
  final String code;
  final String message;

  const SpinException({
    required this.reason,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'SpinException($code, ${reason.value}): $message';
}

/// Visual/domain outcome shown by the slot machine celebration layer.
sealed class SpinOutcome {
  const SpinOutcome();
}

class SpinPrizeOutcome extends SpinOutcome {
  final SpinPrize prize;
  const SpinPrizeOutcome(this.prize);
}

class SpinBonusOutcome extends SpinOutcome {
  final int tickets;
  const SpinBonusOutcome(this.tickets);
}

/// Won prize summary embedded inside `SpinPullResponseDto`.
class SpinPullWonPrize {
  final String winId;
  final String prizeId;
  final String name;
  final SpinSymbol symbol;
  final String? imageUrl;
  final PrizeRarity rarity;
  final String code;
  final DateTime? wonAt;

  const SpinPullWonPrize({
    required this.winId,
    required this.prizeId,
    required this.name,
    required this.symbol,
    required this.rarity,
    required this.code,
    this.imageUrl,
    this.wonAt,
  });

  factory SpinPullWonPrize.fromJson(Map<String, dynamic> json) =>
      SpinPullWonPrize(
        winId: parseString(json['winId']),
        prizeId: parseString(json['prizeId']),
        name: parseString(json['name']),
        symbol: SpinSymbol.fromValue(json['symbol'] as String?),
        imageUrl: parseNullableString(json['imageUrl']),
        rarity: PrizeRarity.fromValue(json['rarity'] as String?),
        code: parseString(json['code']),
        wonAt: parseDateTime(json['wonAt']),
      );

  Map<String, dynamic> toJson() => {
    'winId': winId,
    'prizeId': prizeId,
    'name': name,
    'symbol': symbol.value,
    'imageUrl': imageUrl,
    'rarity': rarity.value,
    'code': code,
    'wonAt': toIsoStringOrNull(wonAt),
  };
}

/// Result returned by `spinPull`.
class SpinPullResult {
  final String spinRequestId;
  final SpinOutcomeType outcomeType;
  final List<SpinSymbol> combo;
  final SpinPullWonPrize? wonPrize;
  final int bonusTickets;
  final int ticketsAfter;
  final int spinsCountAfter;
  final bool reachedPrizeCap;
  final String? ticketSerial;

  const SpinPullResult({
    required this.spinRequestId,
    required this.outcomeType,
    required this.combo,
    this.wonPrize,
    this.bonusTickets = 0,
    this.ticketsAfter = 0,
    this.spinsCountAfter = 0,
    this.reachedPrizeCap = false,
    this.ticketSerial,
  });

  factory SpinPullResult.fromJson(Map<String, dynamic> json) {
    final rawCombo = json['combo'];
    final combo = rawCombo is List
        ? rawCombo
              .map((item) => SpinSymbol.fromValue(item as String?))
              .toList(growable: false)
        : const <SpinSymbol>[];
    final rawWonPrize = json['wonPrize'];
    return SpinPullResult(
      spinRequestId: parseString(json['spinRequestId']),
      outcomeType: SpinOutcomeType.fromValue(json['outcomeType'] as String?),
      combo: combo,
      wonPrize: rawWonPrize is Map
          ? SpinPullWonPrize.fromJson(parseDynamicMap(rawWonPrize))
          : null,
      bonusTickets: parseInt(json['bonusTickets']),
      ticketsAfter: parseInt(json['ticketsAfter']),
      spinsCountAfter: parseInt(json['spinsCountAfter']),
      reachedPrizeCap: parseBool(json['reachedPrizeCap']),
      ticketSerial: parseNullableString(json['ticketSerial']),
    );
  }

  Map<String, dynamic> toJson() => {
    'spinRequestId': spinRequestId,
    'outcomeType': outcomeType.value,
    'combo': combo.map((symbol) => symbol.value).toList(),
    'wonPrize': wonPrize?.toJson(),
    'bonusTickets': bonusTickets,
    'ticketsAfter': ticketsAfter,
    'spinsCountAfter': spinsCountAfter,
    'reachedPrizeCap': reachedPrizeCap,
    'ticketSerial': ticketSerial,
  };
}

/// Result returned by `spinInitPlayer`.
class SpinInitPlayerResult {
  final SpinPlayer player;
  final bool initialGranted;
  final bool packageBonusGranted;
  final String? matchedPackage;

  const SpinInitPlayerResult({
    required this.player,
    this.initialGranted = false,
    this.packageBonusGranted = false,
    this.matchedPackage,
  });

  factory SpinInitPlayerResult.fromJson(Map<String, dynamic> json) =>
      SpinInitPlayerResult(
        player: SpinPlayer.fromJson(parseDynamicMap(json['player'])),
        initialGranted: parseBool(json['initialGranted']),
        packageBonusGranted: parseBool(json['packageBonusGranted']),
        matchedPackage: parseNullableString(json['matchedPackage']),
      );

  Map<String, dynamic> toJson() => {
    'player': player.toJson(),
    'initialGranted': initialGranted,
    'packageBonusGranted': packageBonusGranted,
    'matchedPackage': matchedPackage,
  };
}

/// Result returned by `spinClaimMission`.
class SpinClaimMissionResult {
  final bool granted;
  final int ticketsAwarded;
  final int ticketsAfter;
  final String ticketSerial;

  const SpinClaimMissionResult({
    this.granted = false,
    this.ticketsAwarded = 0,
    this.ticketsAfter = 0,
    this.ticketSerial = '',
  });

  factory SpinClaimMissionResult.fromJson(Map<String, dynamic> json) =>
      SpinClaimMissionResult(
        granted: parseBool(json['granted']),
        ticketsAwarded: parseInt(json['ticketsAwarded']),
        ticketsAfter: parseInt(json['ticketsAfter']),
        ticketSerial: parseString(json['ticketSerial']),
      );

  Map<String, dynamic> toJson() => {
    'granted': granted,
    'ticketsAwarded': ticketsAwarded,
    'ticketsAfter': ticketsAfter,
    'ticketSerial': ticketSerial,
  };
}

/// Result returned by `spinSubmitTrivia`.
class SpinSubmitTriviaResult {
  final bool correct;
  final String explanation;
  final int ticketsAwarded;
  final int ticketsAfter;
  final String? ticketSerial;

  const SpinSubmitTriviaResult({
    this.correct = false,
    this.explanation = '',
    this.ticketsAwarded = 0,
    this.ticketsAfter = 0,
    this.ticketSerial,
  });

  factory SpinSubmitTriviaResult.fromJson(Map<String, dynamic> json) =>
      SpinSubmitTriviaResult(
        correct: parseBool(json['correct']),
        explanation: parseString(json['explanation']),
        ticketsAwarded: parseInt(json['ticketsAwarded']),
        ticketsAfter: parseInt(json['ticketsAfter']),
        ticketSerial: parseNullableString(json['ticketSerial']),
      );

  Map<String, dynamic> toJson() => {
    'correct': correct,
    'explanation': explanation,
    'ticketsAwarded': ticketsAwarded,
    'ticketsAfter': ticketsAfter,
    'ticketSerial': ticketSerial,
  };
}

/// Result returned by `spinRedeemTicketCode`.
class SpinRedeemTicketCodeResult {
  final String label;
  final int ticketsAwarded;
  final int ticketsAfter;
  final String ticketSerial;

  const SpinRedeemTicketCodeResult({
    this.label = '',
    this.ticketsAwarded = 0,
    this.ticketsAfter = 0,
    this.ticketSerial = '',
  });

  factory SpinRedeemTicketCodeResult.fromJson(Map<String, dynamic> json) =>
      SpinRedeemTicketCodeResult(
        label: parseString(json['label']),
        ticketsAwarded: parseInt(json['ticketsAwarded']),
        ticketsAfter: parseInt(json['ticketsAfter']),
        ticketSerial: parseString(json['ticketSerial']),
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    'ticketsAwarded': ticketsAwarded,
    'ticketsAfter': ticketsAfter,
    'ticketSerial': ticketSerial,
  };
}

/// Player claim progress stored in `spinMissionClaims/{uid}_{missionId}`.
class SpinMissionClaim {
  final String uid;
  final String missionId;
  final int completions;
  final List<String> countedTalkIds;
  final DateTime? claimedAt;

  const SpinMissionClaim({
    required this.uid,
    required this.missionId,
    this.completions = 0,
    this.countedTalkIds = const [],
    this.claimedAt,
  });

  factory SpinMissionClaim.fromJson(Map<String, dynamic> json) =>
      SpinMissionClaim(
        uid: parseString(json['uid']),
        missionId: parseString(json['missionId']),
        completions: parseInt(json['completions']),
        countedTalkIds: parseStringList(json['countedTalkIds']),
        claimedAt: parseDateTime(json['claimedAt'] ?? json['lastClaimedAt']),
      );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'missionId': missionId,
    'completions': completions,
    'countedTalkIds': countedTalkIds,
    'claimedAt': toIsoStringOrNull(claimedAt),
  };
}

/// Row payload sent to `adminImportRegistrations`.
class SpinRegistrationRow {
  final String email;
  final String fullName;
  final String package;
  final bool checkedIn;

  const SpinRegistrationRow({
    required this.email,
    required this.package,
    this.fullName = '',
    this.checkedIn = false,
  });

  factory SpinRegistrationRow.fromJson(Map<String, dynamic> json) =>
      SpinRegistrationRow(
        email: parseString(json['email']),
        fullName: parseString(json['fullName']),
        package: parseString(json['package']),
        checkedIn: parseBool(json['checkedIn']),
      );

  Map<String, dynamic> toJson() => {
    'email': email,
    'fullName': fullName,
    'package': package,
    'checkedIn': checkedIn,
  };
}

/// Result returned by `adminImportRegistrations`.
class AdminImportRegistrationsResult {
  final int importedCount;
  final int updatedCount;
  final int totalRegistrationsCount;

  const AdminImportRegistrationsResult({
    this.importedCount = 0,
    this.updatedCount = 0,
    this.totalRegistrationsCount = 0,
  });

  factory AdminImportRegistrationsResult.fromJson(Map<String, dynamic> json) =>
      AdminImportRegistrationsResult(
        importedCount: parseInt(json['importedCount']),
        updatedCount: parseInt(json['updatedCount']),
        totalRegistrationsCount: parseInt(json['totalRegistrationsCount']),
      );

  Map<String, dynamic> toJson() => {
    'importedCount': importedCount,
    'updatedCount': updatedCount,
    'totalRegistrationsCount': totalRegistrationsCount,
  };
}

/// Result returned by `adminGrantTickets`.
class AdminGrantTicketsResult {
  final String targetUid;
  final int ticketsAwarded;
  final int ticketsAfter;
  final String ticketSerial;
  final bool idempotentReplay;

  const AdminGrantTicketsResult({
    this.targetUid = '',
    this.ticketsAwarded = 0,
    this.ticketsAfter = 0,
    this.ticketSerial = '',
    this.idempotentReplay = false,
  });

  factory AdminGrantTicketsResult.fromJson(Map<String, dynamic> json) =>
      AdminGrantTicketsResult(
        targetUid: parseString(json['targetUid']),
        ticketsAwarded: parseInt(json['ticketsAwarded']),
        ticketsAfter: parseInt(json['ticketsAfter']),
        ticketSerial: parseString(json['ticketSerial']),
        idempotentReplay: parseBool(json['idempotentReplay']),
      );

  Map<String, dynamic> toJson() => {
    'targetUid': targetUid,
    'ticketsAwarded': ticketsAwarded,
    'ticketsAfter': ticketsAfter,
    'ticketSerial': ticketSerial,
    'idempotentReplay': idempotentReplay,
  };
}

/// Result returned by `adminLookupWinByCode`.
class AdminLookupWinResult {
  final SpinWin win;
  final SpinPrize? prize;
  final SpinPlayer? player;

  const AdminLookupWinResult({required this.win, this.prize, this.player});

  factory AdminLookupWinResult.fromJson(Map<String, dynamic> json) {
    final rawPrize = json['prize'];
    final rawPlayer = json['player'];
    return AdminLookupWinResult(
      win: SpinWin.fromJson(parseDynamicMap(json['win'])),
      prize: rawPrize is Map
          ? SpinPrize.fromJson(parseDynamicMap(rawPrize))
          : null,
      player: rawPlayer is Map
          ? SpinPlayer.fromJson(parseDynamicMap(rawPlayer))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'win': win.toJson(),
    'prize': prize?.toJson(),
    'player': player?.toJson(),
  };
}

/// Result returned by `adminUpsertSpinPrize`.
class AdminUpsertPrizeResult {
  final SpinPrize prize;
  final bool created;

  const AdminUpsertPrizeResult({required this.prize, this.created = false});

  factory AdminUpsertPrizeResult.fromJson(Map<String, dynamic> json) =>
      AdminUpsertPrizeResult(
        prize: SpinPrize.fromJson(parseDynamicMap(json['prize'])),
        created: parseBool(json['created']),
      );

  Map<String, dynamic> toJson() => {
    'prize': prize.toJson(),
    'created': created,
  };
}

/// Result returned by `adminUpsertSpinMission`.
class AdminUpsertMissionResult {
  final SpinMission mission;
  final bool created;

  const AdminUpsertMissionResult({required this.mission, this.created = false});

  factory AdminUpsertMissionResult.fromJson(Map<String, dynamic> json) =>
      AdminUpsertMissionResult(
        mission: SpinMission.fromJson(parseDynamicMap(json['mission'])),
        created: parseBool(json['created']),
      );

  Map<String, dynamic> toJson() => {
    'mission': mission.toJson(),
    'created': created,
  };
}

/// Result returned by `adminUpsertTicketCode`.
class AdminUpsertTicketCodeResult {
  final SpinTicketCode ticketCode;
  final bool created;

  const AdminUpsertTicketCodeResult({
    required this.ticketCode,
    this.created = false,
  });

  factory AdminUpsertTicketCodeResult.fromJson(Map<String, dynamic> json) =>
      AdminUpsertTicketCodeResult(
        ticketCode: SpinTicketCode.fromJson(
          parseDynamicMap(json['ticketCode']),
        ),
        created: parseBool(json['created']),
      );

  Map<String, dynamic> toJson() => {
    'ticketCode': ticketCode.toJson(),
    'created': created,
  };
}
