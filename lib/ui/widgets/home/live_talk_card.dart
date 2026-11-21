import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/social_links_bar.dart';
import 'package:app_events/ui/widgets/shared/window_card.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Card of the talk that is happening right now: title, speaker photo, name,
/// profession and social links. Tapping the talk calls [onTap]; the social
/// buttons open their own link. The photo comes from [photo] when given,
/// otherwise from the talk's photo URL.
class LiveTalkCard extends StatelessWidget {
  final Speaker talk;
  final VoidCallback onTap;
  final ImageProvider? photo;

  /// Extra content shown below the social links.
  final Widget? footer;

  const LiveTalkCard({
    super.key,
    required this.talk,
    required this.onTap,
    this.photo,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
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
                    talk.title,
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
                _TalkPhoto(talk: talk, photo: photo),
                const SizedBox(height: 14),
                Text(
                  talk.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppStyles.fontColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  talk.profession,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
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
  final ImageProvider? photo;
  const _TalkPhoto({required this.talk, this.photo});

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
              child: _Photo(url: talk.photoUrl, image: photo),
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
          const Positioned(top: -10, right: -18, child: _LiveBadge()),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String url;
  final ImageProvider? image;
  const _Photo({required this.url, this.image});

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
    if (image != null) {
      return Image(
        image: image!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
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

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 20 * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppStyles.colorBaseRed,
          border: Border.all(color: AppStyles.borderColor, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 7,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppStyles.onAccentColor,
                ),
              ),
            ),
            SizedBox(width: 5),
            Text(
              AppStrings.homeLiveBadge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppStyles.onAccentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
