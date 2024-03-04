import 'dart:io';

import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';

class ModalProfilePublic extends StatefulWidget {
  final UserCompetitor user;

  const ModalProfilePublic({super.key, required this.user});

  @override
  State<ModalProfilePublic> createState() => _ModalProfilePublicState();
}

class _ModalProfilePublicState extends State<ModalProfilePublic> {
  final globalKey = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppStyles.colorAppbar,
      children: [
        RepaintBoundary(
          key: globalKey,
          child: Container(
            color: AppStyles.colorAppbar,
            child: Column(
              children: [
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
                          child: Column(children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 15.0, left: 10, right: 10),
                              child: Text(
                                widget.user.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Text(widget.user.aboutMe),
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
                ),
              ],
            ),
          ),
        ),
        Align(
          child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.colorBaseYellow),
              onPressed: () async {
                final temp = await getTemporaryDirectory();
                final path = '${temp.path}/user-gdgsucre.jpg';
                File(path).writeAsBytesSync(await capturePng());

                await Share.shareXFiles([XFile(path)],
                    text: "#SOYGDGSUCRE #DEVFEST");
              },
              icon: SvgPicture.asset(
                "assets/img/share-2-svgrepo-com.svg",
              ),
              label: const Text(
                "Compartir",
                style: TextStyle(color: AppStyles.backgroundColor),
              )),
        )
      ],
    );
  }

  Future capturePng() async {
    RenderRepaintBoundary? boundary =
        globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    final image = await boundary!.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}
