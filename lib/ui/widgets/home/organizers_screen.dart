import 'dart:math' as math;

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_links.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/organizers/add_organizer_form.dart';
import 'package:app_events/ui/widgets/shared/confirm_dialog.dart';
import 'package:app_events/ui/widgets/shared/dashed_border_box.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/initials_avatar.dart';
import 'package:app_events/ui/widgets/shared/social_circle_button.dart';
import 'package:app_events/ui/widgets/shared/title_pill.dart';
import 'package:app_events/ui/widgets/utils/text_normalizer.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _TeamBucket {
  final String key;
  final String label;
  final List<Organizer> members = [];

  _TeamBucket({required this.key, required this.label});
}

/// Event organizers directory with community channels, search, and dynamic team filters.
class OrganizersScreen extends StatefulWidget {
  const OrganizersScreen({super.key});

  @override
  State<OrganizersScreen> createState() => _OrganizersScreenState();
}

class _OrganizersScreenState extends State<OrganizersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedTeamKey;
  final Set<String> _expandedTeams = {};

  static const _collapsedVisibleLimit = 7;

  static final List<String> _knownTeamOrder = [
    AppStrings.organizersTeamApp,
    AppStrings.organizersTeamDesign,
    AppStrings.organizersTeamStaging,
    AppStrings.organizersTeamMarketing,
    AppStrings.organizersTeamLogistics,
    AppStrings.organizersTeamAudioVideo,
    AppStrings.organizersTeamSponsors,
    AppStrings.organizersTeamRoadToDevFest,
    AppStrings.organizersTeamWeb,
    AppStrings.organizersTeamAccreditation,
  ];

  static final Map<String, int> _knownRank = {
    for (var i = 0; i < _knownTeamOrder.length; i++)
      normalizeLookupKey(_knownTeamOrder[i]): i,
  };

  static final Map<String, String> _knownLabels = {
    for (final name in _knownTeamOrder) normalizeLookupKey(name): name,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<OtherProvider>(context, listen: false).getOrganizer();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static List<({String key, String label})> _extractTeams(Organizer item) {
    final seen = <String>{};
    final result = <({String key, String label})>[];
    for (final raw in item.team) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || isRoleOnlyTag(trimmed)) continue;
      final key = normalizeLookupKey(trimmed);
      if (seen.add(key)) {
        result.add((key: key, label: _knownLabels[key] ?? trimmed));
      }
    }
    if (result.isEmpty) {
      final fallbackLabel = item.type == leadValue
          ? AppStrings.organizersFilterLeadership
          : AppStrings.organizersFilterCommunity;
      result.add((
        key: normalizeLookupKey(fallbackLabel),
        label: fallbackLabel,
      ));
    }
    return result;
  }

  static List<_TeamBucket> _buildBuckets(List<Organizer> organizers) {
    final byKey = <String, _TeamBucket>{};
    for (final item in organizers) {
      for (final team in _extractTeams(item)) {
        final bucket = byKey.putIfAbsent(
          team.key,
          () => _TeamBucket(key: team.key, label: team.label),
        );
        bucket.members.add(item);
      }
    }
    final leadershipKey = normalizeLookupKey(
      AppStrings.organizersFilterLeadership,
    );
    final communityKey = normalizeLookupKey(
      AppStrings.organizersFilterCommunity,
    );

    final buckets = byKey.values.toList();
    buckets.sort((a, b) {
      final aFallback = a.key == leadershipKey || a.key == communityKey;
      final bFallback = b.key == leadershipKey || b.key == communityKey;
      if (aFallback != bFallback) return aFallback ? 1 : -1;

      final rankA = _knownRank[a.key];
      final rankB = _knownRank[b.key];
      if (rankA != null && rankB != null) return rankA.compareTo(rankB);
      if (rankA != null) return -1;
      if (rankB != null) return 1;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final organizers = Provider.of<OtherProvider>(context).organizers;
    final userProvider = Provider.of<UserProvider>(context);

    final allBuckets = _buildBuckets(organizers);

    final activeSelection =
        _selectedTeamKey != null &&
            allBuckets.any((b) => b.key == _selectedTeamKey)
        ? _selectedTeamKey
        : null;

    final trimmedQuery = _query.trim().toLowerCase();
    final visibleBuckets = <_TeamBucket>[];
    for (final bucket in allBuckets) {
      if (activeSelection != null && bucket.key != activeSelection) continue;
      final filtered = trimmedQuery.isEmpty
          ? bucket.members
          : bucket.members.where((item) {
              final nameMatch = item.name.toLowerCase().contains(trimmedQuery);
              final teamMatch = item.team.any(
                (t) => t.toLowerCase().contains(trimmedQuery),
              );
              return nameMatch || teamMatch;
            }).toList();
      if (filtered.isNotEmpty) {
        final filteredBucket = _TeamBucket(key: bucket.key, label: bucket.label)
          ..members.addAll(filtered);
        visibleBuckets.add(filteredBucket);
      }
    }

    final forceExpand = trimmedQuery.isNotEmpty || activeSelection != null;

    return HomeBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppStyles.fontColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            AppStrings.organizersTitle,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppStyles.fontColor,
            ),
          ),
          actions: [
            if (userProvider.isAdmin)
              IconButton(
                icon: const Icon(
                  Icons.person_add,
                  size: 20,
                  color: AppStyles.fontColor,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: const AddOrganizerForm(),
                    ),
                  );
                },
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _CommunityHeroCard(),
                  const SizedBox(height: 14),
                  _SearchField(
                    controller: _searchController,
                    hasQuery: _query.isNotEmpty,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        _FilterChipButton(
                          label: AppStrings.organizersFilterAll,
                          count: organizers.length,
                          selected: activeSelection == null,
                          onTap: () => setState(() => _selectedTeamKey = null),
                        ),
                        for (final bucket in allBuckets) ...[
                          const SizedBox(width: 8),
                          _FilterChipButton(
                            label: bucket.label,
                            count: bucket.members.length,
                            selected: activeSelection == bucket.key,
                            onTap: () =>
                                setState(() => _selectedTeamKey = bucket.key),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (organizers.isEmpty)
                    const _EmptyOrganizersBox(
                      message: AppStrings.organizersEmptyState,
                    )
                  else if (visibleBuckets.isEmpty)
                    const _EmptyOrganizersBox(
                      message: AppStrings.organizersEmptySearch,
                    )
                  else
                    for (var i = 0; i < visibleBuckets.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _OrganizerGroupSection(
                        title: visibleBuckets[i].label,
                        members: visibleBuckets[i].members,
                        expanded:
                            forceExpand ||
                            _expandedTeams.contains(visibleBuckets[i].key),
                        collapsedLimit: _collapsedVisibleLimit,
                        onToggleExpand: () {
                          setState(() {
                            final key = visibleBuckets[i].key;
                            if (_expandedTeams.contains(key)) {
                              _expandedTeams.remove(key);
                            } else {
                              _expandedTeams.add(key);
                            }
                          });
                        },
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

class _CommunityHeroCard extends StatelessWidget {
  const _CommunityHeroCard();

  static const _channels = [
    (
      label: AppStrings.homeChannelWhatsApp,
      color: AppStyles.socialWhatsAppColor,
      glyph: AppAssetsPath.glyphWhatsApp,
      url: AppLinks.gdgWhatsApp,
    ),
    (
      label: AppStrings.homeChannelInstagram,
      color: AppStyles.socialInstagramColor,
      glyph: AppAssetsPath.glyphInstagram,
      url: AppLinks.gdgInstagram,
    ),
    (
      label: AppStrings.homeChannelFacebook,
      color: AppStyles.socialFacebookColor,
      glyph: AppAssetsPath.glyphFacebook,
      url: AppLinks.gdgFacebook,
    ),
    (
      label: AppStrings.homeChannelTikTok,
      color: AppStyles.socialTikTokColor,
      glyph: AppAssetsPath.glyphTikTok,
      url: AppLinks.gdgTikTok,
    ),
    (
      label: AppStrings.homeChannelWeb,
      color: AppStyles.socialWebColor,
      glyph: AppAssetsPath.glyphWeb,
      url: AppLinks.gdgWeb,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppStyles.colorBaseYellow, width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppStyles.backdropBlueColor,
                          AppStyles.podiumSecondColor,
                          AppStyles.colorBaseYellow,
                        ],
                      ),
                    ),
                  ),
                  CachedNetworkImage(
                    imageUrl: AppLinks.organizersBanner,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const SizedBox.shrink(),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppStyles.imageOverlayColor,
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Text(
                      AppStrings.organizersGDGSucre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppStyles.onAccentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppStyles.cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _channels.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SocialCircleButton(
                            color: _channels[i].color,
                            glyph: _channels[i].glyph,
                            tooltip: _channels[i].label,
                            size: 42,
                            glyphSize: 20,
                            borderWidth: 2,
                            onTap: () => launcherUrlInfo(_channels[i].url),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _channels[i].label,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppStyles.fontSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 14,
      shadowOffset: 3,
      borderWidth: 2,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppStyles.fontColor,
        ),
        decoration: InputDecoration(
          hintText: AppStrings.organizersSearchHint,
          hintStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppStyles.fontSecondaryColor,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppStyles.fontSecondaryColor,
          ),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppStyles.fontSecondaryColor,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppStyles.colorBaseYellow : AppStyles.cardColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppStyles.borderColor, width: 1.8),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppStyles.borderColor,
                      offset: Offset(2, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppStyles.fontColor
                      : AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganizerGroupSection extends StatelessWidget {
  final String title;
  final List<Organizer> members;
  final bool expanded;
  final int collapsedLimit;
  final VoidCallback onToggleExpand;

  const _OrganizerGroupSection({
    required this.title,
    required this.members,
    required this.expanded,
    required this.collapsedLimit,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final hasOverflow = members.length > collapsedLimit;
    final showMoreTile = hasOverflow && !expanded;
    final visibleMembers = showMoreTile
        ? members.take(collapsedLimit).toList()
        : members;

    final entries = <Widget>[
      for (var i = 0; i < visibleMembers.length; i++)
        _OrganizerTile(member: visibleMembers[i], paletteIndex: i),
      if (showMoreTile)
        _MoreMembersTile(
          remaining: members.length - collapsedLimit,
          onTap: onToggleExpand,
        ),
    ];

    final rows = <List<Widget>>[];
    for (var i = 0; i < entries.length; i += 4) {
      rows.add(entries.sublist(i, math.min(i + 4, entries.length)));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 13),
          child: HardShadowBox(
            color: AppStyles.cardColor,
            radius: 18,
            shadowOffset: 4,
            borderWidth: 2,
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasOverflow && expanded)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: onToggleExpand,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            AppStrings.organizersSeeLess,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppStyles.backdropBlueColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                for (var r = 0; r < rows.length; r++) ...[
                  if (r > 0) const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var c = 0; c < 4; c++) ...[
                        if (c > 0) const SizedBox(width: 8),
                        Expanded(
                          child: c < rows[r].length
                              ? rows[r][c]
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 12,
          child: TitlePill(
            text: title,
            color: AppStyles.colorBaseYellow,
            angle: -1.4,
            fontSize: 12,
            borderWidth: 2,
            shadowOffset: 2,
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppStyles.cardColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                members.length.toString(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppStyles.fontColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrganizerTile extends StatelessWidget {
  final Organizer member;
  final int paletteIndex;

  const _OrganizerTile({required this.member, required this.paletteIndex});

  static const _avatarPalette = [
    AppStyles.backdropBlueColor,
    AppStyles.teamStagingColor,
    AppStyles.podiumSecondColor,
    AppStyles.podiumThirdColor,
    AppStyles.teamMobileColor,
    AppStyles.teamDesignColor,
    AppStyles.teamMarketingColor,
    AppStyles.teamLogisticsColor,
  ];

  String? _roleLabel() {
    if (member.type == leadValue) return AppStrings.organizersTagLead;
    for (final team in member.team) {
      if (isCoLeadRoleTag(team)) {
        return AppStrings.organizersTagCoLead;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final otherProvider = Provider.of<OtherProvider>(context, listen: false);

    final roleLabel = _roleLabel();
    final isLead = member.type == leadValue;
    final avatarColor =
        _avatarPalette[(member.name.hashCode.abs() + paletteIndex) %
            _avatarPalette.length];

    return InkWell(
      onTap: member.link.isNotEmpty ? () => launcherUrlInfo(member.link) : null,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 54,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                InitialsAvatar(
                  name: member.name,
                  photoUrl: member.photoUrl,
                  backgroundColor: avatarColor,
                  size: 48,
                  borderWidth: 2,
                  fontSize: 15,
                ),
                if (roleLabel != null)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isLead
                            ? AppStyles.podiumThirdColor
                            : AppStyles.backdropBlueColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppStyles.borderColor,
                          width: 1.2,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: AppStyles.onAccentColor,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (userProvider.isAdmin)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        FocusScope.of(context).unfocus();
                        if (member.id == null) return;
                        final confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (_) => ConfirmDialog(
                            title: AppStrings.organizerDelete,
                            subtitle: AppStrings.organizerDeleteConfirm(
                              member.name,
                            ),
                            acceptText: AppStrings.commonWordDelete,
                            acceptColor: Colors.redAccent,
                          ),
                        );
                        if (confirmDelete == true && context.mounted) {
                          otherProvider.deleteOrganizer(member.id!);
                        }
                      },
                      // onTap: onDelete,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppStyles.borderColor,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            member.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppStyles.fontColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMembersTile extends StatelessWidget {
  final int remaining;
  final VoidCallback onTap;

  const _MoreMembersTile({required this.remaining, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 54,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 48,
                height: 48,
                child: DashedBorderBox(
                  circle: true,
                  color: AppStyles.colorCardYellow,
                  strokeWidth: 1.8,
                  dashLength: 4,
                  gapLength: 3,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.organizersMoreCount(remaining),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: AppStyles.fontColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            AppStrings.organizersSeeAll,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrganizersBox extends StatelessWidget {
  final String message;

  const _EmptyOrganizersBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 16,
      shadowOffset: 3,
      borderWidth: 2,
      padding: const EdgeInsets.all(20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppStyles.fontSecondaryColor,
        ),
      ),
    );
  }
}
