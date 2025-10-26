import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/user/attendees_screen.dart';
import 'package:app_events/ui/screens/schedule/schedule_screen.dart';
import 'package:app_events/ui/widgets/button_activity.dart';
import 'package:app_events/ui/widgets/card_content.dart';
import 'package:app_events/ui/widgets/home/organizers_screen.dart';
import 'package:app_events/ui/widgets/home/ranking_data.dart';
import 'package:app_events/ui/widgets/home/sponsors_content.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Image.asset(AppAssetsPath.titleEvent, height: 50),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            const CardSchedule(),
            const SizedBox(height: 20),
            const Text(
              AppStrings.homeEventJoinActivities,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ButtonActivity(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(CupertinoPageRoute(builder: (_) => const RankingData()));
              },
              text: AppStrings.homeTournamentGDG,
              icon: Image.asset(AppAssetsPath.trophyIcon, height: 60),
            ),
            const SizedBox(height: 10),
            ButtonActivity(
              icon: SvgPicture.asset(AppAssetsPath.gdgIcon),
              text: AppStrings.homeMeetCommunity,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const OrganizersScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            ButtonActivity(
              icon: SvgPicture.asset(AppAssetsPath.discordIcon),
              text: AppStrings.homeJoinDiscord,
              onPressed: () async {
                await laucherUrlInfo("https://discord.gg/c6gC5W4wtx");
              },
            ),
            const SizedBox(height: 10),
            if (dataCenter.isAdmin)
              ButtonActivity(
                icon: Image.asset(AppAssetsPath.dinoWriteIcon),
                text: AppStrings.commonWordAttendees,
                onPressed: () async {
                  Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const AttendeesScreen()),
                  );
                },
              ),
            const SponsorsContent(),
            const SizedBox(height: 20),
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder:
                  (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }
                    return Text(
                      "${AppStrings.versionApp}: ${snapshot.data?.version ?? ""}",
                      textAlign: TextAlign.center,
                    );
                  },
            ),
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
              onPressed: () async {
                await laucherUrlInfo(
                  "https://www.linkedin.com/in/armandohackcode/",
                );
              },
              child: const Text(AppStrings.developedBy),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: (dataCenter.userCompetitor != null)
          ? const ButtonScan()
          : null,
    );
  }
}

class ButtonScan extends StatelessWidget {
  const ButtonScan({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppStyles.colorBaseBlue,
      child: const Icon(Icons.qr_code_scanner, size: 32),
      onPressed: () async {
        final dataCenter = Provider.of<UserProvider>(context, listen: false);
        var res = await Navigator.of(context).push<Barcode?>(
          MaterialPageRoute(
            builder: (context) =>
                const QRScanContent(msg: AppStrings.scanMessage),
          ),
        );
        if (res != null) {
          var info = await dataCenter.addNewFriend(res.code!);
          if (info != null && context.mounted) {
            customSnackbar(context, AppStrings.scanMessageAddedFriend);
          } else {
            if (context.mounted) {
              customSnackbar(
                context,
                AppStrings.scanMessageInvalidQR,
                color: AppStyles.colorBaseRed,
              );
            }
          }
        }
      },
    );
  }
}

class CardSchedule extends StatelessWidget {
  const CardSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return CardContent(
      height: 140,
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
        onPressed: () {
          Navigator.of(
            context,
          ).push(CupertinoPageRoute(builder: (_) => const ScheduleScreen()));
        },
        child: Stack(
          alignment: const Alignment(0, 0),
          children: [
            Positioned(
              left: 10,
              child: Image.asset(
                AppAssetsPath.scheduleIcon,
                height: MediaQuery.of(context).size.height * 0.08,
              ),
            ),
            Container(
              alignment: const Alignment(1, 1),
              child: Image.asset(
                AppAssetsPath.footerImage,
                height: MediaQuery.of(context).size.height * 0.05,
              ),
            ),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Stack(
                  alignment: Alignment(0, 1.2),
                  children: [
                    Text(
                      AppStrings.homeEventDay,
                      style: TextStyle(
                        fontSize: 50,
                        color: AppStyles.fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppStrings.homeEventMonth,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 20),
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text(
                    AppStrings.scheduleSchedule,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
