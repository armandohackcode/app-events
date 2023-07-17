import 'package:app_events/models/speaker.dart';
import 'package:app_events/widgets/schedule_screen/card_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class ScheduleDetail extends StatelessWidget {
  final Speaker info;
  const ScheduleDetail({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(info.type),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          CardSchedule(
            info: info,
            showTitle: true,
          ),
          const SizedBox(height: 20),
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(info.description),
          const SizedBox(height: 20),
          const Text(
            'Acerca de mi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(info.aboutMe),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var item in info.socialNetwork)
                SizedBox(
                  child: InkWell(
                    child: SvgPicture.asset(
                      getSVG(item),
                      width: 60,
                      height: 40,
                    ),
                    onTap: () async {
                      await _laucher(item.link);
                    },
                  ),
                )
            ],
          )
        ],
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

  Future<void> _laucher(String url) async {
    var link = Uri.parse(url);
    if (await canLaunchUrl(link)) {
      await launchUrl(
        link,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
