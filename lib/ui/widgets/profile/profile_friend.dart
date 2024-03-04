import 'package:animate_do/animate_do.dart';
import 'package:app_events/domain/bloc/data_center.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
      backgroundColor: AppStyles.colorAppbar,
      children: [
        if (user == null)
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            alignment: Alignment.center,
            child: Center(
              child: LoadingAnimationWidget.twistingDots(
                leftDotColor: AppStyles.colorBaseBlue,
                rightDotColor: AppStyles.colorBaseYellow,
                size: 40,
              ),
            ),
          )
        else
          FadeIn(
            child: Container(
              color: AppStyles.colorAppbar,
              child: Column(
                children: [
                  // const SizedBox(height: 15),
                  Image.asset("assets/img/title-devfest.png"),
                  Stack(
                    alignment: const Alignment(0.9, 1),
                    children: [
                      Stack(
                        alignment: const Alignment(-1, 1),
                        children: [
                          Image.asset(
                            "assets/img/color-red.png",
                            width: MediaQuery.of(context).size.width * 0.35,
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                                top: 20, bottom: 60, left: 20, right: 20),
                            // height: 200,
                            width: 300,
                            decoration: BoxDecoration(
                              color: AppStyles.backgroundColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  width: 1.5, color: AppStyles.borderColor),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 15.0, left: 10, right: 10),
                                  child: Text(
                                    user!.name,
                                    textAlign: TextAlign.center,
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
