import 'package:animate_do/animate_do.dart';
import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/models/user_competitor.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ModalProfileFriend extends StatefulWidget {
  final String uuid;

  const ModalProfileFriend({super.key, required this.uuid});

  @override
  State<ModalProfileFriend> createState() => _ModalProfileFriendState();
}

class _ModalProfileFriendState extends State<ModalProfileFriend> {
  UserCompetitor? user;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final data = Provider.of<DataCenter>(context, listen: false);
      var res = await data.getUserInfo(widget.uuid);
      setState(() {
        user = res;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppStyles.fontColor,
      children: [
        if (user == null)
          Image.asset("assets/img/GoogleIO_Logo.gif")
        else
          FadeIn(
            child: Container(
              color: AppStyles.fontColor,
              child: Column(
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
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 15.0, left: 10, right: 10),
                                  child: Text(
                                    user!.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(15.0),
                                  child: Text(user!.aboutMe),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    for (var item in user!.socialNetwork)
                                      SizedBox(
                                        child: InkWell(
                                          child: SvgPicture.asset(
                                            getSVG(item),
                                            width: 60,
                                            height: 40,
                                          ),
                                          onTap: () async {
                                            await laucherUrlInfo(item.link);
                                          },
                                        ),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 35),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        "assets/img/dino-write.png",
                        width: 120,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
