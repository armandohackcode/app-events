import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/schedule_screen/card_schedule.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class ScheduleDetail extends StatelessWidget {
  final String eventId;
  final Speaker info;
  const ScheduleDetail({super.key, required this.eventId, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(info.type)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          CardSchedule(info: info, showTitle: true, action: false),
          if (info.type == "Taller")
            ButtonWorkshop(eventId: eventId, uuid: info.uuid, info: info),
          const SizedBox(height: 20),
          const Text(
            AppStrings.scheduleDescription,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(info.description),
          const SizedBox(height: 20),
          const Text(
            AppStrings.scheduleAboutMe,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(info.aboutMe),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var item in info.socialNetwork)
                InkWell(
                  child: SvgPicture.asset(getSVG(item), width: 60, height: 40),
                  onTap: () async => laucherUrlInfo(item.link),
                ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class ButtonWorkshop extends StatefulWidget {
  final String eventId;
  final Speaker info;
  final String uuid;
  const ButtonWorkshop({
    super.key,
    required this.eventId,
    required this.uuid,
    required this.info,
  });

  @override
  State<ButtonWorkshop> createState() => _ButtonWorkshopState();
}

class _ButtonWorkshopState extends State<ButtonWorkshop> {
  StreamSubscription? _sub;
  bool loading = true;
  bool showMs = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scheduleProvider =
          Provider.of<ScheduleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      scheduleProvider.currentSpeaker = null;
      _sub = scheduleProvider
          .speakerStream(widget.eventId, widget.uuid)
          .listen((speaker) {
        if (speaker != null) {
          scheduleProvider.currentSpeaker = speaker;
          if (scheduleProvider.currentSpeaker?.current ==
              scheduleProvider.currentSpeaker?.limit) {
            _sub?.cancel();
          }
        }
      });

      final alreadyRegistered = await userProvider.searchUserInWorkshop(
        widget.eventId,
        widget.uuid,
      );
      setState(() {
        loading = false;
        showMs = alreadyRegistered;
      });
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
    final scheduleProvider = Provider.of<ScheduleProvider>(context);

    if (loading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: AppStyles.colorBaseBlue,
          size: 20,
        ),
      );
    }

    if ((DateTime.tryParse(widget.info.openDate ?? '')
                ?.difference(DateTime.now())
                .inSeconds ??
            0) >
        0) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppStyles.colorBaseYellow,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '${AppStrings.scheduleRegistrationOpen}\n${dateformat.format(DateTime.tryParse(widget.info.openDate!)!)}',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (showMs) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          AppStrings.scheduleMessageWorkshopRegistered,
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
        if ((scheduleProvider.currentSpeaker?.current ?? 0) >=
            (scheduleProvider.currentSpeaker?.limit ?? -1))
          const Text(
            AppStrings.scheduleSoldOut,
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
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              final ok =
                  await userProvider.addWorkshop(widget.eventId, widget.uuid);
              if (ok) setState(() => showMs = true);
            },
            label: const Text(AppStrings.scheduleRegisterNow),
          ),
        Text(
          '${scheduleProvider.currentSpeaker?.current}/${scheduleProvider.currentSpeaker?.limit}',
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
