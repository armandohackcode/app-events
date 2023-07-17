import 'package:app_events/constants.dart';
import 'package:app_events/screens/schedule_screen.dart';
import 'package:app_events/widgets/button_activity.dart';
import 'package:app_events/widgets/card_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: SvgPicture.asset('assets/img/logo.svg')),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const CardSchedule(),
          const SizedBox(height: 20),
          const Text(
            "Unete a las actividades",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ButtonActivity(
            icon: SvgPicture.asset('assets/img/icon-discord.svg'),
            text: 'Unete al canal de Discord',
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          ButtonActivity(
            icon: SvgPicture.asset('assets/img/icon-kahoot.svg'),
            text: 'Juega en Kahoot con Nosotros',
            onPressed: () {},
          ),
          const SizedBox(height: 10),
          ButtonActivity(
            icon: SvgPicture.asset('assets/img/icon-gdg.svg'),
            text: 'Unete a la comunidad',
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyles.colorBaseBlue,
        child: const Icon(
          Icons.qr_code_scanner,
          size: 32,
        ),
        onPressed: () {},
      ),
      // bottomNavigationBar: const BottonCustomNavApp(),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Padding(
                //   padding: const EdgeInsets.only(top: 20),
                //   child: SvgPicture.asset('assets/img/img_cronograma.svg'),
                // ),
                Stack(
                  alignment: const Alignment(0, 1.2),
                  children: const [
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
                const SizedBox(
                  width: 40,
                ),
                const Padding(
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
