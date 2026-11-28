import 'package:app_events/domain/models/spin_json_helpers.dart';

/// Stand or sponsor QR ticket code campaign matching `SpinTicketCodeDto`.
class SpinTicketCode {
  final String id;
  final String code;
  final String label;
  final int rewardTickets;
  final int maxTotalUses;
  final int usedCount;
  final int maxUsesPerUser;
  final bool active;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;
  final String createdBy;

  const SpinTicketCode({
    required this.id,
    required this.code,
    required this.label,
    this.rewardTickets = 1,
    this.maxTotalUses = 1,
    this.usedCount = 0,
    this.maxUsesPerUser = 1,
    this.active = false,
    this.startsAt,
    this.endsAt,
    this.createdAt,
    this.createdBy = '',
  });

  /// QR payload displayed at stands and sponsors for attendees to scan.
  String qrPayload(String eventId) => 'gdgspin:code:$eventId:$code';

  SpinTicketCode copyWith({
    String? id,
    String? code,
    String? label,
    int? rewardTickets,
    int? maxTotalUses,
    int? usedCount,
    int? maxUsesPerUser,
    bool? active,
    DateTime? startsAt,
    bool clearStartsAt = false,
    DateTime? endsAt,
    bool clearEndsAt = false,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    String? createdBy,
  }) => SpinTicketCode(
    id: id ?? this.id,
    code: code ?? this.code,
    label: label ?? this.label,
    rewardTickets: rewardTickets ?? this.rewardTickets,
    maxTotalUses: maxTotalUses ?? this.maxTotalUses,
    usedCount: usedCount ?? this.usedCount,
    maxUsesPerUser: maxUsesPerUser ?? this.maxUsesPerUser,
    active: active ?? this.active,
    startsAt: clearStartsAt ? null : (startsAt ?? this.startsAt),
    endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
    createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
    createdBy: createdBy ?? this.createdBy,
  );

  factory SpinTicketCode.fromJson(Map<String, dynamic> json) => SpinTicketCode(
    id: parseString(json['id']),
    code: parseString(json['code']).toUpperCase(),
    label: parseString(json['label']),
    rewardTickets: parseInt(json['rewardTickets'], fallback: 1),
    maxTotalUses: parseInt(json['maxTotalUses'], fallback: 1),
    usedCount: parseInt(json['usedCount']),
    maxUsesPerUser: parseInt(json['maxUsesPerUser'], fallback: 1),
    active: parseBool(json['active']),
    startsAt: parseDateTime(json['startsAt']),
    endsAt: parseDateTime(json['endsAt']),
    createdAt: parseDateTime(json['createdAt']),
    createdBy: parseString(json['createdBy']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'label': label,
    'rewardTickets': rewardTickets,
    'maxTotalUses': maxTotalUses,
    'usedCount': usedCount,
    'maxUsesPerUser': maxUsesPerUser,
    'active': active,
    'startsAt': toIsoStringOrNull(startsAt),
    'endsAt': toIsoStringOrNull(endsAt),
    'createdAt': toIsoStringOrNull(createdAt),
    'createdBy': createdBy,
  };
}
