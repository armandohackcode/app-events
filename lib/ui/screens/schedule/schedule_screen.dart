import 'package:animate_do/animate_do.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/schedule_screen/add_schedule.dart';
import 'package:app_events/ui/widgets/schedule_screen/card_schedule.dart';
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
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final schedule = Provider.of<ScheduleProvider>(context, listen: false);
      schedule.loadSchedule();
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final schedule = Provider.of<ScheduleProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.scheduleSchedule,
          // style: TextStyle(color: AppStyles.fontColor),
        ),
        actions: [
          if (user.isAdmin)
            IconButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(CupertinoPageRoute(builder: (_) => const AddSchedule()));
              },
              icon: const Icon(Icons.person_add, size: 32),
            ),
        ],
      ),
      body: (schedule.loadingSchedule)
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
                await schedule.loadSchedule();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: schedule.schedule.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = schedule.schedule[index];
                  if (item.type == EventTypeSpeaker.panel.value) {
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
                              color: AppStyles.backgroundColor,
                            ),
                          ),
                          trailing: Text(
                            item.schedule.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppStyles.backgroundColor,
                            ),
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
