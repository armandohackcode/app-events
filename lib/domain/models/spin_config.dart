import 'dart:math';

import 'package:app_events/domain/models/spin_json_helpers.dart';
import 'package:app_events/domain/models/spin_prize.dart';

/// Operational status of GDG SPIN for an event.
enum SpinGameStatus {
  paused('paused'),
  active('active'),
  closed('closed');

  final String value;
  const SpinGameStatus(this.value);

  static SpinGameStatus fromValue(String? text) {
    for (final status in values) {
      if (status.value == text) return status;
    }
    return SpinGameStatus.paused;
  }
}

/// Pacing strategy controlling how prize stock unlocks across the event.
enum SpinPacingMode {
  timePaced('time_paced'),
  dynamicSpins('dynamic_spins'),
  manualWaves('manual_waves');

  final String value;
  const SpinPacingMode(this.value);

  static SpinPacingMode fromValue(String? text) {
    for (final mode in values) {
      if (mode.value == text) return mode;
    }
    return SpinPacingMode.timePaced;
  }
}

/// Scheduled release wave for time-paced prize distribution.
class SpinPacingWave {
  final String id;
  final String label;
  final DateTime startAt;
  final double releaseRatio;
  final double spinBudgetShare;

  const SpinPacingWave({
    required this.id,
    required this.label,
    required this.startAt,
    required this.releaseRatio,
    required this.spinBudgetShare,
  });

  SpinPacingWave copyWith({
    String? id,
    String? label,
    DateTime? startAt,
    double? releaseRatio,
    double? spinBudgetShare,
  }) => SpinPacingWave(
    id: id ?? this.id,
    label: label ?? this.label,
    startAt: startAt ?? this.startAt,
    releaseRatio: releaseRatio ?? this.releaseRatio,
    spinBudgetShare: spinBudgetShare ?? this.spinBudgetShare,
  );

  factory SpinPacingWave.fromJson(Map<String, dynamic> json) => SpinPacingWave(
    id: parseString(json['id']),
    label: parseString(json['label']),
    startAt:
        parseDateTime(json['startAt'] ?? json['startAtMs']) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    releaseRatio: parseDouble(json['releaseRatio'], fallback: 1.0),
    spinBudgetShare: parseDouble(json['spinBudgetShare']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'startAt': startAt.toUtc().toIso8601String(),
    'releaseRatio': releaseRatio,
    'spinBudgetShare': spinBudgetShare,
  };
}

/// Event-scoped GDG SPIN configuration matching backend `SpinConfigDto`.
class SpinConfig {
  static const Map<PrizeRarity, int> defaultMaxWinsByRarity = {
    PrizeRarity.common: 2,
    PrizeRarity.rare: 1,
    PrizeRarity.epic: 1,
    PrizeRarity.legendary: 1,
  };

  final SpinGameStatus status;
  final String pauseMessage;
  final int ticketCostPerSpin;
  final int defaultInitialTickets;
  final Map<String, int> packageTicketBonus;
  final bool matchRegistrationByEmail;
  final int registeredAttendeesCount;
  final double expectedSpinsPerAttendee;
  final int? estimatedTotalSpinsOverride;
  final SpinPacingMode pacingMode;
  final DateTime? pacingStartAt;
  final DateTime? pacingEndAt;
  final double pacingCurveGamma;
  final List<SpinPacingWave> pacingWaves;
  final bool rushMode;
  final bool rushBypassUnlockAt;
  final double payoutMultiplier;
  final double maxWinProbabilityPerSpin;
  final double rushMaxWinProbabilityPerSpin;
  final int maxPrizesPerUser;
  final bool allowPlayAfterCap;
  final Map<PrizeRarity, int> maxWinsByRarity;
  final int minSpinsBetweenWins;
  final double bonusProbability;
  final int bonusMinTickets;
  final int bonusMaxTickets;
  final int maxBonusWinsPerUser;
  final double wildReplacementChance;
  final int spinCooldownMs;
  final int maxTotalEarnedTicketsPerUser;
  final int maxManualGrantPerAction;
  final int maxManualTicketsPerUser;
  final DateTime? updatedAt;
  final String updatedBy;

