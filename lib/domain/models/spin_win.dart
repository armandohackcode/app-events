import 'package:app_events/domain/models/spin_json_helpers.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';

/// Stand redemption lifecycle for a won GDG SPIN prize.
enum SpinWinStatus {
  pending('pending'),
  redeemed('redeemed'),
  revoked('revoked');

  final String value;
  const SpinWinStatus(this.value);

  static SpinWinStatus fromValue(String? text) {
    for (final status in values) {
      if (status.value == text) return status;
    }
    return SpinWinStatus.pending;
  }
}

/// Prize won by a player in GDG SPIN, matching backend `SpinWinDto`.
class SpinWin {
  final String id;
  final String eventId;
  final String uid;
  final String winnerName;
  final String winnerPhotoUrl;
  final String prizeId;
  final String prizeName;
  final SpinSymbol prizeSymbol;
  final String? prizeImageUrl;
  final PrizeRarity prizeRarity;
  final String code;
  final SpinWinStatus status;
  final String spinRequestId;
  final DateTime? wonAt;
  final DateTime? redeemedAt;
  final String? redeemedByUid;
  final String? redeemedByName;
  final DateTime? revokedAt;
  final String? revokedByUid;
  final String? revokeReason;
  final bool returnedToStock;

  const SpinWin({
    required this.id,
    required this.eventId,
    required this.uid,
    required this.prizeId,
    required this.prizeName,
    required this.prizeSymbol,
    required this.code,
    this.winnerName = '',
    this.winnerPhotoUrl = '',
    this.prizeImageUrl,
    this.prizeRarity = PrizeRarity.common,
    this.status = SpinWinStatus.pending,
    this.spinRequestId = '',
    this.wonAt,
    this.redeemedAt,
    this.redeemedByUid,
    this.redeemedByName,
    this.revokedAt,
    this.revokedByUid,
    this.revokeReason,
    this.returnedToStock = false,
  });

  /// QR payload scanned by staff at the prize booth.
  String get qrPayload => 'gdgspin:win:$eventId:$code';

  SpinWin copyWith({
    String? id,
    String? eventId,
    String? uid,
    String? winnerName,
    String? winnerPhotoUrl,
    String? prizeId,
    String? prizeName,
    SpinSymbol? prizeSymbol,
    String? prizeImageUrl,
    bool clearPrizeImageUrl = false,
    PrizeRarity? prizeRarity,
    String? code,
    SpinWinStatus? status,
    String? spinRequestId,
    DateTime? wonAt,
    bool clearWonAt = false,
    DateTime? redeemedAt,
    bool clearRedeemedAt = false,
    String? redeemedByUid,
    bool clearRedeemedByUid = false,
    String? redeemedByName,
    bool clearRedeemedByName = false,
    DateTime? revokedAt,
    bool clearRevokedAt = false,
    String? revokedByUid,
    bool clearRevokedByUid = false,
    String? revokeReason,
    bool clearRevokeReason = false,
    bool? returnedToStock,
  }) => SpinWin(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    uid: uid ?? this.uid,
    winnerName: winnerName ?? this.winnerName,
    winnerPhotoUrl: winnerPhotoUrl ?? this.winnerPhotoUrl,
    prizeId: prizeId ?? this.prizeId,
    prizeName: prizeName ?? this.prizeName,
    prizeSymbol: prizeSymbol ?? this.prizeSymbol,
    prizeImageUrl: clearPrizeImageUrl
        ? null
        : (prizeImageUrl ?? this.prizeImageUrl),
    prizeRarity: prizeRarity ?? this.prizeRarity,
    code: code ?? this.code,
    status: status ?? this.status,
    spinRequestId: spinRequestId ?? this.spinRequestId,
    wonAt: clearWonAt ? null : (wonAt ?? this.wonAt),
    redeemedAt: clearRedeemedAt ? null : (redeemedAt ?? this.redeemedAt),
    redeemedByUid: clearRedeemedByUid
        ? null
        : (redeemedByUid ?? this.redeemedByUid),
    redeemedByName: clearRedeemedByName
        ? null
        : (redeemedByName ?? this.redeemedByName),
    revokedAt: clearRevokedAt ? null : (revokedAt ?? this.revokedAt),
    revokedByUid: clearRevokedByUid
        ? null
        : (revokedByUid ?? this.revokedByUid),
    revokeReason: clearRevokeReason
        ? null
        : (revokeReason ?? this.revokeReason),
    returnedToStock: returnedToStock ?? this.returnedToStock,
  );

  factory SpinWin.fromJson(Map<String, dynamic> json) => SpinWin(
    id: parseString(json['id']),
    eventId: parseString(json['eventId']),
    uid: parseString(json['uid']),
    winnerName: parseString(json['winnerName']),
    winnerPhotoUrl: parseString(json['winnerPhotoUrl']),
    prizeId: parseString(json['prizeId']),
    prizeName: parseString(json['prizeName']),
    prizeSymbol: SpinSymbol.fromValue(json['prizeSymbol'] as String?),
    prizeImageUrl: parseNullableString(json['prizeImageUrl']),
    prizeRarity: PrizeRarity.fromValue(json['prizeRarity'] as String?),
    code: parseString(json['code']),
    status: SpinWinStatus.fromValue(json['status'] as String?),
    spinRequestId: parseString(json['spinRequestId']),
    wonAt: parseDateTime(json['wonAt']),
    redeemedAt: parseDateTime(json['redeemedAt']),
    redeemedByUid: parseNullableString(json['redeemedByUid']),
    redeemedByName: parseNullableString(json['redeemedByName']),
    revokedAt: parseDateTime(json['revokedAt']),
    revokedByUid: parseNullableString(json['revokedByUid']),
    revokeReason: parseNullableString(json['revokeReason']),
    returnedToStock: parseBool(json['returnedToStock']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'uid': uid,
    'winnerName': winnerName,
    'winnerPhotoUrl': winnerPhotoUrl,
    'prizeId': prizeId,
    'prizeName': prizeName,
    'prizeSymbol': prizeSymbol.value,
    'prizeImageUrl': prizeImageUrl,
    'prizeRarity': prizeRarity.value,
    'code': code,
    'status': status.value,
    'spinRequestId': spinRequestId,
    'wonAt': toIsoStringOrNull(wonAt),
    'redeemedAt': toIsoStringOrNull(redeemedAt),
    'redeemedByUid': redeemedByUid,
    'redeemedByName': redeemedByName,
    'revokedAt': toIsoStringOrNull(revokedAt),
    'revokedByUid': revokedByUid,
    'revokeReason': revokeReason,
    'returnedToStock': returnedToStock,
  };
}
