import 'package:app_events/domain/models/spin_player.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinPlayer', () {
    test('fromJson uses safe defaults for empty map', () {
      final player = SpinPlayer.fromJson({});

      expect(player.uid, '');
      expect(player.displayName, '');
      expect(player.email, '');
      expect(player.tickets, 0);
      expect(player.spinsCount, 0);
      expect(player.totalTicketsEarned, 0);
      expect(player.totalTicketsSpent, 0);
      expect(player.manualTicketsGranted, 0);
      expect(player.bonusWinsCount, 0);
      expect(player.totalPrizesWon, 0);
      expect(player.winsByRarity, {
        PrizeRarity.common: 0,
        PrizeRarity.rare: 0,
        PrizeRarity.epic: 0,
        PrizeRarity.legendary: 0,
      });
      expect(player.winsByPrize, isEmpty);
      expect(player.initialTicketsGranted, isFalse);
      expect(player.packageBonusGranted, isFalse);
      expect(player.matchedPackage, isNull);
      expect(player.lastSpinAt, isNull);
      expect(player.lastWinSpinNumber, isNull);
      expect(player.createdAt, isNull);
      expect(player.updatedAt, isNull);
    });

    test('round-trip toJson and fromJson preserves all fields', () {
      final original = SpinPlayer(
        uid: 'user-1',
        displayName: 'Ada Lovelace',
        email: 'ada@example.com',
        tickets: 4,
        spinsCount: 6,
        totalTicketsEarned: 10,
        totalTicketsSpent: 6,
        manualTicketsGranted: 1,
        bonusWinsCount: 1,
        totalPrizesWon: 2,
        winsByRarity: const {
          PrizeRarity.common: 1,
          PrizeRarity.rare: 1,
          PrizeRarity.epic: 0,
          PrizeRarity.legendary: 0,
        },
        winsByPrize: const {'stickers': 1, 'mug': 1},
        initialTicketsGranted: true,
        packageBonusGranted: true,
        matchedPackage: 'VIP',
        lastSpinAt: DateTime.utc(2026, 11, 28, 11, 30),
        lastWinSpinNumber: 5,
        createdAt: DateTime.utc(2026, 11, 28, 9),
        updatedAt: DateTime.utc(2026, 11, 28, 11, 30),
      );

      final json = original.toJson();
      final restored = SpinPlayer.fromJson(json);

      expect(restored.toJson(), json);
    });

    test('copyWith updates given fields and clears nullable fields', () {
      final original = SpinPlayer(
        uid: 'user-1',
        tickets: 3,
        matchedPackage: 'Standard',
        lastSpinAt: DateTime.utc(2026, 11, 28, 10),
        lastWinSpinNumber: 2,
        createdAt: DateTime.utc(2026, 11, 28, 9),
        updatedAt: DateTime.utc(2026, 11, 28, 10),
      );

      final updated = original.copyWith(
        tickets: 5,
        clearMatchedPackage: true,
        clearLastSpinAt: true,
        clearLastWinSpinNumber: true,
        clearCreatedAt: true,
        clearUpdatedAt: true,
      );

      expect(updated.tickets, 5);
      expect(updated.uid, 'user-1');
      expect(updated.matchedPackage, isNull);
      expect(updated.lastSpinAt, isNull);
      expect(updated.lastWinSpinNumber, isNull);
      expect(updated.createdAt, isNull);
      expect(updated.updatedAt, isNull);
    });
  });
}
