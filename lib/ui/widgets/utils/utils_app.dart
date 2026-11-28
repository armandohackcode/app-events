import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reads an ancestor provider without throwing when absent in isolated tests.
T? maybeProvider<T>(BuildContext context, {bool listen = true}) {
  try {
    return Provider.of<T>(context, listen: listen);
  } on ProviderNotFoundException {
    return null;
  }
}

/// Si es Lead, es 1, si es Organizer, es 2
const int leadValue = 2;
const int organizerValue = 1;

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
          Expanded(
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

/// Icon of a technology area, drawn on its tags and category tiles.
IconData technologyIcon(String area) {
  switch (area) {
    case "Mobile":
      return Icons.smartphone_rounded;
    case "IA":
      return Icons.auto_awesome_rounded;
    case "Cloud":
      return Icons.cloud_outlined;
    case "Web":
      return Icons.language_rounded;
    case "UI/UX":
      return Icons.palette_outlined;
    default:
      return Icons.label_outline_rounded;
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

/// Text shown for a stored activity type: its capitalized label from AppStrings.
/// An unknown type is shown as it is, with its first letter uppercase.
String eventTypeLabel(String type) {
  return switch (EventTypeSpeaker.fromValue(type)) {
    EventTypeSpeaker.conference => AppStrings.eventTypeConference,
    EventTypeSpeaker.workshop => AppStrings.eventTypeWorkshop,
    EventTypeSpeaker.panel => AppStrings.eventTypePanel,
    EventTypeSpeaker.breakTime => AppStrings.eventTypeBreak,
    EventTypeSpeaker.lunch => AppStrings.eventTypeLunch,
    EventTypeSpeaker.networking => AppStrings.eventTypeNetworking,
    EventTypeSpeaker.unknown =>
      type.isEmpty ? type : '${type[0].toUpperCase()}${type.substring(1)}',
  };
}

IconData eventTypeIcon(String type) {
  return switch (EventTypeSpeaker.fromValue(type)) {
    EventTypeSpeaker.conference => Icons.mic_none_rounded,
    EventTypeSpeaker.workshop => Icons.construction_rounded,
    EventTypeSpeaker.panel => Icons.groups_rounded,
    EventTypeSpeaker.breakTime => Icons.coffee_rounded,
    EventTypeSpeaker.lunch => Icons.restaurant_rounded,
    EventTypeSpeaker.networking => Icons.people_alt_rounded,
    EventTypeSpeaker.unknown => Icons.event_note_rounded,
  };
}

/// Background of the tag that shows an activity type.
Color eventTypeColor(String type) {
  return switch (EventTypeSpeaker.fromValue(type)) {
    EventTypeSpeaker.workshop => AppStyles.colorBaseYellow,
    EventTypeSpeaker.panel => AppStyles.cardColor,
    _ => AppStyles.colorBaseRed,
  };
}

/// Text and icon color that reads well over [eventTypeColor].
Color eventTypeForegroundColor(String type) {
  return switch (EventTypeSpeaker.fromValue(type)) {
    EventTypeSpeaker.workshop || EventTypeSpeaker.panel => AppStyles.fontColor,
    _ => AppStyles.onAccentColor,
  };
}
