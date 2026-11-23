import 'dart:async';

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/initials_avatar.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:app_events/ui/widgets/shared/title_pill.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pop-brutalist leaderboard showing top 3 on a podium and remaining attendees below.
class RankingData extends StatefulWidget {
  const RankingData({super.key});

  @override
  State<RankingData> createState() => _RankingDataState();
}

class _RankingDataState extends State<RankingData> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final data = Provider.of<OtherProvider>(context, listen: false);
      _sub = data.getRanking().listen((list) {
        data.ranking = list;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ranking = Provider.of<OtherProvider>(context).ranking;
    final topEntries = ranking.take(3).toList();
    final restEntries = ranking.length > 3
        ? ranking.sublist(3)
        : const <UserCompetitor>[];

    return HomeBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const TitlePill(
            text: AppStrings.rankingTitle,
            color: AppStyles.activitiesRankingTagColor,
            angle: -1,
          ),
        ),
        body: ranking.isEmpty
            ? const _RankingLoadingState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PodiumSection(entries: topEntries),
                          if (restEntries.isNotEmpty) ...[
                            const SizedBox(height: 22),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: TitlePill(
                                text: AppStrings.rankingLeaderboardTag,
                                color: AppStyles.activitiesRankingTagColor,
                                angle: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              restEntries.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: CardRanking(
                                  data: restEntries[index],
                                  index: index + 4,
                                  color:
                                      AppStyles.gdgBrandPalette[(index + 3) %
                                          AppStyles.gdgBrandPalette.length],
                                ),
                              ),
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

class _RankingLoadingState extends StatelessWidget {
  const _RankingLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: HardShadowBox(
          color: AppStyles.cardColor,
          radius: 22,
          shadowOffset: 5,
          borderWidth: 2.5,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Image.asset(
                  AppAssetsPath.loadingAnimation,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),
              const TiltedTag(
                text: AppStrings.rankingLoading,
                color: AppStyles.colorBaseYellow,
                angleDegrees: -1,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PodiumSection extends StatelessWidget {
  final List<UserCompetitor> entries;

  const _PodiumSection({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return TaggedCard(
      tag: AppStrings.rankingPodiumTag,
      tagColor: AppStyles.colorBaseYellow,
      angleDegrees: -1.5,
      child: HardShadowBox(
        color: AppStyles.cardColor,
        radius: 22,
        shadowOffset: 5,
        borderWidth: 2.5,
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (second != null)
                  Expanded(
                    child: _PodiumColumn(
                      rank: 2,
                      entry: second,
                      pillarHeight: 74,
                      pillarColor: AppStyles.podiumSecondColor,
                      rankTextColor: AppStyles.onAccentColor,
                      showTrophy: false,
                    ),
                  ),
                if (second != null) const SizedBox(width: 8),
                if (first != null)
                  Expanded(
                    child: _PodiumColumn(
                      rank: 1,
                      entry: first,
                      pillarHeight: 108,
                      pillarColor: AppStyles.podiumFirstColor,
                      rankTextColor: AppStyles.fontColor,
                      showTrophy: true,
                    ),
                  ),
                if (third != null) const SizedBox(width: 8),
                if (third != null)
                  Expanded(
                    child: _PodiumColumn(
                      rank: 3,
                      entry: third,
                      pillarHeight: 54,
                      pillarColor: AppStyles.podiumThirdColor,
                      rankTextColor: AppStyles.onAccentColor,
                      showTrophy: false,
                    ),
                  ),
              ],
            ),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppStyles.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final int rank;
  final UserCompetitor entry;
  final double pillarHeight;
  final Color pillarColor;
  final Color rankTextColor;
  final bool showTrophy;

  const _PodiumColumn({
    required this.rank,
    required this.entry,
    required this.pillarHeight,
    required this.pillarColor,
    required this.rankTextColor,
    required this.showTrophy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTrophy)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Image.asset(
              AppAssetsPath.trophyIcon,
              width: 28,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        InitialsAvatar(
          name: entry.name,
          photoUrl: entry.photoUrl,
          backgroundColor: pillarColor,
          foregroundColor: rankTextColor,
          size: rank == 1 ? 54 : 46,
          borderWidth: 2,
        ),
        const SizedBox(height: 6),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppStyles.fontColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppStyles.homeBackgroundColor,
            border: Border.all(color: AppStyles.borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            AppStrings.rankingPointsBadge(entry.score),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppStyles.fontColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: pillarHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pillarColor,
            border: const Border(
              top: BorderSide(color: AppStyles.borderColor, width: 2.5),
              left: BorderSide(color: AppStyles.borderColor, width: 2.5),
              right: BorderSide(color: AppStyles.borderColor, width: 2.5),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(
            AppStrings.rankingPositionLabel(rank),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: rankTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pop-brutalist leaderboard row displaying position, avatar, attendee, and points.
class CardRanking extends StatelessWidget {
  const CardRanking({
    super.key,
    required this.data,
    required this.index,
    required this.color,
  });

  final UserCompetitor data;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 16,
      shadowOffset: 3,
      borderWidth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppStyles.homeBackgroundColor,
              border: Border.all(color: AppStyles.borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppStrings.rankingPositionLabel(index),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: AppStyles.fontColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InitialsAvatar(
            name: data.name,
            photoUrl: data.photoUrl,
            backgroundColor: color,
            size: 40,
            borderWidth: 2,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppStyles.fontColor,
                  ),
                ),
                if (data.profession.trim().isNotEmpty)
                  Text(
                    data.profession,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppStyles.activitiesRankingTagColor,
              border: Border.all(color: AppStyles.borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              AppStrings.rankingPointsBadge(data.score),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppStyles.fontColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
