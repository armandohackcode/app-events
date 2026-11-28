import 'dart:async';
import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/providers/spin_admin_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/user/delete_account.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/profile/edit_profile.dart';
import 'package:app_events/ui/widgets/profile/modal_qr_identify.dart';
import 'package:app_events/ui/widgets/profile/profile_connections_section.dart';
import 'package:app_events/ui/widgets/profile/profile_friend.dart';
import 'package:app_events/ui/widgets/profile/profile_header_card.dart';
import 'package:app_events/ui/widgets/profile/profile_public.dart';
import 'package:app_events/ui/widgets/profile/profile_social_qr_section.dart';
import 'package:app_events/ui/widgets/shared/button_scan.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  static int _attendedEventsCount(UserCompetitor? competitor) {
    if (competitor == null) return 0;
    final ids = <String>{
      for (final badge in competitor.badges)
        if (badge.eventId.isNotEmpty) badge.eventId,
    };
    final currentId = competitor.currentEventId?.trim() ?? '';
    if (currentId.isNotEmpty) {
      ids.add(currentId);
    }
    return math.max(ids.length, competitor.badges.length);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    final data = Provider.of<UserProvider>(context);
    final competitor = data.userCompetitor;
    final canPop = Navigator.of(context).canPop();

    final rawCompetitorName = competitor?.name.trim() ?? '';
    final rawAuthName = auth.userInfo.displayName?.trim() ?? '';
    final displayName = rawCompetitorName.isNotEmpty
        ? rawCompetitorName
        : (rawAuthName.isNotEmpty
              ? rawAuthName
              : AppStrings.commonWordAnonymous);
    final avatarUrl = competitor?.photoUrl ?? auth.userInfo.photoUrl ?? '';
    final email = auth.userInfo.email?.trim() ?? '';
    final memberSince = auth.userInfo.createdAt;
    final canScan = competitor != null && competitor.uuid.isNotEmpty;
    final qrCallback = canScan ? () => _openQrModal(competitor.uuid) : null;

    return HomeBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          toolbarHeight: 60,
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
          title: const HomeHeader(padding: EdgeInsets.zero),
          actions: [
            PopupMenuButton<_ProfileMenuAction>(
              icon: const Icon(Icons.more_vert, color: AppStyles.fontColor),
              color: AppStyles.cardColor,
              onSelected: (action) async {
                switch (action) {
                  case _ProfileMenuAction.logout:
                    final spinProvider = maybeProvider<GdgSpinProvider>(
                      context,
                      listen: false,
                    );
                    final spinAdminProvider = maybeProvider<SpinAdminProvider>(
                      context,
                      listen: false,
                    );
                    await auth.logOut();
                    data.clearSession();
                    spinProvider?.unbind();
                    spinAdminProvider?.unbind();
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
        floatingActionButton: canScan ? const ButtonScan() : null,
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, canPop ? 32 : 84),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeaderCard(
                    displayName: displayName,
                    email: email,
                    memberSince: memberSince,
                    avatarUrl: avatarUrl,
                    competitor: competitor,
                    eventsCount: _attendedEventsCount(competitor),
                    onEdit: competitor == null ? null : _openEditProfile,
                    onShare: competitor == null
                        ? null
                        : () => _openPublicProfile(competitor),
                  ),
                  const SizedBox(height: 16),
                  ProfileSocialAndQrSection(
                    socialNetworks: competitor?.socialNetwork ?? const [],
                    onOpenQr: qrCallback,
                  ),
                  const SizedBox(height: 18),
                  ProfileConnectionsSection(
                    friends: competitor?.friends ?? const [],
                    showAll: _showAllConnections,
                    collapsedLimit: _collapsedConnectionsLimit,
                    onToggleShowAll: () => setState(
                      () => _showAllConnections = !_showAllConnections,
                    ),
                    onOpenFriend: (friend) => _openFriendModal(friend.uuid),
                    onOpenQr: qrCallback,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
