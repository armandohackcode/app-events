import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrizeRarity', () {
    test('fromValue maps known values and defaults to common', () {
      expect(PrizeRarity.fromValue('rare'), PrizeRarity.rare);
      expect(PrizeRarity.fromValue('epic'), PrizeRarity.epic);
      expect(PrizeRarity.fromValue('legendary'), PrizeRarity.legendary);
      expect(PrizeRarity.fromValue(null), PrizeRarity.common);
      expect(PrizeRarity.fromValue('mythic'), PrizeRarity.common);
    });
  });

  group('SpinPrize', () {
    test('fromJson uses safe defaults for empty map', () {
      final prize = SpinPrize.fromJson({});

      expect(prize.id, '');
      expect(prize.name, '');
      expect(prize.description, '');
      expect(prize.symbol, SpinSymbol.lemon);
      expect(prize.imageUrl, isNull);
      expect(prize.initialStock, 0);
      expect(prize.remainingStock, 0);
      expect(prize.awardedCount, 0);
      expect(prize.redeemedCount, 0);
      expect(prize.releasedStock, 0);
      expect(prize.maxPerUser, 1);
      expect(prize.weight, 1.0);
      expect(prize.unlockAt, isNull);
      expect(prize.active, isTrue);
      expect(prize.order, 0);
      expect(prize.updatedAt, isNull);
      expect(prize.rarity, PrizeRarity.common);
      expect(prize.isSoldOut, isTrue);
    });

    test('releasedStock defaults to initialStock when omitted', () {
      const prize = SpinPrize(
        id: 'mug',
        name: 'GDG Mug',
        symbol: SpinSymbol.bell,
        initialStock: 8,
        remainingStock: 5,
        rarity: PrizeRarity.rare,
      );
      expect(prize.releasedStock, 8);

      final parsed = SpinPrize.fromJson({'initialStock': 12});
      expect(parsed.remainingStock, 12);
      expect(parsed.releasedStock, 12);
    });

    test('round-trip toJson and fromJson preserves all fields and keys', () {
      final unlockAt = DateTime.utc(2026, 11, 28, 13, 30);
      final updatedAt = DateTime.utc(2026, 11, 28, 9, 0);
      final original = SpinPrize(
        id: 'sparky',
        name: 'Sparky Plush',
        description: 'Limited edition',
        symbol: SpinSymbol.star,
        imageUrl: 'https://example.com/sparky.png',
        initialStock: 5,
        remainingStock: 3,
        awardedCount: 2,
        redeemedCount: 1,
        releasedStock: 4,
        maxPerUser: 2,
        weight: 1.5,
        unlockAt: unlockAt,
        active: false,
        order: 3,
        updatedAt: updatedAt,
        rarity: PrizeRarity.epic,
      );

      final json = original.toJson();
      expect(json.keys, {
        'id',
        'name',
        'description',
        'symbol',
        'imageUrl',
        'rarity',
        'initialStock',
        'remainingStock',
        'awardedCount',
        'redeemedCount',
        'releasedStock',
        'maxPerUser',
        'weight',
        'unlockAt',
        'active',
        'order',
        'updatedAt',
      });

      final restored = SpinPrize.fromJson(json);
      expect(restored.toJson(), json);
      expect(restored.isSoldOut, isFalse);
      expect(restored.unlockAt, unlockAt);
      expect(restored.updatedAt, updatedAt);
    });

    test('copyWith updates only given fields and supports clear flags', () {
      final original = SpinPrize(
        id: 'stickers',
        name: 'GDG Stickers',
        symbol: SpinSymbol.cherries,
        initialStock: 30,
        remainingStock: 10,
        rarity: PrizeRarity.common,
        imageUrl: 'https://example.com/stickers.png',
        unlockAt: DateTime.utc(2026, 11, 28, 12),
        updatedAt: DateTime.utc(2026, 11, 28, 8),
      );

      final updated = original.copyWith(
        remainingStock: 0,
        clearImageUrl: true,
        clearUnlockAt: true,
        clearUpdatedAt: true,
      );

      expect(updated.remainingStock, 0);
      expect(updated.isSoldOut, isTrue);
      expect(updated.imageUrl, isNull);
      expect(updated.unlockAt, isNull);
      expect(updated.updatedAt, isNull);
      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.symbol, original.symbol);
      expect(updated.initialStock, original.initialStock);
      expect(updated.rarity, original.rarity);
    });
  });
}
