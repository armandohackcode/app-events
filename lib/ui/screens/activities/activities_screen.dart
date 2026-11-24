import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/gdg_spin_provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/gdg_spin/gdg_spin_screen.dart';
import 'package:app_events/ui/widgets/activities/activity_ranking_card.dart';
import 'package:app_events/ui/widgets/activities/activity_spin_card.dart';
import 'package:app_events/ui/widgets/activities/activity_treasure_card.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/home/ranking_data.dart';
import 'package:app_events/ui/widgets/home/treasure_bunt.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Activities tab presenting Ranking, GDG SPIN, and Treasure Hunt.
class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  bool _treasureLoadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final otherProvider = Provider.of<OtherProvider>(context, listen: false);
      if (otherProvider.treasureHuntItems.isNotEmpty) return;
      try {
        await otherProvider.getTreasureHuntItems();
      } catch (_) {
        if (mounted) {
          setState(() => _treasureLoadFailed = true);
        }
      }
    });
  }

  void _openTreasure(BuildContext context, UserProvider userProvider) {
    if (userProvider.userCompetitor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.activitiesJoinEventFirst)),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => const TreasureBunt()));
  }

  @override
  Widget build(BuildContext context) {
    final spinProvider = context.watch<GdgSpinProvider>();
    final userProvider = context.watch<UserProvider>();
    final otherProvider = context.watch<OtherProvider>();

    final found = userProvider.userCompetitor?.treasures.length;
    final items = otherProvider.treasureHuntItems;
    final total = (!_treasureLoadFailed && items.isNotEmpty)
        ? items.length
        : null;

    return Scaffold(
      backgroundColor: AppStyles.homeBackgroundColor,
      body: HomeBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeHeaderDecoration(child: HomeHeader()),
                      const Text(
                        AppStrings.navBarActivities,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        AppStrings.activitiesSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TaggedCard(
                        tag: AppStrings.activitiesRankingTag,
                        tagColor: AppStyles.activitiesRankingTagColor,
                        angleDegrees: -2,
                        child: ActivityRankingCard(
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const RankingData(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TaggedCard(
                        tag: AppStrings.activitiesSpinTag,
                        tagColor: AppStyles.activitiesSpinTagColor,
                        angleDegrees: 2,
                        child: ActivitySpinCard(
                          tickets: spinProvider.tickets,
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (_) => const GdgSpinScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      TaggedCard(
                        tag: AppStrings.homeTreasureBunt,
                        tagColor: AppStyles.activitiesTreasureTagColor,
                        angleDegrees: -1,
                        child: ActivityTreasureCard(
                          found: found,
                          total: total,
                          onTap: () => _openTreasure(context, userProvider),
                        ),
                      ),
                    ],
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
