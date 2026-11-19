import 'package:app_events/domain/models/spin_symbol.dart';

/// Rarity tier for a GDG SPIN prize.
enum PrizeRarity {
  common,
  rare,
  epic,
  legendary;

  String get value => name;

  static PrizeRarity fromValue(String? text) {
    for (final rarity in values) {
      if (rarity.name == text) return rarity;
    }
    return PrizeRarity.common;
  }
}

/// Prize configured for GDG SPIN with remaining stock tracking.
class SpinPrize {
  final String id;
  final String name;
  final SpinSymbol symbol;
  final int initialStock;
  final int remainingStock;
  final PrizeRarity rarity;

  const SpinPrize({
    required this.id,
    required this.name,
    required this.symbol,
    required this.initialStock,
    required this.remainingStock,
    required this.rarity,
  });

  bool get isSoldOut => remainingStock <= 0;

  SpinPrize copyWith({
    String? id,
    String? name,
    SpinSymbol? symbol,
    int? initialStock,
    int? remainingStock,
    PrizeRarity? rarity,
  }) => SpinPrize(
    id: id ?? this.id,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    initialStock: initialStock ?? this.initialStock,
    remainingStock: remainingStock ?? this.remainingStock,
    rarity: rarity ?? this.rarity,
  );

  factory SpinPrize.fromJson(Map<String, dynamic> json) => SpinPrize(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    symbol: SpinSymbol.fromValue(json['symbol'] as String?),
    initialStock: (json['initialStock'] as num?)?.toInt() ?? 0,
    remainingStock: (json['remainingStock'] as num?)?.toInt() ?? 0,
    rarity: PrizeRarity.fromValue(json['rarity'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'symbol': symbol.value,
    'initialStock': initialStock,
    'remainingStock': remainingStock,
    'rarity': rarity.value,
  };
}
