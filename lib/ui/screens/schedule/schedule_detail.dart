import 'dart:async';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/talk_interaction_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/home/question_box.dart';
import 'package:app_events/ui/widgets/schedule_screen/edit_schedule.dart';
import 'package:app_events/ui/widgets/schedule_screen/talk_detail_card.dart';
import 'package:app_events/ui/widgets/schedule_screen/talk_rating_card.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/social_links_bar.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
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

  Future<void> _openAskSpeakerDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _AskSpeakerDialog(eventId: eventId, speakerUuid: info.uuid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = maybeProvider<UserProvider>(context, listen: false);
    final authProvider = maybeProvider<SignInSocialNetworkProvider>(
      context,
      listen: false,
    );
    final talkProvider = maybeProvider<TalkInteractionProvider>(
      context,
      listen: false,
    );
    final isAdmin = userProvider?.isAdmin ?? false;
    final authUid = (authProvider != null && authProvider.isAuth)
        ? authProvider.userInfo.uid
        : null;
    final uid = (authUid != null && authUid.isNotEmpty)
        ? authUid
        : userProvider?.userCompetitor?.uuid;
    final canInteract = info.uuid.isNotEmpty && talkProvider != null;

    return Scaffold(
      backgroundColor: AppStyles.homeBackgroundColor,
      appBar: AppBar(
        title: Text(eventTypeLabel(info.type)),
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
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TalkDetailCard(
                        info: info,
                        photo: CachedNetworkImageProvider(info.photoUrl),
                      ),
                      if (info.type == "Taller") ...[
                        const SizedBox(height: 16),
                        ButtonWorkshop(
                          eventId: eventId,
                          uuid: info.uuid,
                          info: info,
                        ),
                      ],
                      if (info.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _TextSection(
                          tag: AppStrings.scheduleWhatIsItAbout,
                          tagColor: AppStyles.colorBaseYellow,
                          angle: -2,
                          text: info.description,
                        ),
                      ],
                      if (info.aboutMe.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _TextSection(
                          tag: AppStrings.scheduleWhoTellsIt,
                          tagColor: AppStyles.titlePillColor,
                          angle: 2,
                          color: AppStyles.colorCardBlue,
                          text: info.aboutMe,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SocialLinksBar(networks: info.socialNetwork),
                      if (canInteract) ...[
                        const SizedBox(height: 24),
                        TalkRatingCard(
                          eventId: eventId,
                          speakerUuid: info.uuid,
                          uid: uid,
                        ),
                        const SizedBox(height: 16),
                        ChunkyButton(
                          label: AppStrings.talkAskSpeakerAction,
                          color: AppStyles.colorCardBlue,
                          expand: true,
                          icon: const Icon(
                            Icons.question_answer_outlined,
                            size: 18,
                            color: AppStyles.fontColor,
                          ),
                          onPressed: () =>
                              unawaited(_openAskSpeakerDialog(context)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AskSpeakerDialog extends StatefulWidget {
  final String eventId;
  final String speakerUuid;

  const _AskSpeakerDialog({required this.eventId, required this.speakerUuid});

  @override
  State<_AskSpeakerDialog> createState() => _AskSpeakerDialogState();
}

class _AskSpeakerDialogState extends State<_AskSpeakerDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _submitting = true);
    try {
      final ok = await submitTalkQuestionWithFeedback(
        context,
        eventId: widget.eventId,
        speakerUuid: widget.speakerUuid,
        rawText: _controller.text,
      );
      if (ok && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: HardShadowBox(
                  color: AppStyles.cardColor,
                  radius: 22,
                  shadowOffset: 5,
                  borderWidth: 2.5,
                  padding: const EdgeInsets.fromLTRB(18, 28, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _controller,
                        enabled: !_submitting,
                        maxLength: 300,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: AppStrings.talkAskSpeakerHint,
                          counterText: '',
                          filled: true,
                          fillColor: AppStyles.gamesBackgroundColor,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppStyles.borderColor,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppStyles.borderColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChunkyButton(
                              label: AppStrings.commonWordCancel,
                              color: AppStyles.cardColor,
                              minHeight: 44,
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChunkyButton(
                              label: AppStrings.talkAskSpeakerSend,
                              color: AppStyles.colorBaseYellow,
                              minHeight: 44,
                              onPressed: _submitting
                                  ? null
                                  : () => unawaited(_send()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: TiltedTag(
                    text: AppStrings.talkAskSpeakerTitle,
                    color: AppStyles.colorBaseYellow,
                    angleDegrees: -1.5,
                    compact: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card with a tilted tag over its top edge and a block of text inside.
class _TextSection extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final double angle;
  final Color color;
  final String text;

  const _TextSection({
    required this.tag,
    required this.tagColor,
    required this.angle,
    required this.text,
    this.color = AppStyles.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return TaggedCard(
      tag: tag,
      tagColor: tagColor,
      angleDegrees: angle,
      compact: true,
      child: HardShadowBox(
        color: color,
        radius: 16,
        shadowOffset: 4,
        padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: AppStyles.fontColor,
            ),
          ),
        ),
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
