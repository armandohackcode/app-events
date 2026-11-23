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
      expect(prize.symbol, SpinSymbol.lemon);
      expect(prize.initialStock, 0);
      expect(prize.remainingStock, 0);
      expect(prize.rarity, PrizeRarity.common);
      expect(prize.isSoldOut, isTrue);
    });

    test('round-trip toJson and fromJson preserves data and keys', () {
      const original = SpinPrize(
        id: 'mug',
        name: 'GDG Mug',
        symbol: SpinSymbol.bell,
        initialStock: 5,
        remainingStock: 3,
        rarity: PrizeRarity.rare,
      );

      final json = original.toJson();
      expect(json.keys, {
        'id',
        'name',
        'symbol',
        'initialStock',
        'remainingStock',
        'rarity',
      });

      final restored = SpinPrize.fromJson(json);
      expect(restored.toJson(), json);
      expect(restored.isSoldOut, isFalse);
    });

    test('copyWith updates only the given fields', () {
      const original = SpinPrize(
        id: 'stickers',
        name: 'GDG Stickers',
        symbol: SpinSymbol.cherries,
        initialStock: 30,
        remainingStock: 10,
        rarity: PrizeRarity.common,
      );

      final updated = original.copyWith(remainingStock: 0);

      expect(updated.remainingStock, 0);
      expect(updated.isSoldOut, isTrue);
      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.symbol, original.symbol);
      expect(updated.initialStock, original.initialStock);
      expect(updated.rarity, original.rarity);
    });
  });
}
