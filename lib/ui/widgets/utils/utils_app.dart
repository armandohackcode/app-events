import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void customSnackbar(
  BuildContext context,
  String text, {
  Color color = AppStyles.colorBaseBlue,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: Row(
        children: [
          Image.asset(AppAssetsPath.firePedIcon, width: 45, height: 45),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.65,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(text),
            ),
          ),
        ],
      ),
    ),
  );
}

String getSVG(SocialNetwork item) {
  return switch (item.networkType) {
    SocialNetworkType.github => AppAssetsPath.iconGithub,
    SocialNetworkType.facebook => AppAssetsPath.iconFacebook,
    SocialNetworkType.instagram => AppAssetsPath.iconInstagram,
    SocialNetworkType.twitter => AppAssetsPath.iconTwitter,
    SocialNetworkType.linkedin => AppAssetsPath.iconLinkedIn,
    SocialNetworkType.tiktok ||
    SocialNetworkType.blog ||
    SocialNetworkType.unknown => AppAssetsPath.iconWebRound,
  };
}

/// Brand color of the button that represents [item].
Color getSocialColor(SocialNetwork item) {
  return switch (item.networkType) {
    SocialNetworkType.github => AppStyles.socialGithubColor,
    SocialNetworkType.facebook => AppStyles.socialFacebookColor,
    SocialNetworkType.instagram => AppStyles.socialInstagramColor,
    SocialNetworkType.twitter => AppStyles.socialTwitterColor,
    SocialNetworkType.linkedin => AppStyles.socialLinkedInColor,
    SocialNetworkType.tiktok => AppStyles.socialTikTokColor,
    SocialNetworkType.blog ||
    SocialNetworkType.unknown => AppStyles.socialWebColor,
  };
}

/// Single-color glyph of [item], meant to be tinted over [getSocialColor].
String getSocialGlyph(SocialNetwork item) {
  return switch (item.networkType) {
    SocialNetworkType.github => AppAssetsPath.glyphGithub,
    SocialNetworkType.facebook => AppAssetsPath.glyphFacebook,
    SocialNetworkType.instagram => AppAssetsPath.glyphInstagram,
    SocialNetworkType.twitter => AppAssetsPath.glyphTwitter,
    SocialNetworkType.linkedin => AppAssetsPath.glyphLinkedIn,
    SocialNetworkType.tiktok => AppAssetsPath.glyphTikTok,
    SocialNetworkType.blog ||
    SocialNetworkType.unknown => AppAssetsPath.glyphWeb,
  };
}

String getSocialLabel(SocialNetwork item) {
  return switch (item.networkType) {
    SocialNetworkType.github => AppStrings.scheduleGithub,
    SocialNetworkType.facebook => AppStrings.scheduleFacebook,
    SocialNetworkType.instagram => AppStrings.scheduleInstagram,
    SocialNetworkType.twitter => AppStrings.scheduleTwitter,
    SocialNetworkType.linkedin => AppStrings.scheduleLinkedIn,
    SocialNetworkType.tiktok => AppStrings.scheduleTikTok,
    SocialNetworkType.blog ||
    SocialNetworkType.unknown => AppStrings.scheduleBlog,
  };
}

/// Tag color of a talk's technology area.
Color technologyColor(String area) {
  switch (area) {
    case "Mobile":
      return AppStyles.colorBaseGreen;
    case "IA":
      return AppStyles.colorBaseYellow;
    case "Cloud":
      return AppStyles.colorBaseRed;
    case "Web":
      return AppStyles.colorBaseBlue;
    case "UI/UX":
      return AppStyles.colorBasePurple;
    default:
      return AppStyles.colorBaseRed;
  }
}

Future<void> launcherUrlInfo(String url) async {
  try {
    var link = Uri.parse(url);
    if (await canLaunchUrl(link)) {
      await launchUrl(link, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
}
