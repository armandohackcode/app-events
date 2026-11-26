import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/live_badge.dart';
import 'package:app_events/ui/widgets/shared/social_links_bar.dart';
import 'package:app_events/ui/widgets/shared/window_card.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Card of the activity that is happening right now. It shows the data the
/// activity has: title, speaker photo, name, profession and social links; a
/// break or lunch shows its icon and description instead of a speaker.
/// Tapping the activity calls [onTap]; the social buttons open their own link.
class LiveTalkCard extends StatelessWidget {
  final Speaker talk;
  final VoidCallback onTap;

  /// Extra content shown below the social links.
  final Widget? footer;

  const LiveTalkCard({
    super.key,
    required this.talk,
    required this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isGeneral = EventTypeSpeaker.fromValue(talk.type).isGeneralActivity;
    final detail = isGeneral ? talk.description : talk.profession;
    return WindowCard(
      title: AppStrings.homeLiveWindowTitle,
      trailing: talk.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    talk.title.isEmpty ? eventTypeLabel(talk.type) : talk.title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _TalkPhoto(talk: talk, isGeneral: isGeneral),
                if (!isGeneral && talk.name.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    talk.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ],
                if (detail.isNotEmpty) ...[
                  // Without a name above, leave room for the photo shadow.
                  SizedBox(height: !isGeneral && talk.name.isNotEmpty ? 2 : 14),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (talk.socialNetwork.isNotEmpty) ...[
            const SizedBox(height: 14),
            SocialLinksBar(networks: talk.socialNetwork),
          ],
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

class _TalkPhoto extends StatelessWidget {
  final Speaker talk;
  final bool isGeneral;
  const _TalkPhoto({required this.talk, required this.isGeneral});

  static const double _width = 177;
  static const double _height = 139;
  static const double _borderWidth = 3.5;
  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -2 * math.pi / 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _width,
            height: _height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(
                color: AppStyles.borderColor,
                width: _borderWidth,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppStyles.colorBaseYellow,
                  offset: Offset(6, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius - _borderWidth),
              child: isGeneral
                  ? _ActivityIcon(type: talk.type)
                  : _Photo(url: talk.photoUrl),
            ),
          ),
          if (talk.technologyType.isNotEmpty)
            // Both sides are bounded so a long area name is cut with an ellipsis
            // instead of overflowing the photo.
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TechnologyTag(area: talk.technologyType),
              ),
            ),
          const Positioned(top: -10, right: -18, child: LiveBadge()),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String url;
  const _Photo({required this.url});

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: AppStyles.placeholderColor,
      child: Center(
        child: Icon(
          Icons.person,
          size: 56,
          color: AppStyles.fontSecondaryColor,
        ),
      ),
    );
    if (url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

/// Large icon of an activity that has no speaker photo.
class _ActivityIcon extends StatelessWidget {
  final String type;
  const _ActivityIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppStyles.colorCardBlue,
      child: Center(
        child: Icon(eventTypeIcon(type), size: 56, color: AppStyles.fontColor),
      ),
    );
  }
}

class _TechnologyTag extends StatelessWidget {
  final String area;
  const _TechnologyTag({required this.area});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: technologyColor(area),
        border: Border.all(color: AppStyles.borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        area,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppStyles.fontColor,
        ),
      ),
    );
  }
}
