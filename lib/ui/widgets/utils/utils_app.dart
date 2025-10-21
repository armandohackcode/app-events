import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void customSnackbar(BuildContext context, String text,
    {Color color = AppStyles.colorBaseBlue}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: Row(
        children: [
          Image.asset(
            'assets/img/fire-ped.png',
            width: 45,
            height: 45,
          ),
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
      return 'assets/img/github-142-svgrepo-com.svg';
    case "FACEBOOK":
      return 'assets/img/facebook-1-svgrepo-com.svg';
    case "INSTAGRAM":
      return 'assets/img/instagram-2016-logo-svgrepo-com.svg';
    case "TWITTER":
      return 'assets/img/twitter-3-logo-svgrepo-com.svg';
    case "LINKEDIN":
      return 'assets/img/linkedin-svgrepo-com.svg';
    default:
      return 'assets/img/web-round-svgrepo-com-2.svg';
  }
}

Future<void> laucherUrlInfo(String url) async {
  try {
    var link = Uri.parse(url);
    if (await canLaunchUrl(link)) {
      await launchUrl(
        link,
        mode: LaunchMode.externalApplication,
      );
    }
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
}