  const SpinConfig({
    this.status = SpinGameStatus.paused,
    this.pauseMessage = '',
    this.ticketCostPerSpin = 1,
    this.defaultInitialTickets = 2,
    this.packageTicketBonus = const {},
    this.matchRegistrationByEmail = true,
    this.registeredAttendeesCount = 0,
    this.expectedSpinsPerAttendee = 4.0,
    this.estimatedTotalSpinsOverride,
    this.pacingMode = SpinPacingMode.timePaced,
    this.pacingStartAt,
    this.pacingEndAt,
    this.pacingCurveGamma = 1.0,
    this.pacingWaves = const [],
    this.rushMode = false,
    this.rushBypassUnlockAt = true,
    this.payoutMultiplier = 1.0,
    this.maxWinProbabilityPerSpin = 0.45,
    this.rushMaxWinProbabilityPerSpin = 0.85,
    this.maxPrizesPerUser = 3,
    this.allowPlayAfterCap = false,
    this.maxWinsByRarity = defaultMaxWinsByRarity,
    this.minSpinsBetweenWins = 1,
    this.bonusProbability = 0.06,
    this.bonusMinTickets = 1,
    this.bonusMaxTickets = 3,
    this.maxBonusWinsPerUser = 2,
    this.wildReplacementChance = 0.35,
    this.spinCooldownMs = 2500,
    this.maxTotalEarnedTicketsPerUser = 15,
    this.maxManualGrantPerAction = 5,
    this.maxManualTicketsPerUser = 10,
    this.updatedAt,
    this.updatedBy = '',
  });

  /// Effective total estimated spins across the event.
  int get effectiveEstimatedTotalSpins {
    final override = estimatedTotalSpinsOverride;
    if (override != null) {
      return max(1, override);
    }
    return max(
      1,
      (registeredAttendeesCount * expectedSpinsPerAttendee).round(),
    );
  }

  SpinConfig copyWith({
    SpinGameStatus? status,
    String? pauseMessage,
    int? ticketCostPerSpin,
    int? defaultInitialTickets,
    Map<String, int>? packageTicketBonus,
    bool? matchRegistrationByEmail,
    int? registeredAttendeesCount,
    double? expectedSpinsPerAttendee,
    int? estimatedTotalSpinsOverride,
    bool clearEstimatedTotalSpinsOverride = false,
    SpinPacingMode? pacingMode,
    DateTime? pacingStartAt,
    bool clearPacingStartAt = false,
    DateTime? pacingEndAt,
    bool clearPacingEndAt = false,
    double? pacingCurveGamma,
    List<SpinPacingWave>? pacingWaves,
    bool? rushMode,
    bool? rushBypassUnlockAt,
    double? payoutMultiplier,
    double? maxWinProbabilityPerSpin,
    double? rushMaxWinProbabilityPerSpin,
    int? maxPrizesPerUser,
    bool? allowPlayAfterCap,
    Map<PrizeRarity, int>? maxWinsByRarity,
    int? minSpinsBetweenWins,
    double? bonusProbability,
    int? bonusMinTickets,
    int? bonusMaxTickets,
    int? maxBonusWinsPerUser,
    double? wildReplacementChance,
    int? spinCooldownMs,
    int? maxTotalEarnedTicketsPerUser,
    int? maxManualGrantPerAction,
    int? maxManualTicketsPerUser,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    String? updatedBy,
  }) => SpinConfig(
    status: status ?? this.status,
    pauseMessage: pauseMessage ?? this.pauseMessage,
    ticketCostPerSpin: ticketCostPerSpin ?? this.ticketCostPerSpin,
    defaultInitialTickets: defaultInitialTickets ?? this.defaultInitialTickets,
    packageTicketBonus: packageTicketBonus ?? this.packageTicketBonus,
    matchRegistrationByEmail:
        matchRegistrationByEmail ?? this.matchRegistrationByEmail,
    registeredAttendeesCount:
        registeredAttendeesCount ?? this.registeredAttendeesCount,
    expectedSpinsPerAttendee:
        expectedSpinsPerAttendee ?? this.expectedSpinsPerAttendee,
    estimatedTotalSpinsOverride: clearEstimatedTotalSpinsOverride
        ? null
        : (estimatedTotalSpinsOverride ?? this.estimatedTotalSpinsOverride),
    pacingMode: pacingMode ?? this.pacingMode,
    pacingStartAt: clearPacingStartAt
        ? null
        : (pacingStartAt ?? this.pacingStartAt),
    pacingEndAt: clearPacingEndAt ? null : (pacingEndAt ?? this.pacingEndAt),
    pacingCurveGamma: pacingCurveGamma ?? this.pacingCurveGamma,
    pacingWaves: pacingWaves ?? this.pacingWaves,
    rushMode: rushMode ?? this.rushMode,
    rushBypassUnlockAt: rushBypassUnlockAt ?? this.rushBypassUnlockAt,
    payoutMultiplier: payoutMultiplier ?? this.payoutMultiplier,
    maxWinProbabilityPerSpin:
        maxWinProbabilityPerSpin ?? this.maxWinProbabilityPerSpin,
    rushMaxWinProbabilityPerSpin:
        rushMaxWinProbabilityPerSpin ?? this.rushMaxWinProbabilityPerSpin,
    maxPrizesPerUser: maxPrizesPerUser ?? this.maxPrizesPerUser,
    allowPlayAfterCap: allowPlayAfterCap ?? this.allowPlayAfterCap,
    maxWinsByRarity: maxWinsByRarity ?? this.maxWinsByRarity,
    minSpinsBetweenWins: minSpinsBetweenWins ?? this.minSpinsBetweenWins,
    bonusProbability: bonusProbability ?? this.bonusProbability,
    bonusMinTickets: bonusMinTickets ?? this.bonusMinTickets,
    bonusMaxTickets: bonusMaxTickets ?? this.bonusMaxTickets,
    maxBonusWinsPerUser: maxBonusWinsPerUser ?? this.maxBonusWinsPerUser,
    wildReplacementChance: wildReplacementChance ?? this.wildReplacementChance,
    spinCooldownMs: spinCooldownMs ?? this.spinCooldownMs,
    maxTotalEarnedTicketsPerUser:
        maxTotalEarnedTicketsPerUser ?? this.maxTotalEarnedTicketsPerUser,
    maxManualGrantPerAction:
        maxManualGrantPerAction ?? this.maxManualGrantPerAction,
    maxManualTicketsPerUser:
        maxManualTicketsPerUser ?? this.maxManualTicketsPerUser,
    updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
    updatedBy: updatedBy ?? this.updatedBy,
  );

