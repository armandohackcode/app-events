import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Main card of a talk detail: the speaker photo with the technology and
/// activity tags on top, then the title, the speaker and their profession.
class TalkDetailCard extends StatelessWidget {
  final Speaker info;
  final ImageProvider photo;

  const TalkDetailCard({super.key, required this.info, required this.photo});

  static const double _radius = 16;
  static const double _borderWidth = 2.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        border: Border.all(color: AppStyles.borderColor, width: _borderWidth),
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(color: AppStyles.borderColor, offset: Offset(5, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - _borderWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Photo(info: info, photo: photo),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                      letterSpacing: -0.2,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppStyles.colorBaseYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          info.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.fontColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (info.profession.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 12),
                      child: Text(
                        info.profession,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final Speaker info;
  final ImageProvider photo;
  const _Photo({required this.info, required this.photo});

  static const double _height = 215;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeInImage(
            placeholder: const AssetImage(AppAssetsPath.loadingSmallImage),
            image: photo,
            fit: BoxFit.cover,
            imageErrorBuilder: (_, _, _) =>
                const ColoredBox(color: AppStyles.placeholderColor),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppStyles.imageFadeColor],
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Align(
              alignment: Alignment.centerRight,
              child: _Tags(info: info),
            ),
          ),
        ],
      ),
    );
  }
}

/// Technology and activity tags, glued to the top-right corner of the photo.
class _Tags extends StatelessWidget {
  final Speaker info;
  const _Tags({required this.info});

  @override
  Widget build(BuildContext context) {
    final activity = [info.type, info.schedule].where((e) => e.isNotEmpty);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The activity tag, which carries the schedule, gets most of the width.
        if (info.technologyType.isNotEmpty)
          Flexible(
            child: _Tag(
              text: info.technologyType,
              color: technologyColor(info.technologyType),
              textColor: AppStyles.fontColor,
              weight: FontWeight.w700,
            ),
          ),
        if (activity.isNotEmpty)
          Flexible(
            flex: 3,
            child: _Tag(
              text: activity.join(' | '),
              color: AppStyles.colorBaseRed,
              textColor: AppStyles.onAccentColor,
              weight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final FontWeight weight;

  const _Tag({
    required this.text,
    required this.color,
    required this.textColor,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          left: BorderSide(color: AppStyles.borderColor, width: 1.5),
          right: BorderSide(color: AppStyles.borderColor, width: 1.5),
          bottom: BorderSide(color: AppStyles.borderColor, width: 1.5),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, fontWeight: weight, color: textColor),
      ),
    );
  }
}
