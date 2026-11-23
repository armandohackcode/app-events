import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/widgets/shared/dashed_border_box.dart';
import 'package:app_events/ui/widgets/shared/dot_pattern.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/initials_avatar.dart';
import 'package:app_events/ui/widgets/shared/title_pill.dart';
import 'package:flutter/material.dart';

/// Profile connections grid with header counter, expand toggle, and QR tile.
class ProfileConnectionsSection extends StatelessWidget {
  final List<Friend> friends;
  final bool showAll;
  final int collapsedLimit;
  final VoidCallback onToggleShowAll;
  final ValueChanged<Friend> onOpenFriend;
  final VoidCallback? onOpenQr;

  const ProfileConnectionsSection({
    super.key,
    required this.friends,
    required this.showAll,
    required this.collapsedLimit,
    required this.onToggleShowAll,
    required this.onOpenFriend,
    required this.onOpenQr,
  });

  @override
  Widget build(BuildContext context) {
    final canToggle = friends.length > collapsedLimit;
    final visibleFriends = !canToggle || showAll
        ? friends
        : friends.take(collapsedLimit).toList();

    final tiles = <Widget>[
      for (var i = 0; i < visibleFriends.length; i++)
        _ConnectionCard(
          friend: visibleFriends[i],
          accentColor:
              AppStyles.gdgBrandPalette[i % AppStyles.gdgBrandPalette.length],
          onTap: () => onOpenFriend(visibleFriends[i]),
        ),
      _NewConnectionTile(onTap: onOpenQr),
    ];

    final rows = <List<Widget>>[];
    for (var i = 0; i < tiles.length; i += 3) {
      rows.add(tiles.sublist(i, math.min(i + 3, tiles.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              TitlePill(
                text: AppStrings.commonWordConnections,
                color: AppStyles.colorBaseYellow,
                angle: -1.1,
                fontSize: 12.5,
                borderWidth: 1.8,
                shadowOffset: 2,
                padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppStyles.cardColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    friends.length.toString(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ),
              ),
              if (canToggle)
                InkWell(
                  onTap: onToggleShowAll,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            showAll
                                ? AppStrings.profileSeeLessConnections
                                : AppStrings.profileSeeAllConnections,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppStyles.fontColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppStyles.fontColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (friends.isEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            AppStrings.profileNoConnections,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0) const SizedBox(width: 10),
                  Expanded(
                    child: c < rows[r].length
                        ? rows[r][c]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final Friend friend;
  final Color accentColor;
  final VoidCallback onTap;

  const _ConnectionCard({
    required this.friend,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: HardShadowBox(
        color: AppStyles.cardColor,
        radius: 14,
        shadowOffset: 3,
        borderWidth: 2,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      height: 30,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: accentColor,
                        border: const Border(
                          bottom: BorderSide(
                            color: AppStyles.borderColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: DotPattern(
                        color: AppStyles.onAccentColor.withValues(alpha: 0.32),
                        step: 7,
                        dotRadius: 1.1,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      child: InitialsAvatar(
                        name: friend.name,
                        photoUrl: friend.photoUrl,
                        backgroundColor: AppStyles.colorCardYellow,
                        foregroundColor: AppStyles.fontColor,
                        size: 40,
                        borderWidth: 2,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                child: Text(
                  friend.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewConnectionTile extends StatelessWidget {
  final VoidCallback? onTap;

  const _NewConnectionTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: DashedBorderBox(
        color: AppStyles.colorCardYellow,
        radius: 14,
        strokeWidth: 1.8,
        dashLength: 5,
        gapLength: 4,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppStyles.colorBaseYellow,
                shape: BoxShape.circle,
                border: Border.all(color: AppStyles.borderColor, width: 1.8),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 18,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              AppStrings.profileNewConnection,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              AppStrings.profileShareQr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