  factory SpinConfig.fromJson(Map<String, dynamic> json) {
    final rawRarityMap = parseDynamicMap(json['maxWinsByRarity']);
    final maxWinsByRarity = {
      for (final rarity in PrizeRarity.values)
        rarity: parseInt(
          rawRarityMap[rarity.value],
          fallback: defaultMaxWinsByRarity[rarity] ?? 1,
        ),
    };

    final rawWaves = json['pacingWaves'];
    final pacingWaves = rawWaves is List
        ? rawWaves
              .whereType<Map>()
              .map((item) => SpinPacingWave.fromJson(parseDynamicMap(item)))
              .toList(growable: false)
        : const <SpinPacingWave>[];

    return SpinConfig(
      status: SpinGameStatus.fromValue(json['status'] as String?),
      pauseMessage: parseString(json['pauseMessage']),
      ticketCostPerSpin: max(
        1,
        parseInt(json['ticketCostPerSpin'], fallback: 1),
      ),
      defaultInitialTickets: max(
        0,
        parseInt(json['defaultInitialTickets'], fallback: 2),
      ),
      packageTicketBonus: parseStringIntMap(json['packageTicketBonus']),
      matchRegistrationByEmail: parseBool(
        json['matchRegistrationByEmail'],
        fallback: true,
      ),
      registeredAttendeesCount: max(
        0,
        parseInt(json['registeredAttendeesCount']),
      ),
      expectedSpinsPerAttendee: parseDouble(
        json['expectedSpinsPerAttendee'],
        fallback: 4.0,
      ),
      estimatedTotalSpinsOverride: parseNullableInt(
        json['estimatedTotalSpinsOverride'],
      ),
      pacingMode: SpinPacingMode.fromValue(json['pacingMode'] as String?),
      pacingStartAt: parseDateTime(json['pacingStartAt']),
      pacingEndAt: parseDateTime(json['pacingEndAt']),
      pacingCurveGamma: parseDouble(json['pacingCurveGamma'], fallback: 1.0),
      pacingWaves: pacingWaves,
      rushMode: parseBool(json['rushMode']),
      rushBypassUnlockAt: parseBool(json['rushBypassUnlockAt'], fallback: true),
      payoutMultiplier: parseDouble(json['payoutMultiplier'], fallback: 1.0),
      maxWinProbabilityPerSpin: parseDouble(
        json['maxWinProbabilityPerSpin'],
        fallback: 0.45,
      ),
      rushMaxWinProbabilityPerSpin: parseDouble(
        json['rushMaxWinProbabilityPerSpin'],
        fallback: 0.85,
      ),
      maxPrizesPerUser: max(0, parseInt(json['maxPrizesPerUser'], fallback: 3)),
      allowPlayAfterCap: parseBool(json['allowPlayAfterCap']),
      maxWinsByRarity: maxWinsByRarity,
      minSpinsBetweenWins: max(
        0,
        parseInt(json['minSpinsBetweenWins'], fallback: 1),
      ),
      bonusProbability: parseDouble(json['bonusProbability'], fallback: 0.06),
      bonusMinTickets: max(1, parseInt(json['bonusMinTickets'], fallback: 1)),
      bonusMaxTickets: max(1, parseInt(json['bonusMaxTickets'], fallback: 3)),
      maxBonusWinsPerUser: max(
        0,
        parseInt(json['maxBonusWinsPerUser'], fallback: 2),
      ),
      wildReplacementChance: parseDouble(
        json['wildReplacementChance'],
        fallback: 0.35,
      ),
      spinCooldownMs: max(0, parseInt(json['spinCooldownMs'], fallback: 2500)),
      maxTotalEarnedTicketsPerUser: max(
        0,
        parseInt(json['maxTotalEarnedTicketsPerUser'], fallback: 15),
      ),
      maxManualGrantPerAction: max(
        1,
        parseInt(json['maxManualGrantPerAction'], fallback: 5),
      ),
      maxManualTicketsPerUser: max(
        0,
        parseInt(json['maxManualTicketsPerUser'], fallback: 10),
      ),
      updatedAt: parseDateTime(json['updatedAt']),
      updatedBy: parseString(json['updatedBy']),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.value,
    'pauseMessage': pauseMessage,
    'ticketCostPerSpin': ticketCostPerSpin,
    'defaultInitialTickets': defaultInitialTickets,
    'packageTicketBonus': Map<String, int>.from(packageTicketBonus),
    'matchRegistrationByEmail': matchRegistrationByEmail,
    'registeredAttendeesCount': registeredAttendeesCount,
    'expectedSpinsPerAttendee': expectedSpinsPerAttendee,
    'estimatedTotalSpinsOverride': estimatedTotalSpinsOverride,
    'pacingMode': pacingMode.value,
    'pacingStartAt': toIsoStringOrNull(pacingStartAt),
    'pacingEndAt': toIsoStringOrNull(pacingEndAt),
    'pacingCurveGamma': pacingCurveGamma,
    'pacingWaves': pacingWaves.map((wave) => wave.toJson()).toList(),
    'rushMode': rushMode,
    'rushBypassUnlockAt': rushBypassUnlockAt,
    'payoutMultiplier': payoutMultiplier,
    'maxWinProbabilityPerSpin': maxWinProbabilityPerSpin,
    'rushMaxWinProbabilityPerSpin': rushMaxWinProbabilityPerSpin,
    'maxPrizesPerUser': maxPrizesPerUser,
    'allowPlayAfterCap': allowPlayAfterCap,
    'maxWinsByRarity': {
      for (final rarity in PrizeRarity.values)
        rarity.value: maxWinsByRarity[rarity] ?? 0,
    },
    'minSpinsBetweenWins': minSpinsBetweenWins,
    'bonusProbability': bonusProbability,
    'bonusMinTickets': bonusMinTickets,
    'bonusMaxTickets': bonusMaxTickets,
    'maxBonusWinsPerUser': maxBonusWinsPerUser,
    'wildReplacementChance': wildReplacementChance,
    'spinCooldownMs': spinCooldownMs,
    'maxTotalEarnedTicketsPerUser': maxTotalEarnedTicketsPerUser,
    'maxManualGrantPerAction': maxManualGrantPerAction,
    'maxManualTicketsPerUser': maxManualTicketsPerUser,
    'updatedAt': toIsoStringOrNull(updatedAt),
    'updatedBy': updatedBy,
  };
}
