import 'package:app_events/domain/models/spin_json_helpers.dart';
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

/// Prize configured for GDG SPIN with remaining stock and pacing metadata.
class SpinPrize {
  final String id;
  final String name;
  final String description;
  final SpinSymbol symbol;
  final String? imageUrl;
  final PrizeRarity rarity;
  final int initialStock;
  final int remainingStock;
  final int awardedCount;
  final int redeemedCount;
  final int releasedStock;
  final int maxPerUser;
  final double weight;
  final DateTime? unlockAt;
  final bool active;
  final int order;
  final DateTime? updatedAt;

  const SpinPrize({
    required this.id,
    required this.name,
    required this.symbol,
    required this.initialStock,
    required this.remainingStock,
    required this.rarity,
    this.description = '',
    this.imageUrl,
    this.awardedCount = 0,
    this.redeemedCount = 0,
    int? releasedStock,
    this.maxPerUser = 1,
    this.weight = 1.0,
    this.unlockAt,
    this.active = true,
    this.order = 0,
    this.updatedAt,
  }) : releasedStock = releasedStock ?? initialStock;

  bool get isSoldOut => remainingStock <= 0;

  SpinPrize copyWith({
    String? id,
    String? name,
    String? description,
    SpinSymbol? symbol,
    String? imageUrl,
    bool clearImageUrl = false,
    PrizeRarity? rarity,
    int? initialStock,
    int? remainingStock,
    int? awardedCount,
    int? redeemedCount,
    int? releasedStock,
    int? maxPerUser,
    double? weight,
    DateTime? unlockAt,
    bool clearUnlockAt = false,
    bool? active,
    int? order,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) => SpinPrize(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    symbol: symbol ?? this.symbol,
    imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
    rarity: rarity ?? this.rarity,
    initialStock: initialStock ?? this.initialStock,
    remainingStock: remainingStock ?? this.remainingStock,
    awardedCount: awardedCount ?? this.awardedCount,
    redeemedCount: redeemedCount ?? this.redeemedCount,
    releasedStock: releasedStock ?? this.releasedStock,
    maxPerUser: maxPerUser ?? this.maxPerUser,
    weight: weight ?? this.weight,
    unlockAt: clearUnlockAt ? null : (unlockAt ?? this.unlockAt),
    active: active ?? this.active,
    order: order ?? this.order,
    updatedAt: clearUpdatedAt ? null : (updatedAt ?? this.updatedAt),
  );

  factory SpinPrize.fromJson(Map<String, dynamic> json) {
    final initialStock = parseInt(json['initialStock']);
    return SpinPrize(
      id: parseString(json['id']),
      name: parseString(json['name']),
      description: parseString(json['description']),
      symbol: SpinSymbol.fromValue(json['symbol'] as String?),
      imageUrl: parseNullableString(json['imageUrl']),
      rarity: PrizeRarity.fromValue(json['rarity'] as String?),
      initialStock: initialStock,
      remainingStock: parseInt(json['remainingStock'], fallback: initialStock),
      awardedCount: parseInt(json['awardedCount']),
      redeemedCount: parseInt(json['redeemedCount']),
      releasedStock: parseInt(json['releasedStock'], fallback: initialStock),
      maxPerUser: parseInt(json['maxPerUser'], fallback: 1),
      weight: parseDouble(json['weight'], fallback: 1.0),
      unlockAt: parseDateTime(json['unlockAt']),
      active: parseBool(json['active'], fallback: true),
      order: parseInt(json['order']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'symbol': symbol.value,
    'imageUrl': imageUrl,
    'rarity': rarity.value,
    'initialStock': initialStock,
    'remainingStock': remainingStock,
    'awardedCount': awardedCount,
    'redeemedCount': redeemedCount,
    'releasedStock': releasedStock,
    'maxPerUser': maxPerUser,
    'weight': weight,
    'unlockAt': toIsoStringOrNull(unlockAt),
    'active': active,
    'order': order,
    'updatedAt': toIsoStringOrNull(updatedAt),
  };
}
