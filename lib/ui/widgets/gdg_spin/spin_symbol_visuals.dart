import 'dart:math' as math;

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/spin_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// UI metadata (asset path, win accent color, and localized name) for [SpinSymbol].
extension SpinSymbolVisuals on SpinSymbol {
  String? get assetPath => switch (this) {
    SpinSymbol.seven => null,
    SpinSymbol.bar => AppAssetsPath.androidPed,
    SpinSymbol.cherries => AppAssetsPath.dinoRunIcon,
    SpinSymbol.bell => AppAssetsPath.computerIcon,
    SpinSymbol.star => AppAssetsPath.firePedIcon,
    SpinSymbol.diamond => AppAssetsPath.dashPed,
    SpinSymbol.lemon => AppAssetsPath.treasureBuntImg2,
    SpinSymbol.mysteryBox => AppAssetsPath.trophyIcon,
    SpinSymbol.wild => AppAssetsPath.logoGdg,
  };

  Color get accentColor => switch (this) {
    SpinSymbol.cherries => AppStyles.gdgBrandPalette[0],
    SpinSymbol.bell => AppStyles.spinAccentDiamondColor,
    SpinSymbol.bar => AppStyles.gdgBrandPalette[3],
    SpinSymbol.seven => AppStyles.gdgBrandPalette[0],
    SpinSymbol.star => AppStyles.spinAccentStarColor,
    SpinSymbol.diamond => AppStyles.spinAccentDiamondColor,
    SpinSymbol.mysteryBox => AppStyles.gdgBrandPalette[2],
    SpinSymbol.lemon => AppStyles.gdgBrandPalette[1],
    SpinSymbol.wild => AppStyles.gdgBrandPalette[0],
  };

  String get accessibleName => switch (this) {
    SpinSymbol.seven => AppStrings.spinSymbolSevenName,
    SpinSymbol.bar => AppStrings.spinSymbolBarName,
    SpinSymbol.cherries => AppStrings.spinSymbolCherriesName,
    SpinSymbol.bell => AppStrings.spinSymbolBellName,
    SpinSymbol.star => AppStrings.spinSymbolStarName,
    SpinSymbol.diamond => AppStrings.spinSymbolDiamondName,
    SpinSymbol.lemon => AppStrings.spinSymbolLemonName,
    SpinSymbol.mysteryBox => AppStrings.spinBonusRowName,
    SpinSymbol.wild => AppStrings.spinWildRowName,
  };
}

/// Renders a [SpinSymbol] cleanly inside a square of [size].
///
/// When [slotIndex] is provided (`0..2`), [SpinSymbol.seven] renders the
/// corresponding DevFest letter (`G`, `D`, `G`) so a 3-reel line spells `GDG`.
class SpinSymbolArt extends StatelessWidget {
  final SpinSymbol symbol;
  final double size;
  final int? slotIndex;

  const SpinSymbolArt({
    super.key,
    required this.symbol,
    required this.size,
    this.slotIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (symbol == SpinSymbol.seven) {
      return _GdgBadgeArt(size: size, slotIndex: slotIndex);
    }
    final path = symbol.assetPath!;
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
  }
}

class _GdgBadgeArt extends StatelessWidget {
  final double size;
  final int? slotIndex;

  const _GdgBadgeArt({required this.size, this.slotIndex});

  static const _tileAnglesDeg = [-4.0, 3.0, -2.0];

  @override
  Widget build(BuildContext context) {
    if (slotIndex != null) {
      final idx = slotIndex!.clamp(0, 2);
      final tileWidth = size * 0.78;
      final tileHeight = size * 0.88;
      final borderWidth = (size * 0.065).clamp(1.2, 2.2);
      final shadowOffset = (size * 0.065).clamp(1.0, 2.4);
      final radius = (size * 0.18).clamp(3.0, 9.0);

      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: _GdgColorTile(
            letter: AppStrings.spinSignGdgLetters[idx],
            backgroundColor: AppStyles.gdgBrandPalette[idx],
            angleDeg: _tileAnglesDeg[idx],
            width: tileWidth,
            height: tileHeight,
            fontSize: size * 0.56,
            radius: radius,
            borderWidth: borderWidth,
            shadowOffset: shadowOffset,
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  _GdgColorTile(
                    letter: AppStrings.spinSignGdgLetters[i],
                    backgroundColor: AppStyles.gdgBrandPalette[i],
                    angleDeg: _tileAnglesDeg[i],
                    width: 24,
                    height: 29,
                    fontSize: 16,
                    radius: 6,
                    borderWidth: 2,
                    shadowOffset: 2,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GdgColorTile extends StatelessWidget {
  final String letter;
  final Color backgroundColor;
  final double angleDeg;
  final double width;
  final double height;
  final double fontSize;
  final double radius;
  final double borderWidth;
  final double shadowOffset;

  const _GdgColorTile({
    required this.letter,
    required this.backgroundColor,
    required this.angleDeg,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.radius,
    required this.borderWidth,
    required this.shadowOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angleDeg * math.pi / 180,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: AppStyles.borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppStyles.borderColor,
              offset: Offset(shadowOffset, shadowOffset),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
              color: AppStyles.onAccentColor,
            ),
          ),
        ),
      ),
    );
  }
}
