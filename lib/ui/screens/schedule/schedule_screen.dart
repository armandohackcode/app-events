import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/schedule/schedule_detail.dart';
import 'package:app_events/ui/widgets/events/edit_event.dart';
import 'package:app_events/ui/widgets/schedule_screen/add_schedule.dart';
import 'package:app_events/ui/widgets/schedule_screen/card_schedule.dart';
import 'package:app_events/ui/widgets/shared/event_status_badge.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

final _dateFmt = DateFormat('dd MMM yyyy', 'es');

class ScheduleScreen extends StatefulWidget {
  final Event event;
  const ScheduleScreen({super.key, required this.event});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const double _expandedHeight = 260.0;
  // Threshold at which the AppBar is considered fully collapsed
  static const double _collapseThreshold = _expandedHeight - kToolbarHeight;

  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScheduleProvider>(
        context,
        listen: false,
      ).loadSchedule(widget.event.id);
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset.clamp(0.0, _collapseThreshold);
    if (offset != _scrollOffset) setState(() => _scrollOffset = offset);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final schedule = Provider.of<ScheduleProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final event = widget.event;
    final isAdmin = user.isAdmin;
    final hasJoined = user.userCompetitor?.currentEventId == event.id;
    final canJoin =
        event.status == EventStatus.active &&
        !hasJoined &&
        user.userCompetitor != null;

    // 0.0 = fully expanded (image visible), 1.0 = fully collapsed (solid bar)
    final t = event.imageUrl.isNotEmpty
        ? (_scrollOffset / _collapseThreshold).clamp(0.0, 1.0)
        : 1.0;

    final appBarBg = Color.lerp(Colors.transparent, AppStyles.colorAppbar, t)!;
    final fgColor = Color.lerp(Colors.white, AppStyles.fontColor, t)!;

    return Scaffold(
      floatingActionButton: canJoin
          ? FloatingActionButton.extended(
              backgroundColor: AppStyles.colorBaseGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow),
              label: const Text(AppStrings.eventJoin),
              onPressed: () async {
                await user.joinEvent(event.id);
                if (context.mounted) {
                  customSnackbar(
                    context,
                    '${AppStrings.eventJoinSuccess}${event.title}!',
                  );
                }
              },
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => schedule.loadSchedule(event.id),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              expandedHeight: event.imageUrl.isNotEmpty
                  ? _expandedHeight
                  : null,
              pinned: true,
              backgroundColor: appBarBg,
              foregroundColor: fgColor,
              titleTextStyle: TextStyle(
                color: fgColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'GoogleSans',
              ),
              title: Opacity(
                opacity: ((t - 0.4) / 0.6).clamp(0.0, 1.0),
                child: Text(event.title),
              ),
              actions: [
                if (isAdmin) ...[
                  IconButton(
                    tooltip: AppStrings.eventEdit,
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => EditEvent(event: event),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 22),
                  ),
                  IconButton(
                    tooltip: AppStrings.scheduleAddSpeakerOrActivity,
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => AddSchedule(eventId: event.id),
                      ),
                    ),
                    icon: const Icon(Icons.person_add, size: 24),
                  ),
                ],
              ],
              flexibleSpace: event.imageUrl.isNotEmpty
                  ? FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'event_image_${event.id}',
                            child: CachedNetworkImage(
                              imageUrl: event.imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (ctx, url) => ColoredBox(
                                color: AppStyles.borderColor,
                                child: Center(
                                  child: LoadingAnimationWidget.twistingDots(
                                    leftDotColor: AppStyles.colorBaseBlue,
                                    rightDotColor: AppStyles.colorBaseYellow,
                                    size: 36,
                                  ),
                                ),
                              ),
                              errorWidget: (ctx, url, err) => const ColoredBox(
                                color: AppStyles.backgroundColor,
                              ),
                            ),
                          ),
                          // Top gradient → icons always readable regardless of image color
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment(0, 0.45),
                                colors: [Color(0x99000000), Colors.transparent],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),

            // Event info section
            SliverToBoxAdapter(
              child: _EventInfoSection(
                event: event,
                user: user,
                eventProvider: eventProvider,
                hasJoined: hasJoined,
                collapseT: t,
              ),
            ),

            // Schedule section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 4, 15, 10),
                child: Text(
                  AppStrings.scheduleSchedule,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
            ),

            // Speaker list
            if (schedule.loadingSchedule)
              SliverFillRemaining(
                child: Center(
                  child: LoadingAnimationWidget.twistingDots(
                    leftDotColor: AppStyles.colorBaseBlue,
                    rightDotColor: AppStyles.colorBaseYellow,
                    size: 40,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = schedule.schedule[index];
                    if (item.type == EventTypeSpeaker.panel.value) {
                      return ZoomIn(child: _PanelItem(item: item));
                    }
                    return ZoomIn(
                      child: CardSchedule(
                        info: item,
                        onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) =>
                                ScheduleDetail(eventId: event.id, info: item),
                          ),
                        ),
                      ),
                    );
                  }, childCount: schedule.schedule.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event info section
