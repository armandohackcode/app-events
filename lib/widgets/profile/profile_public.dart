import 'package:app_events/constants.dart';
import 'package:app_events/models/user_competitor.dart';
import 'package:app_events/widgets/card_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModalProfilePublic extends StatelessWidget {
  final UserCompetitor user;
  const ModalProfilePublic({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppStyles.fontColor,
      children: [
        const SizedBox(height: 15),
        SvgPicture.asset("assets/img/io-logo-white.svg"),
        Stack(
          alignment: const Alignment(0.9, 1),
          children: [
            Stack(
              alignment: const Alignment(0, 1),
              children: [
                Image.asset("assets/img/more-color.png"),
                Container(
                  margin: const EdgeInsets.only(
                      top: 20, bottom: 60, left: 20, right: 20),
                  // height: 200,
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppStyles.backgroundColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(width: 1.5),
                  ),
                  child: Column(children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 15.0, left: 10, right: 10),
                      child: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(user.aboutMe),
                    ),
                    const SizedBox(height: 10),
                  ]),
                ),
              ],
            ),
            Image.asset(
              "assets/img/dino-write.png",
              width: 120,
            )
          ],
        )
      ],
    );
  }
}
