import 'package:app_events/constants.dart';
import 'package:app_events/models/speaker.dart';
import 'package:app_events/screens/schedule_detail.dart';
import 'package:app_events/widgets/card_content.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CardSchedule extends StatelessWidget {
  final Speaker info;
  final bool showTitle;
  final bool action;

  const CardSchedule({
    required this.info,
    this.showTitle = false,
    this.action = true,
    super.key,
  });

  Color colorTag(String area) {
    switch (area) {
      case "Mobile":
        return AppStyles.colorBaseGreen;
      case "IA":
        return AppStyles.colorBaseYellow;
      case "Cloud":
        return AppStyles.colorBaseRed;
      case "Web":
        return AppStyles.colorBaseBlue;
      default:
        return AppStyles.colorBaseRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: CardContent(
        child: TextButton(
          onPressed: () {
            if (!action) {
              return;
            }
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => ScheduleDetail(
                  info: info,
                ),
              ),
            );
          },
          style: TextButton.styleFrom(padding: const EdgeInsets.all(0)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 15, left: 10, right: 10, bottom: 10),
                child: Column(
                  children: [
                    ClipOval(
                      // child: Image.network(
                      //   info.photoUrl,
                      //   fit: BoxFit.cover,
                      //   width: MediaQuery.of(context).size.width * 0.23,
                      //   height: MediaQuery.of(context).size.width * 0.23,
                      // ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.23,
                        height: MediaQuery.of(context).size.width * 0.23,
                        child: FadeInImage(
                            placeholder: const AssetImage(
                                "assets/img/gitgoogle-loading.gif"),
                            image: NetworkImage(info.photoUrl)),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 5),
                      width: 60,
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      decoration: BoxDecoration(
                          color: colorTag(info.technologyType),
                          border: Border.all(color: AppStyles.fontColor),
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        info.technologyType,
                        style: const TextStyle(
                            color: AppStyles.backgroundColor,
                            fontWeight: FontWeight.normal,
                            fontSize: 12),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        info.title,
                        maxLines: (showTitle) ? 8 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.fontColor),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        info.name,
                        style: const TextStyle(
                          color: AppStyles.fontColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        info.profession,
                        style: const TextStyle(
                          color: AppStyles.fontSecundaryColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        '${info.type} | ${info.schedule}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppStyles.fontColor,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
