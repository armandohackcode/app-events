// import 'package:app_events/constants.dart';
import 'dart:async';

import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/models/speaker.dart';
import 'package:app_events/widgets/schedule_screen/card_schedule.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class ScheduleDetail extends StatelessWidget {
  final Speaker info;
  const ScheduleDetail({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(info.type),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          CardSchedule(
            info: info,
            showTitle: true,
          ),
          if (info.type == "Taller")
            ButtonWorkshop(
              uuid: info.uuid,
              info: info,
            ),
          const SizedBox(height: 20),
          const Text(
            'Descripción',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(info.description),
          const SizedBox(height: 20),
          const Text(
            'Acerca de mi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(info.aboutMe),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var item in info.socialNetwork)
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
          )
        ],
      ),
    );
  }
}

class ButtonWorkshop extends StatefulWidget {
  final Speaker info;
  final String uuid;
  const ButtonWorkshop({Key? key, required this.uuid, required this.info})
      : super(key: key);

  @override
  State<ButtonWorkshop> createState() => _ButtonWorkshopState();
}

class _ButtonWorkshopState extends State<ButtonWorkshop> {
  StreamSubscription? _sub;
  bool loading = true;
  bool showMs = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final data = Provider.of<DataCenter>(context, listen: false);
      data.currentSpeaker = null;
      _sub = data.speakerStream(widget.uuid).listen((event) {
        if (event.data() != null) {
          data.currentSpeaker = Speaker.fromJson(event.data()!);
          if (data.currentSpeaker?.current == data.currentSpeaker?.limit) {
            _sub?.cancel();
          }
        }
      });
      var res = await data.searchUserInWorkShop(widget.uuid);
      if (res) {
        setState(() {
          loading = false;
          showMs = true;
        });
      } else {
        setState(() {
          loading = false;
          showMs = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataCenter>(context);

    if (loading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: Colors.white,
          size: 20,
        ),
      );
    }
    print(DateTime.parse(widget.info.openDate!)
        .difference(DateTime.now())
        .inSeconds);
    if ((DateTime.tryParse(widget.info.openDate!)
                ?.difference(DateTime.now())
                .inSeconds ??
            0) >
        0) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppStyles.colorBaseYellow,
              borderRadius: BorderRadius.circular(15)),
          child: Text(
            " Las inscripciones estarán disponibles desde el \n ${dateformat.format(DateTime.tryParse(widget.info.openDate!)!)}",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (showMs) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          " 😊 Te esperamos en el Taller 💻",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: AppStyles.colorBaseBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if ((data.currentSpeaker?.current ?? 0) >=
            (data.currentSpeaker?.limit ?? -1))
          const Text(
            "⚠️ Entradas agotadas",
            style: TextStyle(fontSize: 18, color: AppStyles.colorBaseRed),
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.dock_outlined),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                side: const BorderSide(),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              await data.addWorkshop(widget.uuid);
              setState(() {
                showMs = true;
              });
            },
            label: const Text("Obtener un cupo"),
          ),
        Text(
          "${data.currentSpeaker?.current}/${data.currentSpeaker?.limit}",
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
