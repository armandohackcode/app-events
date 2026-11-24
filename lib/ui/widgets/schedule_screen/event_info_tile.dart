import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Row card of the event header (date, place): a [leading] widget, a title
/// and a subtitle. When [onTap] is given a chevron is shown and the subtitle
/// is drawn as a link.
class EventInfoTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const EventInfoTile({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLink = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: HardShadowBox(
        radius: 20,
        shadowOffset: 4,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isLink ? FontWeight.w700 : FontWeight.w500,
                      color: isLink
                          ? AppStyles.colorBaseBlue
                          : AppStyles.fontSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isLink)
              const Icon(
                Icons.chevron_right_rounded,
                color: AppStyles.fontColor,
              ),
          ],
        ),
      ),
    );
  }
}