// ---------------------------------------------------------------------------

class _EventInfoSection extends StatelessWidget {
  final Event event;
  final UserProvider user;
  final EventProvider eventProvider;
  final bool hasJoined;
  final double collapseT;

  const _EventInfoSection({
    required this.event,
    required this.user,
    required this.eventProvider,
    required this.hasJoined,
    required this.collapseT,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: (1 - collapseT / 0.6).clamp(0.0, 1.0),
            child: Text(
              event.title,
              style: const TextStyle(
                color: AppStyles.fontColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              EventStatusBadge(status: event.status),
              const Spacer(),
              if (user.isAdmin)
                _AdminStatusMenu(event: event, eventProvider: eventProvider),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: const TextStyle(
              color: AppStyles.fontSecondaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 15,
                color: AppStyles.fontSecondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                '${_dateFmt.format(event.startDate)} — ${_dateFmt.format(event.endDate)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
          if (event.locationUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => laucherUrlInfo(event.locationUrl),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 15,
                    color: AppStyles.colorBaseBlue,
                  ),
                  SizedBox(width: 6),
                  Text(
                    AppStrings.eventViewLocation,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppStyles.colorBaseBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (event.status == EventStatus.active &&
              user.userCompetitor != null &&
              hasJoined) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppStyles.colorBaseGreen,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.eventAlreadyJoined,
                  style: const TextStyle(
                    color: AppStyles.colorBaseGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Divider(color: AppStyles.borderColor),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Admin: status change popup (separate from edit button in AppBar)
// ---------------------------------------------------------------------------

class _AdminStatusMenu extends StatelessWidget {
  final Event event;
  final EventProvider eventProvider;
  const _AdminStatusMenu({required this.event, required this.eventProvider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EventStatus>(
      color: AppStyles.colorAppbar,
      icon: const Icon(Icons.more_vert, color: AppStyles.fontColor),
      onSelected: (status) async {
        await eventProvider.updateEventStatus(event.id, status);
      },
      itemBuilder: (_) => EventStatus.values
          .where((s) => s != event.status)
          .map(
            (s) => PopupMenuItem(
              value: s,
              child: Text(switch (s) {
                EventStatus.upcoming => AppStrings.eventAdminMarkUpcoming,
                EventStatus.active => AppStrings.eventAdminActivate,
                EventStatus.finished => AppStrings.eventAdminClose,
              }, style: const TextStyle(color: AppStyles.fontColor)),
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Panel item (non-speaker schedule entry)
// ---------------------------------------------------------------------------

class _PanelItem extends StatelessWidget {
  final Speaker item;
  const _PanelItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppStyles.colorBaseBlue,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppStyles.fontColor, width: 1.5),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
