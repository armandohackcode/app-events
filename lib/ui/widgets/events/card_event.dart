import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/ui/screens/schedule/schedule_screen.dart';
import 'package:app_events/ui/widgets/shared/event_status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

final _dateFmt = DateFormat('dd MMM yyyy', 'es');

class CardEvent extends StatelessWidget {
  final Event event;
  const CardEvent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute(builder: (_) => ScheduleScreen(event: event)),
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppStyles.cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl.isNotEmpty)
                Hero(
                  tag: 'event_image_${event.id}',
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    placeholder: (ctx, url) => Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppStyles.borderColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: LoadingAnimationWidget.twistingDots(
                          leftDotColor: AppStyles.colorBaseBlue,
                          rightDotColor: AppStyles.colorBaseYellow,
                          size: 32,
                        ),
                      ),
                    ),
                    errorWidget: (ctx, url, err) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.fontColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        EventStatusBadge(status: event.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppStyles.fontSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: AppStyles.fontSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_dateFmt.format(event.startDate)} — ${_dateFmt.format(event.endDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppStyles.fontSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          AppStrings.eventViewSchedule,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppStyles.colorBaseBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 11,
                          color: AppStyles.colorBaseBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
