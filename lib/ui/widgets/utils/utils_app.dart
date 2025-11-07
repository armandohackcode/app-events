import 'package:app_events/config/theme/app_assets_path.dart';
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
  switch (item.type) {
    case "GITHUB":
      return AppAssetsPath.iconGithub;
    case "FACEBOOK":
      return AppAssetsPath.iconFacebook;
    case "INSTAGRAM":
      return AppAssetsPath.iconInstagram;
    case "TWITTER":
      return AppAssetsPath.iconTwitter;
    case "LINKEDIN":
      return AppAssetsPath.iconLinkedIn;
    default:
      return AppAssetsPath.iconWebRound;
  }
}

Future<void> laucherUrlInfo(String url) async {
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
