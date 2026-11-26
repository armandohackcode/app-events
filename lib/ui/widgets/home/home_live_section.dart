import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/live_activity_provider.dart';
import 'package:app_events/ui/screens/schedule/schedule_detail.dart';
import 'package:app_events/ui/widgets/home/live_talk_card.dart';
import 'package:app_events/ui/widgets/home/question_box.dart';
import 'package:app_events/ui/widgets/shared/window_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

/// Live activity section of the home screen, kept up to date with the
/// activity marked as live in the active event.
class HomeLiveSection extends StatefulWidget {
  const HomeLiveSection({super.key});

  @override
  State<HomeLiveSection> createState() => _HomeLiveSectionState();
}

class _HomeLiveSectionState extends State<HomeLiveSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LiveActivityProvider>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveActivityProvider>();
    final activity = live.activity;
    final eventId = live.eventId;
    if (activity == null || eventId == null) {
      return _LiveStatusCard(loading: live.loading);
    }
    final speakerName = activity.name.trim().split(' ').first;
    final isGeneral = EventTypeSpeaker.fromValue(
      activity.type,
    ).isGeneralActivity;
    return LiveTalkCard(
      talk: activity,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => ScheduleDetail(eventId: eventId, info: activity),
        ),
      ),
      footer: isGeneral || speakerName.isEmpty
          ? null
          : QuestionBox(speakerName: speakerName),
    );
  }
}

/// What the section shows while there is no live activity to present.
class _LiveStatusCard extends StatelessWidget {
  final bool loading;
  const _LiveStatusCard({required this.loading});

  @override
  Widget build(BuildContext context) {
    return WindowCard(
      title: AppStrings.homeLiveWindowTitle,
      child: SizedBox(
        height: 120,
        child: Center(
          child: loading
              ? LoadingAnimationWidget.twistingDots(
                  leftDotColor: AppStyles.colorBaseBlue,
                  rightDotColor: AppStyles.colorBaseYellow,
                  size: 32,
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.podcasts_rounded,
                      size: 40,
                      color: AppStyles.fontFaintColor,
                    ),
                    SizedBox(height: 10),
                    Text(
                      AppStrings.homeLiveEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
