// cspell:ignore lider coordin diseno disen diseñ escenograf escenografia logistica acreditacion comunidad organizador difusion colead movil
import 'dart:math' as math;

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_links.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/shared/dashed_border_box.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/initials_avatar.dart';
import 'package:app_events/ui/widgets/shared/social_circle_button.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _OrganizerGroup { leadership, design, development, community }

/// Event organizers directory with community channels, search, and team filters.
class OrganizersScreen extends StatefulWidget {
  const OrganizersScreen({super.key});

  @override
  State<OrganizersScreen> createState() => _OrganizersScreenState();
}

class _OrganizersScreenState extends State<OrganizersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _OrganizerGroup? _selectedGroup;
  final Set<_OrganizerGroup> _expandedGroups = {};

  static const _collapsedVisibleLimit = 7;

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

  static _OrganizerGroup _classifyGroup(Organizer item) {
    final lowerTeams = item.team.map((t) => t.toLowerCase()).toList();
    if (item.lead ||
        _containsAny(lowerTeams, const [
          'lider',
          'lead',
          'organizador',
          'coordin',
        ])) {
      return _OrganizerGroup.leadership;
    }
    if (_containsAny(lowerTeams, const [
      'diseñ',
      'disen',
      'diseno',
      'ui',
      'ux',
      'escenograf',
    ])) {
      return _OrganizerGroup.design;
    }
    if (_containsAny(lowerTeams, const [
      'web',
      'mobile',
      'movil',
      'cloud',
      'ia',
      'ai',
      'dev',
      'tech',
      'android',
      'flutter',
      'data',
    ])) {
      return _OrganizerGroup.development;
    }
    return _OrganizerGroup.community;
  }

  static bool _containsAny(List<String> values, List<String> needles) {
    for (final value in values) {
      for (final needle in needles) {
        if (value.contains(needle)) return true;
      }
    }
    return false;
  }

  String _sectionTitle(_OrganizerGroup group) => switch (group) {
    _OrganizerGroup.leadership => AppStrings.organizersFilterLeadership,
    _OrganizerGroup.design => AppStrings.organizersSectionDesign,
    _OrganizerGroup.development => AppStrings.organizersFilterDevelopment,
    _OrganizerGroup.community => AppStrings.organizersSectionCommunity,
  };

  String _filterLabel(_OrganizerGroup group) => switch (group) {
    _OrganizerGroup.leadership => AppStrings.organizersFilterLeadership,
    _OrganizerGroup.design => AppStrings.organizersFilterDesign,
    _OrganizerGroup.development => AppStrings.organizersFilterDevelopment,
    _OrganizerGroup.community => AppStrings.organizersFilterCommunity,
  };

  @override
  Widget build(BuildContext context) {
    final organizers = Provider.of<OtherProvider>(context).organizers;

    final groupCounts = <_OrganizerGroup, int>{
      for (final group in _OrganizerGroup.values) group: 0,
    };
    for (final item in organizers) {
      final group = _classifyGroup(item);
      groupCounts[group] = (groupCounts[group] ?? 0) + 1;
    }

    final trimmedQuery = _query.trim().toLowerCase();
    final grouped = <_OrganizerGroup, List<Organizer>>{
      for (final group in _OrganizerGroup.values) group: [],
    };
    for (final item in organizers) {
      final group = _classifyGroup(item);
      if (_selectedGroup != null && _selectedGroup != group) continue;
      if (trimmedQuery.isNotEmpty) {
        final nameMatch = item.name.toLowerCase().contains(trimmedQuery);
        final teamMatch = item.team.any(
          (t) => t.toLowerCase().contains(trimmedQuery),
        );
        if (!nameMatch && !teamMatch) continue;
      }
      grouped[group]!.add(item);
    }

    final visibleGroups = _OrganizerGroup.values
        .where((g) => grouped[g]!.isNotEmpty)
        .toList();
    final forceExpand = trimmedQuery.isNotEmpty || _selectedGroup != null;

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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChipButton(
                        label: AppStrings.organizersFilterAll,
                        count: organizers.length,
                        selected: _selectedGroup == null,
                        onTap: () => setState(() => _selectedGroup = null),
                      ),
                      for (final group in _OrganizerGroup.values)
                        _FilterChipButton(
                          label: _filterLabel(group),
                          count: groupCounts[group] ?? 0,
                          selected: _selectedGroup == group,
                          onTap: () => setState(() => _selectedGroup = group),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (organizers.isEmpty)
                    const _EmptyOrganizersBox(
                      message: AppStrings.organizersEmptyState,
                    )
                  else if (visibleGroups.isEmpty)
                    const _EmptyOrganizersBox(
                      message: AppStrings.organizersEmptySearch,
                    )
                  else
                    for (var i = 0; i < visibleGroups.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      _OrganizerGroupSection(
                        title: _sectionTitle(visibleGroups[i]),
                        members: grouped[visibleGroups[i]]!,
                        expanded:
                            forceExpand ||
                            _expandedGroups.contains(visibleGroups[i]),
                        collapsedLimit: _collapsedVisibleLimit,
                        onToggleExpand: () {
                          setState(() {
                            final group = visibleGroups[i];
                            if (_expandedGroups.contains(group)) {
                              _expandedGroups.remove(group);
                            } else {
                              _expandedGroups.add(group);
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  for (final channel in _channels)
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SocialCircleButton(
                            color: channel.color,
                            glyph: channel.glyph,
                            tooltip: channel.label,
                            size: 40,
                            glyphSize: 19,
                            borderWidth: 1.8,
                            onTap: () => launcherUrlInfo(channel.url),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            channel.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppStyles.fontColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
          child: Transform.rotate(
            angle: -0.025,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppStyles.colorBaseYellow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppStyles.borderColor, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppStyles.borderColor, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
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
                      members.length.toString(),
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
    if (member.lead) return AppStrings.organizersTagLead;
    for (final team in member.team) {
      final lower = team.toLowerCase();
      if (lower.contains('co-lead') ||
          lower.contains('colead') ||
          lower.contains('co lead')) {
        return AppStrings.organizersTagCoLead;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _roleLabel();
    final isLead = member.lead;
    final avatarColor =
        _avatarPalette[(member.name.hashCode.abs() + paletteIndex) %
            _avatarPalette.length];

    return InkWell(
      onTap: member.link.isNotEmpty ? () => launcherUrlInfo(member.link) : null,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
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
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
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
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
