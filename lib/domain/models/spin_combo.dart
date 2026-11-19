import 'package:app_events/domain/models/spin_symbol.dart';

/// Pure combo rules for GDG SPIN.
///
/// The wild symbol never replaces seven, lemon, or mysteryBox.
class SpinCombo {
  const SpinCombo._();

  static const Set<SpinSymbol> wildable = {
    SpinSymbol.cherries,
    SpinSymbol.bell,
    SpinSymbol.bar,
    SpinSymbol.star,
    SpinSymbol.diamond,
  };

  /// Returns true when a 3-symbol row would look like a win to the player.
  static bool looksLikeWin(List<SpinSymbol> combo) {
    if (combo.length != 3) return false;
    final a = combo[0];
    final b = combo[1];
    final c = combo[2];
    if (a == b && b == c) return true;

    final wildCount = combo.where((s) => s == SpinSymbol.wild).length;
    if (wildCount >= 2) return true;
    if (wildCount == 1) {
      final nonWilds = combo.where((s) => s != SpinSymbol.wild).toList();
      if (nonWilds.length == 2 &&
          nonWilds[0] == nonWilds[1] &&
          wildable.contains(nonWilds[0])) {
        return true;
      }
    }
    return false;
  }

  /// Returns true when the first two reels can still form a winning or bonus
  /// line on the third reel.
  static bool canStillWin(SpinSymbol first, SpinSymbol second) {
    if (first == second && first != SpinSymbol.lemon) return true;
    if (first == SpinSymbol.wild && wildable.contains(second)) return true;
    if (second == SpinSymbol.wild && wildable.contains(first)) return true;
    return false;
  }
}
