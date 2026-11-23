import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/widgets/shared/social_circle_button.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// User social network links and personal QR access row for the profile screen.
class ProfileSocialAndQrSection extends StatelessWidget {
  final List<SocialNetwork> socialNetworks;
  final VoidCallback? onOpenQr;

  const ProfileSocialAndQrSection({
    super.key,
    required this.socialNetworks,
    required this.onOpenQr,
  });

  @override
  Widget build(BuildContext context) {
    final visibleNetworks = socialNetworks
        .where((item) => item.link.trim().isNotEmpty)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.profileSocialLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
              const SizedBox(height: 8),
              if (visibleNetworks.isEmpty)
                const Text(
                  AppStrings.profileNoSocialLinks,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppStyles.fontSecondaryColor,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    for (final item in visibleNetworks)
                      SocialCircleButton(
                        color: getSocialColor(item),
                        glyph: getSocialGlyph(item),
                        tooltip: getSocialLabel(item),
                        size: 36,
                        glyphSize: 17,
                        borderWidth: 1.5,
                        onTap: () => launcherUrlInfo(item.link),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Opacity(
          opacity: onOpenQr != null ? 1.0 : 0.45,
          child: InkWell(
            onTap: onOpenQr,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2, size: 18, color: AppStyles.fontColor),
                    SizedBox(width: 5),
                    Text(
                      AppStrings.profileQrAction,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
