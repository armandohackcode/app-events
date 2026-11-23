/// Symbols shown on the GDG SPIN reels and pay table.
enum SpinSymbol {
  seven,
  bar,
  cherries,
  bell,
  star,
  diamond,
  lemon,
  mysteryBox,
  wild;

  String get value => name;

  static SpinSymbol fromValue(String? text) {
    for (final symbol in values) {
      if (symbol.name == text) return symbol;
    }
    return SpinSymbol.lemon;
  }
}
