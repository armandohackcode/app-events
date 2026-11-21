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

  static const String monospaceFontFamily = 'Courier New';
}
