import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/screens/attendies_screen.dart';
import 'package:app_events/screens/schedule_screen.dart';
import 'package:app_events/widgets/button_activity.dart';
import 'package:app_events/widgets/card_content.dart';
import 'package:app_events/widgets/home/organizers_screen.dart';
import 'package:app_events/widgets/home/ranking_data.dart';
import 'package:app_events/widgets/home/sponsors_content.dart';
import 'package:app_events/widgets/utils/qr_scan_content.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(title: SvgPicture.asset('assets/img/logo.svg')),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const CardSchedule(),
          const SizedBox(height: 20),
          const Text(
            "Únete a las actividades",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ButtonActivity(
              onPressed: () {
                Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const RankingData()));
              },
              text: "Torneo GDG Sucre",
              icon: Image.asset("assets/img/trofeo.png", height: 60)),
          const SizedBox(height: 10),
          ButtonActivity(
            icon: SvgPicture.asset('assets/img/icon-gdg.svg'),
            text: 'Conoce a la comunidad',
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const OrganizersScreen(),
                ),
              );
              // await laucherUrlInfo(
              //     "https://gdg.community.dev/events/details/google-gdg-sucre-presents-google-io-extended-sucre-1/");
            },
          ),
          const SizedBox(height: 10),
          ButtonActivity(
            icon: SvgPicture.asset('assets/img/icon-discord.svg'),
            text: 'Únete al canal en Discord',
            onPressed: () async {
              await laucherUrlInfo("https://discord.gg/c6gC5W4wtx");
            },
          ),
          const SizedBox(height: 10),
          if (dataCenter.isAdmin)
            ButtonActivity(
              icon: Image.asset("assets/img/dino-write.png"),
              text: 'Participantes',
              onPressed: () async {
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const AttendiesScrren()));
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
                "Versión de aplicación: ${snapshot.data?.version ?? ""}",
                textAlign: TextAlign.center,
              );
            },
          ),
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
            onPressed: () async {
              await laucherUrlInfo(
                  "https://www.linkedin.com/in/armandohackcode/");
            },
            child: const Text("Desarrollado por @armandohackcode"),
          ),
          const SizedBox(height: 60),
        ],
      ),
      floatingActionButton:
          (dataCenter.userCompetitor != null) ? const ButtonScan() : null,
      // bottomNavigationBar: const BottonCustomNavApp(),
    );
  }
}

class ButtonScan extends StatelessWidget {
  const ButtonScan({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppStyles.colorBaseBlue,
      child: const Icon(
        Icons.qr_code_scanner,
        size: 32,
      ),
      onPressed: () async {
        final dataCenter = Provider.of<DataCenter>(context, listen: false);
        var res = await Navigator.of(context).push<Barcode?>(MaterialPageRoute(
          builder: (context) => const QRScanContent(
            msg: "Scanea el código QR de tu nuevo amigo",
          ),
        ));
        if (res != null) {
          var info = await dataCenter.addNewFriend(res.code!);
          if (info != null && context.mounted) {
            customSnackbar(context, "Añadiste a un nuevo amigo");
          } else {
            if (context.mounted) {
              customSnackbar(context, "QR no válido",
                  color: AppStyles.colorBaseRed);
            }
          }
        }
      },
    );
  }
}

class CardSchedule extends StatelessWidget {
  const CardSchedule({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CardContent(
      height: 140,
      child: TextButton(
        style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
        onPressed: () {
          Navigator.of(context)
              .push(CupertinoPageRoute(builder: (_) => const ScheduleScreen()));
        },
        child: Stack(
          alignment: const Alignment(0, 0),
          children: [
            Container(
              alignment: const Alignment(0, 1),
              child: Image.asset('assets/img/bottom_schedule.png'),
            ),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Padding(
                //   padding: const EdgeInsets.only(top: 20),
                //   child: SvgPicture.asset('assets/img/img_cronograma.svg'),
                // ),
                Stack(
                  alignment: Alignment(0, 1.2),
                  children: [
                    Text(
                      "12",
                      style: TextStyle(
                        fontSize: 60,
                        color: AppStyles.fontColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Agosto",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 40,
                ),
                Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text(
                    "Cronograma",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.fontColor,
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
