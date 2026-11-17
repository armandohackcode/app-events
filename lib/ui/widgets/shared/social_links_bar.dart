import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/social_circle_button.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Row of social network buttons that adapts to how many links there are:
/// three or more are round buttons framed by decorative brackets, two share
/// the width as oval buttons, and a single one fills the whole width.
/// Networks without a link are skipped.
class SocialLinksBar extends StatelessWidget {
  final List<SocialNetwork> networks;
  const SocialLinksBar({super.key, required this.networks});

  @override
  Widget build(BuildContext context) {
    final items = networks.where((n) => n.link.trim().isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    if (items.length >= 3) {
      // Scales down instead of overflowing when there are many networks.
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Bracket(mirrored: true),
            const SizedBox(width: 4),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              SocialCircleButton(
                color: getSocialColor(items[i]),
                glyph: getSocialGlyph(items[i]),
                tooltip: getSocialLabel(items[i]),
                onTap: () => launcherUrlInfo(items[i].link),
              ),
            ],
            const SizedBox(width: 4),
            const _Bracket(),
          ],
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _SocialOval(item: items[i])),
        ],
      ],
    );
  }
}

class _Bracket extends StatelessWidget {
  final bool mirrored;
  const _Bracket({this.mirrored = false});

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: mirrored,
      child: SvgPicture.asset(
        AppAssetsPath.socialBrackets,
        width: 20,
        height: 24,
        colorFilter: const ColorFilter.mode(
          AppStyles.fontColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _SocialOval extends StatelessWidget {
  final SocialNetwork item;
  const _SocialOval({required this.item});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: getSocialLabel(item),
      child: Material(
        color: getSocialColor(item),
        shape: const StadiumBorder(
          side: BorderSide(color: AppStyles.borderColor, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => launcherUrlInfo(item.link),
          child: SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  getSocialGlyph(item),
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppStyles.onAccentColor,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    getSocialLabel(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppStyles.onAccentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
