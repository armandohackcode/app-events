import 'package:app_events/domain/models/spin_config.dart';
import 'package:app_events/domain/models/spin_dashboard.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinDashboardStats', () {
    test('fromJson uses safe defaults for empty map', () {
      final dashboard = SpinDashboardStats.fromJson({});

      expect(dashboard.config.status, SpinGameStatus.paused);
      expect(dashboard.stats.totalSpins, 0);
      expect(dashboard.stats.totalWins, 0);
      expect(dashboard.prizes, isEmpty);
      expect(dashboard.winCounts.total, 0);
      expect(dashboard.activePlayersCount, 0);
      expect(dashboard.registrationsCount, 0);
    });

    test('SpinWinCounts computes total fallback when omitted', () {
      final counts = SpinWinCounts.fromJson({
        'pending': 3,
        'redeemed': 5,
        'revoked': 1,
      });
      expect(counts.total, 9);
    });

    test('round-trip toJson and fromJson preserves dashboard aggregate', () {
      const original = SpinDashboardStats(
        config: SpinConfig(status: SpinGameStatus.active),
        stats: SpinStatsSummary(
          totalSpins: 120,
          totalWins: 18,
          totalBonusSpins: 7,
          totalBonusTickets: 14,
          totalTicketsIssued: 250,
          totalTicketsSpent: 120,
        ),
        prizes: [
          SpinPrize(
            id: 'mug',
            name: 'GDG Mug',
            symbol: SpinSymbol.bell,
            initialStock: 5,
            remainingStock: 3,
            rarity: PrizeRarity.rare,
          ),
        ],
        winCounts: SpinWinCounts(
          pending: 8,
          redeemed: 9,
          revoked: 1,
          total: 18,
        ),
        activePlayersCount: 64,
        registrationsCount: 240,
      );

      final json = original.toJson();
      final restored = SpinDashboardStats.fromJson(json);

      expect(restored.toJson(), json);
    });
  });
}
