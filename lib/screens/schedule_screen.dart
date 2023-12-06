import 'package:animate_do/animate_do.dart';
import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/widgets/schedule_screen/add_schedule.dart';
import 'package:app_events/widgets/schedule_screen/card_schedule.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // late StreamSubscription _sub;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final dataCenter = Provider.of<DataCenter>(context, listen: false);
      // _sub = dataCenter.getListScheduleStream().listen((event) {
      //   print("Conectando ...");
      //   print(event.docs);
      //   var data = event.docs.map((e) => Speaker.fromJson(e.data())).toList();
      //   dataCenter.schedule = data;
      // });
      dataCenter.getListSchedule();
    });
    super.initState();
  }

  @override
  void dispose() {
    // _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cronograma',
          // style: TextStyle(color: AppStyles.fontColor),
        ),
        actions: [
          if (dataCenter.isAdmin)
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const AddSchedule()));
                },
                icon: const Icon(
                  Icons.person_add,
                  size: 32,
                ))
        ],
      ),
      // CardSchedule(
      //       imagePath:
      //           'https://newprofilepic.photo-cdn.net//assets/images/article/profile.jpg?4d355bd',
      //       title: 'Inteligencia Artificial para todos',
      //       name: 'Fernanda Lascano',
      //       profession: 'GDE | Software engineer',
      //       area: "Mobile",
      //       type: 'Conferencia',
      //       hours: '09:00',
      //     ),
      body: (dataCenter.loadingSchedule)
          ? Container(
              height: MediaQuery.of(context).size.height * 0.8,
              alignment: Alignment.center,
              child: Center(
                child: LoadingAnimationWidget.twistingDots(
                  leftDotColor: AppStyles.colorBaseBlue,
                  rightDotColor: AppStyles.colorBaseYellow,
                  size: 40,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await dataCenter.getListSchedule();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: dataCenter.schedule.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = dataCenter.schedule[index];
                  if (item.type == "Actividad") {
                    return ZoomIn(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        alignment: const Alignment(0, 0),
                        decoration: BoxDecoration(
                          color: AppStyles.colorBaseBlue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppStyles.fontColor,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(0),
                          title: Text(
                            item.title.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppStyles.backgroundColor),
                          ),
                          trailing: Text(
                            item.schedule.toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppStyles.backgroundColor),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return ZoomIn(child: CardSchedule(info: item));
                  }
                },
              ),
            ),
    );
  }
}
