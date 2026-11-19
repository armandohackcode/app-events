import 'dart:async';
import 'dart:math' as math;

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/user/delete_account.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/profile/edit_profile.dart';
import 'package:app_events/ui/widgets/profile/modal_qr_identify.dart';
import 'package:app_events/ui/widgets/profile/profile_friend.dart';
import 'package:app_events/ui/widgets/profile/profile_public.dart';
import 'package:app_events/ui/widgets/shared/button_scan.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/dashed_border_box.dart';
import 'package:app_events/ui/widgets/shared/dot_pattern.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/initials_avatar.dart';
import 'package:app_events/ui/widgets/shared/social_circle_button.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

enum _ProfileMenuAction { logout, deleteAccount }

/// Authenticated user profile screen with stats, social networks, QR code, and connections grid.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<UserCompetitor?>? _sub;
  bool _showAllConnections = false;

  static const _collapsedConnectionsLimit = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = Provider.of<UserProvider>(context, listen: false);
      if (data.userCompetitor != null) {
        _sub = data.streamInfoUser().listen((user) {
          if (user != null) {
            data.userCompetitor = user;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _openEditProfile() async {
    final res = await Navigator.of(
      context,
    ).push<bool?>(CupertinoPageRoute(builder: (_) => const EditProfile()));
    if (res == true && mounted) {
      customSnackbar(context, AppStrings.profileMsCongratulations);
    }
  }

  void _openPublicProfile(UserCompetitor competitor) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalProfilePublic(user: competitor),
    );
  }

  void _openQrModal(String uuid) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalQrIdentify(identify: uuid),
    );
  }

  void _openFriendModal(String uuid) {
    showDialog<void>(
      context: context,
      builder: (_) => ModalProfileFriend(uuid: uuid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    final data = Provider.of<UserProvider>(context);
    final competitor = data.userCompetitor;
    final canPop = Navigator.of(context).canPop();

    final displayName =
        competitor?.name ??
        auth.userInfo.displayName ??
        AppStrings.commonWordAnonymous;
    final avatarUrl = competitor?.photoUrl ?? auth.userInfo.photoUrl ?? '';
    final canScan = competitor != null && competitor.uuid.isNotEmpty;

    return HomeBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: canPop
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppStyles.fontColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(AppAssetsPath.gdgIcon, height: 18),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  AppStrings.profileCommunityHeader,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<_ProfileMenuAction>(
              icon: const Icon(Icons.more_vert, color: AppStyles.fontColor),
              color: AppStyles.cardColor,
              onSelected: (action) async {
                switch (action) {
                  case _ProfileMenuAction.logout:
                    await auth.logOut();
                    data.userCompetitor = null;
                    auth.isAuth = false;
                  case _ProfileMenuAction.deleteAccount:
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeleteAccount()),
                    );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _ProfileMenuAction.logout,
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: AppStyles.fontColor),
                      SizedBox(width: 8),
                      Text(AppStrings.profileLogOut),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _ProfileMenuAction.deleteAccount,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_forever_outlined,
                        size: 18,
                        color: AppStyles.colorBaseRed,
                      ),
                      SizedBox(width: 8),
                      Text(AppStrings.profileDeleteAccount),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: canScan
            ? Padding(
                padding: EdgeInsets.only(bottom: canPop ? 0 : 88),
                child: const ButtonScan(),
              )
            : null,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, canPop ? 32 : 112),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeaderCard(
                    displayName: displayName,
                    avatarUrl: avatarUrl,
                    competitor: competitor,
                    onEdit: competitor == null ? null : _openEditProfile,
                    onShare: competitor == null
                        ? null
                        : () => _openPublicProfile(competitor),
                  ),
                  if (competitor != null) ...[
                    const SizedBox(height: 16),
                    _SocialAndQrSection(
                      competitor: competitor,
                      onOpenQr: competitor.uuid.isNotEmpty
                          ? () => _openQrModal(competitor.uuid)
                          : null,
                    ),
                    const SizedBox(height: 18),
                    _ConnectionsSection(
                      friends: competitor.friends,
                      showAll: _showAllConnections,
                      collapsedLimit: _collapsedConnectionsLimit,
                      onToggleShowAll: () => setState(
                        () => _showAllConnections = !_showAllConnections,
                      ),
                      onOpenFriend: (friend) => _openFriendModal(friend.uuid),
                      onOpenQr: competitor.uuid.isNotEmpty
                          ? () => _openQrModal(competitor.uuid)
                          : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String displayName;
  final String avatarUrl;
  final UserCompetitor? competitor;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  const _ProfileHeaderCard({
    required this.displayName,
    required this.avatarUrl,
    required this.competitor,
    required this.onEdit,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final profession = competitor?.profession.trim() ?? '';
    final aboutMe = competitor?.aboutMe.trim() ?? '';

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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
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
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified,
                          size: 17,
                          color: AppStyles.backdropBlueColor,
                        ),
                      ],
                    ),
                    if (profession.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        profession,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      ),
                    ],
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
          if (competitor != null) ...[
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    value: competitor!.score,
                    label: AppStrings.commonWordPoints,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    value: competitor!.friends.length,
                    label: AppStrings.profileFriendsStat,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    value: competitor!.treasures.length,
                    label: AppStrings.profileTreasuresStat,
                  ),
                ),
              ],
            ),
          ],
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

class _SocialAndQrSection extends StatelessWidget {
  final UserCompetitor competitor;
  final VoidCallback? onOpenQr;

  const _SocialAndQrSection({required this.competitor, required this.onOpenQr});

  @override
  Widget build(BuildContext context) {
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
              if (competitor.socialNetwork.isEmpty)
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
                    for (final item in competitor.socialNetwork)
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
        if (onOpenQr != null)
          InkWell(
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
      ],
    );
  }
}

class _ConnectionsSection extends StatelessWidget {
  final List<Friend> friends;
  final bool showAll;
  final int collapsedLimit;
  final VoidCallback onToggleShowAll;
  final ValueChanged<Friend> onOpenFriend;
  final VoidCallback? onOpenQr;

  const _ConnectionsSection({
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
              Transform.rotate(
                angle: -0.02,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                  decoration: BoxDecoration(
                    color: AppStyles.colorBaseYellow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppStyles.borderColor,
                      width: 1.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppStyles.borderColor,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        AppStrings.commonWordConnections,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
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
                    ],
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
