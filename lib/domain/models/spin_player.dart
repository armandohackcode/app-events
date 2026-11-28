import 'package:app_events/domain/models/spin_json_helpers.dart';
import 'package:app_events/domain/models/spin_prize.dart';

/// Player wallet and anti-hoarding counters for a single event.
class SpinPlayer {
  static const Map<PrizeRarity, int> emptyWinsByRarity = {
    PrizeRarity.common: 0,
    PrizeRarity.rare: 0,
    PrizeRarity.epic: 0,
    PrizeRarity.legendary: 0,
  };

  final String uid;
  final String displayName;
  final String email;
  final int tickets;
  final int spinsCount;
  final int totalTicketsEarned;
  final int totalTicketsSpent;
  final int manualTicketsGranted;
  final int bonusWinsCount;
  final int totalPrizesWon;
  final Map<PrizeRarity, int> winsByRarity;
  final Map<String, int> winsByPrize;
  final bool initialTicketsGranted;
  final bool packageBonusGranted;
  final String? matchedPackage;
  final DateTime? lastSpinAt;
  final int? lastWinSpinNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SpinPlayer({
    this.uid = '',
    this.displayName = '',
    this.email = '',
    this.tickets = 0,
    this.spinsCount = 0,
    this.totalTicketsEarned = 0,
    this.totalTicketsSpent = 0,
    this.manualTicketsGranted = 0,
    this.bonusWinsCount = 0,
    this.totalPrizesWon = 0,
    this.winsByRarity = emptyWinsByRarity,
    this.winsByPrize = const {},
    this.initialTicketsGranted = false,
    this.packageBonusGranted = false,
    this.matchedPackage,
    this.lastSpinAt,
    this.lastWinSpinNumber,
    this.createdAt,
    this.updatedAt,
  });

  SpinPlayer copyWith({
    String? uid,
    String? displayName,
    String? email,
    int? tickets,
    int? spinsCount,
    int? totalTicketsEarned,
    int? totalTicketsSpent,
    int? manualTicketsGranted,
    int? bonusWinsCount,
    int? totalPrizesWon,
    Map<PrizeRarity, int>? winsByRarity,
    Map<String, int>? winsByPrize,
    bool? initialTicketsGranted,
    bool? packageBonusGranted,
    String? matchedPackage,
    bool clearMatchedPackage = false,
    DateTime? lastSpinAt,
    bool clearLastSpinAt = false,
    int? lastWinSpinNumber,
    bool clearLastWinSpinNumber = false,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) => SpinPlayer(
    uid: uid ?? this.uid,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    tickets: tickets ?? this.tickets,
    spinsCount: spinsCount ?? this.spinsCount,
    totalTicketsEarned: totalTicketsEarned ?? this.totalTicketsEarned,
    totalTicketsSpent: totalTicketsSpent ?? this.totalTicketsSpent,
    manualTicketsGranted: manualTicketsGranted ?? this.manualTicketsGranted,
    bonusWinsCount: bonusWinsCount ?? this.bonusWinsCount,
    totalPrizesWon: totalPrizesWon ?? this.totalPrizesWon,
    winsByRarity: winsByRarity ?? this.winsByRarity,
    winsByPrize: winsByPrize ?? this.winsByPrize,
    initialTicketsGranted: initialTicketsGranted ?? this.initialTicketsGranted,
    packageBonusGranted: packageBonusGranted ?? this.packageBonusGranted,
    matchedPackage: clearMatchedPackage
        ? null
        : (matchedPackage ?? this.matchedPackage),
    lastSpinAt: clearLastSpinAt ? null : (lastSpinAt ?? this.lastSpinAt),
    lastWinSpinNumber: clearLastWinSpinNumber
        ? null
        : (lastWinSpinNumber ?? this.lastWinSpinNumber),
    createdAt: clearCreatedAt ? null : (createdAt ?? this.createdAt),
    updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
  );

  factory SpinPlayer.fromJson(Map<String, dynamic> json) {
    final rawRarity = parseDynamicMap(json['winsByRarity']);
    final winsByRarity = {
      for (final rarity in PrizeRarity.values)
        rarity: parseInt(rawRarity[rarity.value]),
    };

    return SpinPlayer(
      uid: parseString(json['uid']),
      displayName: parseString(json['displayName']),
      email: parseString(json['email']),
      tickets: parseInt(json['tickets']),
      spinsCount: parseInt(json['spinsCount']),
      totalTicketsEarned: parseInt(json['totalTicketsEarned']),
      totalTicketsSpent: parseInt(json['totalTicketsSpent']),
      manualTicketsGranted: parseInt(json['manualTicketsGranted']),
      bonusWinsCount: parseInt(json['bonusWinsCount']),
      totalPrizesWon: parseInt(json['totalPrizesWon']),
      winsByRarity: winsByRarity,
      winsByPrize: parseStringIntMap(json['winsByPrize']),
      initialTicketsGranted: parseBool(json['initialTicketsGranted']),
      packageBonusGranted: parseBool(json['packageBonusGranted']),
      matchedPackage: parseNullableString(json['matchedPackage']),
      lastSpinAt: parseDateTime(json['lastSpinAt']),
      lastWinSpinNumber: parseNullableInt(json['lastWinSpinNumber']),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'tickets': tickets,
    'spinsCount': spinsCount,
    'totalTicketsEarned': totalTicketsEarned,
    'totalTicketsSpent': totalTicketsSpent,
    'manualTicketsGranted': manualTicketsGranted,
    'bonusWinsCount': bonusWinsCount,
    'totalPrizesWon': totalPrizesWon,
    'winsByRarity': {
      for (final rarity in PrizeRarity.values)
        rarity.value: winsByRarity[rarity] ?? 0,
    },
    'winsByPrize': Map<String, int>.from(winsByPrize),
    'initialTicketsGranted': initialTicketsGranted,
    'packageBonusGranted': packageBonusGranted,
    'matchedPackage': matchedPackage,
    'lastSpinAt': toIsoStringOrNull(lastSpinAt),
    'lastWinSpinNumber': lastWinSpinNumber,
    'createdAt': toIsoStringOrNull(createdAt),
    'updatedAt': toIsoStringOrNull(updatedAt),
  };
}
