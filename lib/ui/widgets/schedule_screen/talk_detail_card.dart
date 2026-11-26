import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/time_and_tags.dart';
import 'package:flutter/material.dart';

/// Main card of a talk detail: the speaker photo, then the schedule with the
/// technology and activity tags, the title, and the speaker with their
/// profession.
class TalkDetailCard extends StatelessWidget {
  final Speaker info;
  final ImageProvider photo;

  const TalkDetailCard({super.key, required this.info, required this.photo});

  static const double _radius = 20;
  static const double _borderWidth = 2.5;

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      radius: _radius,
      shadowOffset: 5,
      borderWidth: _borderWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - _borderWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Photo(photo: photo),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TimeAndTags(
                    schedule: info.schedule,
                    technologyType: info.technologyType,
                    type: info.type,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    info.title,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  if (info.name.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(height: 2, color: AppStyles.dividerColor),
                    const SizedBox(height: 14),
                    _Speaker(info: info),
                  ],
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
  final ImageProvider photo;
  const _Photo({required this.photo});

  static const double _height = 230;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppStyles.borderColor, width: 2),
        ),
      ),
      child: FadeInImage(
        placeholder: const AssetImage(AppAssetsPath.loadingSmallImage),
        image: photo,
        fit: BoxFit.cover,
        imageErrorBuilder: (_, _, _) =>
            const ColoredBox(color: AppStyles.placeholderColor),
      ),
    );
  }
}

class _Speaker extends StatelessWidget {
  final Speaker info;
  const _Speaker({required this.info});

  /// Parts of the profession, split where it uses " · ".
  static List<String> _parts(String profession) => profession
      .split('·')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final parts = _parts(info.profession);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppStyles.colorBaseYellow,
                shape: BoxShape.circle,
                border: Border.all(color: AppStyles.borderColor, width: 2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                info.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppStyles.fontColor,
                ),
              ),
            ),
          ],
        ),
        if (parts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 24),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: parts.first,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppStyles.colorBaseBlue,
                    ),
                  ),
                  if (parts.length > 1)
                    TextSpan(text: ' · ${parts.skip(1).join(' · ')}'),
                ],
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
          ),
      ],
    );
  }
}
