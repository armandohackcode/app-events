import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_links.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/social_circle_button.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Card with the community's channels (WhatsApp, Instagram, Discord, TikTok)
/// as round buttons with a label under each one.
class ChannelsCard extends StatelessWidget {
  const ChannelsCard({super.key});

  static const List<_Channel> _channels = [
    _Channel(
      label: AppStrings.homeChannelWhatsApp,
      color: AppStyles.socialWhatsAppColor,
      glyph: AppAssetsPath.glyphWhatsApp,
      link: AppLinks.gdgWhatsApp,
    ),
    _Channel(
      label: AppStrings.homeChannelInstagram,
      color: AppStyles.socialInstagramColor,
      glyph: AppAssetsPath.glyphInstagram,
      link: AppLinks.gdgInstagram,
    ),
    _Channel(
      label: AppStrings.homeChannelDiscord,
      color: AppStyles.socialDiscordColor,
      glyph: AppAssetsPath.glyphDiscord,
      link: AppLinks.gdgDiscord,
    ),
    _Channel(
      label: AppStrings.homeChannelTikTok,
      color: AppStyles.socialTikTokColor,
      glyph: AppAssetsPath.glyphTikTok,
      link: AppLinks.gdgTikTok,
    ),
    _Channel(
      label: AppStrings.homeChannelWeb,
      color: AppStyles.socialWebColor,
      glyph: AppAssetsPath.glyphWeb,
      link: AppLinks.gdgCommunity,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        border: Border.all(color: AppStyles.borderColor, width: 2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppStyles.borderColor, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            AppStrings.homeChannelsTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppStyles.fontColor,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            AppStrings.homeChannelsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Scales down instead of overflowing on narrow screens.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _channels.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  _ChannelButton(channel: _channels[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Channel {
  final String label;
  final Color color;
  final String glyph;
  final String link;

  const _Channel({
    required this.label,
    required this.color,
    required this.glyph,
    required this.link,
  });
}

class _ChannelButton extends StatelessWidget {
  final _Channel channel;
  const _ChannelButton({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialCircleButton(
          color: channel.color,
          glyph: channel.glyph,
          tooltip: channel.label,
          onTap: () => launcherUrlInfo(channel.link),
          size: 54,
          glyphSize: 24,
          borderWidth: 2.5,
          hardShadow: true,
        ),
        const SizedBox(height: 7),
        Text(
          channel.label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppStyles.fontSecondaryColor,
          ),
        ),
      ],
    );
  }
}
