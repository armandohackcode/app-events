import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/schedule_screen/edit_schedule.dart';
import 'package:app_events/ui/widgets/schedule_screen/talk_detail_card.dart';
import 'package:app_events/ui/widgets/shared/labeled_card.dart';
import 'package:app_events/ui/widgets/shared/social_links_bar.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class ScheduleDetail extends StatelessWidget {
  final String eventId;
  final Speaker info;
  const ScheduleDetail({super.key, required this.eventId, required this.info});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.scheduleDeleteConfirmTitle),
        content: const Text(AppStrings.scheduleDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.commonWordCancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.colorBaseRed,
              foregroundColor: AppStyles.onAccentColor,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.commonWordDelete),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final scheduleProvider = Provider.of<ScheduleProvider>(
      context,
      listen: false,
    );
    await scheduleProvider.deleteSchedule(eventId, info.uuid);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    customSnackbar(context, AppStrings.scheduleDeleteSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserProvider>(context, listen: false).isAdmin;
    return Scaffold(
      backgroundColor: AppStyles.homeBackgroundColor,
      appBar: AppBar(
        title: Text(info.type),
        actions: [
          if (isAdmin) ...[
            IconButton(
              tooltip: AppStrings.scheduleEditEntry,
              icon: const Icon(Icons.edit_outlined, size: 22),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => EditSchedule(eventId: eventId, info: info),
                ),
              ),
            ),
            IconButton(
              tooltip: AppStrings.scheduleDeleteEntry,
              icon: const Icon(Icons.delete_outline, size: 22),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),

      body: HomeBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 15, 18, 40),
          children: [
            TalkDetailCard(
              info: info,
              photo: CachedNetworkImageProvider(info.photoUrl),
            ),
            if (info.type == "Taller") ...[
              const SizedBox(height: 16),
              ButtonWorkshop(eventId: eventId, uuid: info.uuid, info: info),
            ],
            if (info.description.trim().isNotEmpty) ...[
              const SizedBox(height: 24),
              LabeledCard(
                label: AppStrings.scheduleWhatIsItAbout,
                labelColor: AppStyles.colorBaseYellow,
                labelTextColor: AppStyles.fontColor,
                color: AppStyles.cardColor,
                child: Text(info.description, style: _bodyStyle),
              ),
            ],
            if (info.aboutMe.trim().isNotEmpty) ...[
              const SizedBox(height: 26),
              LabeledCard(
                label: AppStrings.scheduleWhoTellsIt,
                labelColor: AppStyles.colorBaseBlue,
                labelTextColor: AppStyles.onAccentColor,
                color: AppStyles.colorCardBlue,
                speechTail: true,
                labelAngle: 2,
                angle: 0.6,
                child: Text(info.aboutMe, style: _bodyStyle),
              ),
            ],
            const SizedBox(height: 24),
            SocialLinksBar(networks: info.socialNetwork),
          ],
        ),
      ),
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.w500,
    color: AppStyles.fontColor,
  );
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
      final scheduleProvider = Provider.of<ScheduleProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      scheduleProvider.currentSpeaker = null;
      _sub = scheduleProvider.speakerStream(widget.eventId, widget.uuid).listen(
        (speaker) {
          if (speaker != null) {
            scheduleProvider.currentSpeaker = speaker;
            if (scheduleProvider.currentSpeaker?.current ==
                scheduleProvider.currentSpeaker?.limit) {
              _sub?.cancel();
            }
          }
        },
      );

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

    if ((DateTime.tryParse(
              widget.info.openDate ?? '',
            )?.difference(DateTime.now()).inSeconds ??
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
            '${AppStrings.scheduleRegistrationOpen}\n${dateFormat.format(DateTime.tryParse(widget.info.openDate!)!)}',
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
              final userProvider = Provider.of<UserProvider>(
                context,
                listen: false,
              );
              final ok = await userProvider.addWorkshop(
                widget.eventId,
                widget.uuid,
              );
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
