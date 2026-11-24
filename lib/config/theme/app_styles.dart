import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateFormat dateFormat = DateFormat('dd/MM/yyyy HH:mm');

class AppStyles {
  static const Color primaryColor = Color(0xFF1E1E1E);
  static const Color cardColor = Colors.white;
  static const Color borderColor = Color(0xFF1E1E1E);

  static const Color backgroundColor = Colors.white;
  static const Color fontColor = Color(0xFF1E1E1E);
  static const Color fontSecondaryColor = Color(0xFF3B3B3B);
  static const Color colorBaseBlue = Color(0xFF0057B8);
  static const Color colorBaseRed = Color(0xFFEA4535);
  static const Color colorFlashRed = Color(0xFFD8190B);
  static const Color colorBaseGreen = Color(0xFF36BD57);
  static const Color colorBaseYellow = Color(0xFFFFBB00);
  static const Color colorBasePurple = Color(0xFFAB47BC); // UI/UX
  static const Color colorNavbar = Colors.white;
  static const Color colorAppbar = Colors.white;

  static const Color colorCardBlue = Color(0xFFE7EFFE);
  static const Color colorCardRed = Color(0xFFFFE5E6);
  static const Color colorFooter = Color(0xFFFAFAF6);

  // Text and icons drawn on colored buttons, tags, images or the camera view.
  static const Color onAccentColor = Colors.white;
  static const Color shadowColor = Color(0x14000000);
  static const Color imageOverlayColor = Color(0x99000000);
  static const Color scrimColor = Colors.black;
  static const Color placeholderColor = Color(0xFFF5F5F5); // Colors.grey[100]
  static const Color qrScanBorderColor = Colors.red;

  // Organizer team tags
  static const Color teamLogisticsColor = Color(0xFF2196F3);
  static const Color teamStagingColor = Color(0xFF9C27B0);
  static const Color teamDesignColor = Color(0xFFE91E63);
  static const Color teamMobileColor = Color(0xFF00BCD4);
  static const Color teamMarketingColor = Color(0xFFFF9800);
  static const Color teamAudioVideoColor = Color(0xFFFF5722);
  static const Color teamDefaultColor = Color(0xFF607D8B);

  // Home screen
  static const Color homeBackgroundColor = Color(0xFFF7F3EA);
  static const Color fontFaintColor = Color(0xFF9A9A95);
  // Soft icon background: the base yellow with reduced opacity.
  static final Color colorCardYellow = colorBaseYellow.withValues(alpha: 0.2);
  static const Color titlePillColor = Color(0xFFAFC6E8);
  static const Color backdropBlueColor = Color(0xFF4285F4);

  // Floating particles of the home background.
  static const Color particleBlueColor = Color(0xFF3B82F6);
  static const Color particleDeepBlueColor = Color(0xFF2F5FD8);
  static const Color particleLightBlueColor = Color(0xFF7FA8F2);

  // Retro window card header strip (its controls use the logo base colors).
  static const Color windowChromeColor = Color(0xFFF4F6FA);

  // Social network brand colors.
  static const Color socialInstagramColor = Color(0xFFE4405F);
  static const Color socialLinkedInColor = Color(0xFF0A66C2);
  static const Color socialTikTokColor = Color(0xFF111111);
  static const Color socialGithubColor = Color(0xFF181717);
  static const Color socialFacebookColor = Color(0xFF1877F2);
  static const Color socialTwitterColor = socialTikTokColor;
  static const Color socialWebColor = colorBaseBlue;
  static const Color socialWhatsAppColor = Color(0xFF25D366);

  /// [color] mixed with black: the dark end of a gradient that starts at [color].
  static Color darken(Color color, [double amount = 0.2]) =>
      Color.lerp(color, scrimColor, amount)!;

  static const String monospaceFontFamily = 'Courier New';

  // Games (Activities tab and GDG SPIN)
  static const Color gamesBackgroundColor = homeBackgroundColor;
  static const List<Color> gdgBrandPalette = [
    backdropBlueColor,
    colorBaseRed,
    colorBaseYellow,
    colorBaseGreen,
  ];
  static const Color activitiesRankingTagColor = Color(0xFFA8C7FA);
  static const Color activitiesSpinTagColor = colorBaseYellow;
  static const Color activitiesTreasureTagColor = Color(0xFFA8DAB5);
  static const Color podiumFirstColor = colorBaseYellow;
  static const Color podiumSecondColor = colorBaseGreen;
  static const Color podiumThirdColor = colorBaseRed;
  static const Color treasureFoundColor = podiumSecondColor;

  // GDG SPIN (blue pop-brutalist cabinet on cream HomeBackdrop)
  static const Color spinCabinetColor = backdropBlueColor;
  static const Color spinCabinetShadowColor = borderColor;
  static const Color spinCabinetInnerShadowColor = borderColor;
  static const Color spinCabinetDotColor = spinDotPatternColor;
  static const Color spinCabinetBulbBorderColor = borderColor;
  static const Color spinLeverStickColor = borderColor;
  static const Color spinDotPatternColor = Color(0x291E1E1E);
  static const Color spinBezelColor = colorBaseYellow;
  static const Color spinReelDimColor = Color(0x99F7F3EA);
  static const Color spinPaylineColor = podiumThirdColor;
  static const Color spinPaylineHitColor = colorBaseYellow;
  static const Color spinKnobColor = podiumThirdColor;
  static const Color spinTeaseColor = Color(0xFFFFF1C7);
  static const Color spinNearMissColor = Color(0xFFF29900);
  static const Color spinCoinColor = colorBaseYellow;
  static const Color spinCoinShadowColor = Color(0xFF9A6F00);
  static const Color spinWarnColor = Color(0xFFF8BDB8);
  static const Color spinScrimColor = Color(0xF0F7F3EA);
  static const Color spinDemoButtonColor = activitiesRankingTagColor;
  static const Color spinMyPrizesTagColor = spinWarnColor;
  static const Color spinPayTableTagColor = colorBaseYellow;
  static const Color spinEarnTagColor = activitiesTreasureTagColor;
  static const Color spinMissionDoneColor = activitiesTreasureTagColor;
  static const Color rarityCommonColor = activitiesTreasureTagColor;
  static const Color rarityRareColor = activitiesRankingTagColor;
  static const Color rarityEpicColor = spinWarnColor;
  static const Color rarityLegendaryColor = colorBaseYellow;
  static const Color raritySpecialColor = Color(0xFFE5E5E0);
  static const Color spinAccentStarColor = Color(0xFFFF9100);
  static const Color spinAccentDiamondColor = Color(0xFF29B6F6);
  static const List<Color> spinFrameBulbPalette = [
    colorBaseYellow,
    cardColor,
    podiumThirdColor,
    podiumSecondColor,
  ];
  static const List<Color> spinBezelBulbPalette = [borderColor, cardColor];
}
