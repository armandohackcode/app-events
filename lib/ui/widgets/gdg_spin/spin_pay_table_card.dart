import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_prize.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:app_events/ui/widgets/gdg_spin/spin_symbol_visuals.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Card showing every winning combination, remaining stock, bonus, and wild.
class SpinPayTableCard extends StatelessWidget {
  final List<SpinPrize> prizes;

  const SpinPayTableCard({super.key, required this.prizes});

  static const List<double> _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  String _rarityLabel(PrizeRarity rarity) => switch (rarity) {
    PrizeRarity.common => AppStrings.spinRarityCommon,
    PrizeRarity.rare => AppStrings.spinRarityRare,
    PrizeRarity.epic => AppStrings.spinRarityEpic,
    PrizeRarity.legendary => AppStrings.spinRarityLegendary,
  };

  Color _rarityColor(PrizeRarity rarity) => switch (rarity) {
    PrizeRarity.common => AppStyles.rarityCommonColor,
    PrizeRarity.rare => AppStyles.rarityRareColor,
    PrizeRarity.epic => AppStyles.rarityEpicColor,
    PrizeRarity.legendary => AppStyles.rarityLegendaryColor,
  };

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 20,
      shadowOffset: 5,
      borderWidth: 2.5,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.spinThreeOfAKind,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          if (prizes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                AppStrings.spinPayTableEmpty,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            )
          else
            for (var i = 0; i < prizes.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildPrizeRow(prizes[i]),
            ],
          const SizedBox(height: 8),
          const _PayTableRowLayout(
            symbols: [
              SpinSymbol.mysteryBox,
              SpinSymbol.mysteryBox,
              SpinSymbol.mysteryBox,
            ],
            name: AppStrings.spinBonusRowName,
            note: AppStrings.spinBonusRowNote,
            tagText: AppStrings.spinRarityBonus,
            tagColor: AppStyles.raritySpecialColor,
          ),
          const SizedBox(height: 8),
          const _PayTableRowLayout(
            symbols: [SpinSymbol.wild],
            name: AppStrings.spinWildRowName,
            note: AppStrings.spinWildRowNote,
            tagText: AppStrings.spinRarityWild,
            tagColor: AppStyles.raritySpecialColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeRow(SpinPrize prize) {
    final soldOut = prize.isSoldOut;
    final tagColor = soldOut
        ? AppStyles.raritySpecialColor
        : _rarityColor(prize.rarity);
    final tagText = soldOut
        ? AppStrings.spinSoldOut
        : _rarityLabel(prize.rarity);
    final note = soldOut
        ? AppStrings.spinSoldOut
        : AppStrings.spinRemaining(prize.remainingStock, prize.initialStock);

    final row = _PayTableRowLayout(
      symbols: [prize.symbol, prize.symbol, prize.symbol],
      imageUrl: prize.imageUrl,
      name: prize.name,
      note: note,
      tagText: tagText,
      tagColor: tagColor,
      grayscaleMatrix: soldOut ? _grayscaleMatrix : null,
    );

    if (!soldOut) return row;
    return Opacity(opacity: 0.5, child: row);
  }
}

class _PayTableRowLayout extends StatelessWidget {
  final List<SpinSymbol> symbols;
  final String? imageUrl;
  final String name;
  final String note;
  final String tagText;
  final Color tagColor;
  final List<double>? grayscaleMatrix;

  const _PayTableRowLayout({
    required this.symbols,
    required this.name,
    required this.note,
    required this.tagText,
    required this.tagColor,
    this.imageUrl,
    this.grayscaleMatrix,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    Widget symbolsWidget = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < symbols.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            SpinSymbolArt(
              symbol: symbols[i],
              size: 20,
              slotIndex: symbols.length == 3 ? i : null,
            ),
          ],
        ],
      ),
    );

    Widget? thumbnailWidget = hasImage
        ? Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppStyles.gamesBackgroundColor,
              border: Border.all(color: AppStyles.borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SpinPrizeThumbnail(
              symbol: symbols.first,
              imageUrl: imageUrl,
              size: 28,
              fallbackSize: 20,
              borderRadius: 6,
            ),
          )
        : null;

    if (grayscaleMatrix != null) {
      symbolsWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(grayscaleMatrix!),
        child: symbolsWidget,
      );
      if (thumbnailWidget != null) {
        thumbnailWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix(grayscaleMatrix!),
          child: thumbnailWidget,
        );
      }
    }

    return Row(
      children: [
        Container(
          width: 76,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppStyles.gamesBackgroundColor,
            border: Border.all(color: AppStyles.borderColor, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: symbolsWidget,
        ),
        if (thumbnailWidget != null) ...[
          const SizedBox(width: 6),
          thumbnailWidget,
        ],
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
              Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _RarityBadge(text: tagText, color: tagColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _RarityBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppStyles.borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: AppStyles.fontColor,
        ),
      ),
    );
  }
}
