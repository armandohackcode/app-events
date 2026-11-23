import 'package:app_events/domain/models/spin_combo.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinCombo.looksLikeWin', () {
    test('returns true when all three symbols match', () {
      for (final symbol in SpinSymbol.values) {
        expect(SpinCombo.looksLikeWin([symbol, symbol, symbol]), isTrue);
      }
    });

    test('returns true for one wild plus two equal wildable symbols', () {
      for (final symbol in SpinCombo.wildable) {
        expect(
          SpinCombo.looksLikeWin([SpinSymbol.wild, symbol, symbol]),
          isTrue,
        );
        expect(
          SpinCombo.looksLikeWin([symbol, SpinSymbol.wild, symbol]),
          isTrue,
        );
        expect(
          SpinCombo.looksLikeWin([symbol, symbol, SpinSymbol.wild]),
          isTrue,
        );
      }
    });

    test('wild never replaces seven, lemon, or mysteryBox', () {
      expect(
        SpinCombo.looksLikeWin([
          SpinSymbol.wild,
          SpinSymbol.seven,
          SpinSymbol.seven,
        ]),
        isFalse,
      );
      expect(
        SpinCombo.looksLikeWin([
          SpinSymbol.lemon,
          SpinSymbol.wild,
          SpinSymbol.lemon,
        ]),
        isFalse,
      );
      expect(
        SpinCombo.looksLikeWin([
          SpinSymbol.mysteryBox,
          SpinSymbol.mysteryBox,
          SpinSymbol.wild,
        ]),
        isFalse,
      );
    });

    test('returns true when there are at least two wilds', () {
      expect(
        SpinCombo.looksLikeWin([
          SpinSymbol.wild,
          SpinSymbol.wild,
          SpinSymbol.lemon,
        ]),
        isTrue,
      );
      expect(
        SpinCombo.looksLikeWin([
          SpinSymbol.wild,
          SpinSymbol.seven,
          SpinSymbol.wild,
        ]),
        isTrue,
      );
    });

    test('returns false for mixed non-winning lines and invalid lengths', () {
      expect(
        SpinCombo.looksLikeWin([
          SpinSymbol.cherries,
          SpinSymbol.bell,
          SpinSymbol.star,
        ]),
        isFalse,
      );
      expect(
        SpinCombo.looksLikeWin([
          SpinSymbol.wild,
          SpinSymbol.cherries,
          SpinSymbol.bell,
        ]),
        isFalse,
      );
      expect(SpinCombo.looksLikeWin([SpinSymbol.seven]), isFalse);
    });
  });

  group('SpinCombo.canStillWin', () {
    test('returns true for equal symbols except lemon', () {
      for (final symbol in SpinSymbol.values) {
        expect(
          SpinCombo.canStillWin(symbol, symbol),
          symbol != SpinSymbol.lemon,
        );
      }
    });

    test('returns true for wild paired with a wildable symbol', () {
      for (final symbol in SpinCombo.wildable) {
        expect(SpinCombo.canStillWin(SpinSymbol.wild, symbol), isTrue);
        expect(SpinCombo.canStillWin(symbol, SpinSymbol.wild), isTrue);
      }
    });

    test('returns false for wild paired with seven, lemon, or mysteryBox', () {
      for (final symbol in [
        SpinSymbol.seven,
        SpinSymbol.lemon,
        SpinSymbol.mysteryBox,
      ]) {
        expect(SpinCombo.canStillWin(SpinSymbol.wild, symbol), isFalse);
        expect(SpinCombo.canStillWin(symbol, SpinSymbol.wild), isFalse);
      }
    });

    test('returns false for mismatched non-wild symbols', () {
      expect(SpinCombo.canStillWin(SpinSymbol.cherries, SpinSymbol.bar), false);
    });
  });
}
