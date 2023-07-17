import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/models/speaker.dart';
import 'package:app_events/widgets/schedule_screen/add_schedule.dart';
import 'package:app_events/widgets/schedule_screen/card_schedule.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late StreamSubscription _sub;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final dataCenter = Provider.of<DataCenter>(context, listen: false);
      _sub = dataCenter.getListSchedule().listen((event) {
        print("Conectando ...");
        print(event.docs);
        var data = event.docs.map((e) => Speaker.fromJson(e.data())).toList();
        dataCenter.schedule = data;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub.cancel();
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
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: dataCenter.schedule.length,
        itemBuilder: (BuildContext context, int index) {
          var item = dataCenter.schedule[index];
          if (item.type == "Actividad") {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              alignment: const Alignment(0, 0),
              decoration: BoxDecoration(
                color: AppStyles.colorBaseBlue,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppStyles.fontColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                item.title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          } else {
            return FadeInUp(child: CardSchedule(info: item));
          }
        },
      ),
    );
  }
}
