import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/initials_avatar.dart';
import 'package:flutter/material.dart';

/// Main profile summary card showing identity, bio, membership age, and stats.
class ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String email;
  final DateTime? memberSince;
  final String avatarUrl;
  final UserCompetitor? competitor;
  final int eventsCount;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  const ProfileHeaderCard({
    super.key,
    required this.displayName,
    required this.email,
    required this.memberSince,
    required this.avatarUrl,
    required this.competitor,
    required this.eventsCount,
    required this.onEdit,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final profession = competitor?.profession.trim() ?? '';
    final aboutMe = competitor?.aboutMe.trim() ?? '';
    final memberSinceText = memberSince != null
        ? AppStrings.profileMemberSinceYear(memberSince!.year)
        : AppStrings.profileMemberSinceUnknown;

    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 20,
      shadowOffset: 4,
      borderWidth: 2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InitialsAvatar(
                name: displayName,
                photoUrl: avatarUrl,
                backgroundColor: AppStyles.colorCardYellow,
                foregroundColor: AppStyles.fontColor,
                size: 62,
                borderWidth: 2,
                fallbackAsset: AppAssetsPath.firePedIcon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.fontColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isNotEmpty
                          ? email
                          : AppStrings.profileEmailUnavailable,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: email.isNotEmpty
                            ? AppStyles.fontSecondaryColor
                            : AppStyles.fontFaintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profession.isNotEmpty
                          ? profession
                          : AppStrings.profileProfessionUnavailable,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: profession.isNotEmpty
                            ? AppStyles.fontSecondaryColor
                            : AppStyles.fontFaintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ChunkyButton(
                  label: AppStrings.profileEditProfile,
                  color: AppStyles.cardColor,
                  onPressed: onEdit,
                  expand: true,
                  radius: 999,
                  minHeight: 40,
                  minTapHeight: 44,
                  fontSize: 12.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChunkyButton(
                  label: AppStrings.commonWordShare,
                  color: AppStyles.colorBaseYellow,
                  onPressed: onShare,
                  expand: true,
                  radius: 999,
                  minHeight: 40,
                  minTapHeight: 44,
                  fontSize: 12.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            aboutMe.isNotEmpty ? aboutMe : AppStrings.profileMsEditProfile,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.38,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppStyles.colorCardYellow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppStyles.borderColor, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13.5,
                    color: AppStyles.fontColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      memberSinceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: competitor?.score ?? 0,
                  label: AppStrings.commonWordPoints,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: competitor?.friends.length ?? 0,
                  label: AppStrings.profileFriendsStat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: eventsCount,
                  label: AppStrings.eventsTitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyles.borderColor, width: 1.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1,
                color: AppStyles.fontColor,
              ),
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
