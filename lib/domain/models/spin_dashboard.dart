import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_json_helpers.dart';
import 'package:app_events/domain/models/spin_prize.dart';

/// Aggregated spin counters across the 5 distributed stat shards.
class SpinStatsSummary {
  final int totalSpins;
  final int totalWins;
  final int totalBonusSpins;
  final int totalBonusTickets;
  final int totalTicketsIssued;
  final int totalTicketsSpent;

  const SpinStatsSummary({
    this.totalSpins = 0,
    this.totalWins = 0,
    this.totalBonusSpins = 0,
    this.totalBonusTickets = 0,
    this.totalTicketsIssued = 0,
    this.totalTicketsSpent = 0,
  });

  factory SpinStatsSummary.fromJson(Map<String, dynamic> json) =>
      SpinStatsSummary(
        totalSpins: parseInt(json['totalSpins']),
        totalWins: parseInt(json['totalWins']),
        totalBonusSpins: parseInt(json['totalBonusSpins']),
        totalBonusTickets: parseInt(json['totalBonusTickets']),
        totalTicketsIssued: parseInt(json['totalTicketsIssued']),
        totalTicketsSpent: parseInt(json['totalTicketsSpent']),
      );

  Map<String, dynamic> toJson() => {
    'totalSpins': totalSpins,
    'totalWins': totalWins,
    'totalBonusSpins': totalBonusSpins,
    'totalBonusTickets': totalBonusTickets,
    'totalTicketsIssued': totalTicketsIssued,
    'totalTicketsSpent': totalTicketsSpent,
  };
}

/// Counts of won prizes grouped by redemption status.
class SpinWinCounts {
  final int pending;
  final int redeemed;
  final int revoked;
  final int total;

  const SpinWinCounts({
    this.pending = 0,
    this.redeemed = 0,
    this.revoked = 0,
    this.total = 0,
  });

  factory SpinWinCounts.fromJson(Map<String, dynamic> json) {
    final pending = parseInt(json['pending']);
    final redeemed = parseInt(json['redeemed']);
    final revoked = parseInt(json['revoked']);
    return SpinWinCounts(
      pending: pending,
      redeemed: redeemed,
      revoked: revoked,
      total: parseInt(json['total'], fallback: pending + redeemed + revoked),
    );
  }

  Map<String, dynamic> toJson() => {
    'pending': pending,
    'redeemed': redeemed,
    'revoked': revoked,
    'total': total,
  };
}

/// Admin dashboard aggregate matching `AdminGetSpinDashboardResponseDto`.
class SpinDashboardStats {
  final SpinConfig config;
  final SpinStatsSummary stats;
  final List<SpinPrize> prizes;
  final SpinWinCounts winCounts;
  final int activePlayersCount;
  final int registrationsCount;

  const SpinDashboardStats({
    required this.config,
    required this.stats,
    required this.prizes,
    required this.winCounts,
    this.activePlayersCount = 0,
    this.registrationsCount = 0,
  });

  factory SpinDashboardStats.fromJson(Map<String, dynamic> json) {
    final rawPrizes = json['prizes'];
    final prizes = rawPrizes is List
        ? rawPrizes
              .whereType<Map>()
              .map((item) => SpinPrize.fromJson(parseDynamicMap(item)))
              .toList(growable: false)
        : const <SpinPrize>[];

    return SpinDashboardStats(
      config: SpinConfig.fromJson(parseDynamicMap(json['config'])),
      stats: SpinStatsSummary.fromJson(parseDynamicMap(json['stats'])),
      prizes: prizes,
      winCounts: SpinWinCounts.fromJson(parseDynamicMap(json['winCounts'])),
      activePlayersCount: parseInt(json['activePlayersCount']),
      registrationsCount: parseInt(json['registrationsCount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'config': config.toJson(),
    'stats': stats.toJson(),
    'prizes': prizes.map((prize) => prize.toJson()).toList(),
    'winCounts': winCounts.toJson(),
    'activePlayersCount': activePlayersCount,
    'registrationsCount': registrationsCount,
  };
}
