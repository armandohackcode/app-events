import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_links.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/screens/events/events_screen.dart';
import 'package:app_events/ui/screens/user/attendees_screen.dart';
// import 'package:app_events/ui/screens/speed_run/speed_run_screen.dart';
import 'package:app_events/ui/widgets/home/activity_row.dart';
import 'package:app_events/ui/widgets/home/channels_card.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/home/live_talk_card.dart';
import 'package:app_events/ui/widgets/home/organizers_screen.dart';
import 'package:app_events/ui/widgets/home/question_box.dart';
import 'package:app_events/ui/widgets/home/ranking_data.dart';
import 'package:app_events/ui/widgets/home/sponsors_content.dart';
import 'package:app_events/ui/widgets/home/treasure_bunt.dart';
import 'package:app_events/ui/widgets/shared/button_scan.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// Placeholder content of the live talk card. It is static until the card is
/// fed with the talk that is really in progress.
final Speaker _placeholderTalk = Speaker(
  uuid: '',
  title: AppStrings.homeLiveTalkTitle,
  description: '',
  name: AppStrings.homeLiveSpeakerName,
  profession: AppStrings.homeLiveSpeakerProfession,
  aboutMe: '',
  photoUrl: '',
  technologyType: AppStrings.homeLiveTechnology,
  type: EventTypeSpeaker.conference.value,
  color: '',
  schedule: AppStrings.homeLiveSchedule,
  position: 0,
  socialNetwork: [
    SocialNetwork(
      type: SocialNetworkType.instagram.value,
      link: AppLinks.gdgInstagram,
    ),
    SocialNetwork(
      type: SocialNetworkType.linkedin.value,
      link: AppLinks.gdgLinkedIn,
    ),
    SocialNetwork(
      type: SocialNetworkType.tiktok.value,
      link: AppLinks.gdgTikTok,
    ),
  ],
);

class Home extends StatelessWidget {
  const Home({super.key});

  static const double _rowGap = 14;

  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: AppStyles.homeBackgroundColor,
      body: HomeBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            children: [
              const HomeHeaderDecoration(child: _HomeHeader()),
              LiveTalkCard(
                talk: _placeholderTalk,
                photo: const AssetImage(AppAssetsPath.liveTalkPhoto),
                // Design only for now: the talk detail is not linked yet.
                onTap: () {},
                footer: const QuestionBox(),
              ),
              const SizedBox(height: 16),
              ActivityRow(
                icon: Image.asset(AppAssetsPath.computerIcon),
                iconBackground: AppStyles.colorCardBlue,
                title: AppStrings.scheduleSchedule,
                subtitle: AppStrings.homeScheduleSubtitle,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const EventsScreen()),
                ),
              ),
              // No delete
              // ButtonActivity(
              //   onPressed: () => Navigator.of(context).push(
              //     CupertinoPageRoute(builder: (_) => const SpeedRunScreen()),
              //   ),
              //   text: AppStrings.homeSpeedRunBuild,
              //   icon: Image.asset(AppAssetsPath.dinoRunIcon, height: 80),
              // ),
              const SizedBox(height: _rowGap),
              ActivityRow(
                icon: Image.asset(AppAssetsPath.trophyIcon),
                iconBackground: AppStyles.colorCardRed,
                title: AppStrings.homeTournamentGDG,
                onTap: () => Navigator.of(
                  context,
                ).push(CupertinoPageRoute(builder: (_) => const RankingData())),
              ),
              const SizedBox(height: _rowGap),
              ActivityRow(
                icon: Image.asset(AppAssetsPath.firePedExplorerIcon),
                iconBackground: AppStyles.colorCardBlue,
                title: AppStrings.homeTreasureBunt,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const TreasureBunt()),
                ),
              ),
              const SizedBox(height: _rowGap),
              ActivityRow(
                icon: Image.asset(AppAssetsPath.logoGdg),
                iconBackground: AppStyles.colorCardYellow,
                title: AppStrings.homeMeetCommunity,
                subtitle: AppStrings.homeMeetCommunitySubtitle,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const OrganizersScreen()),
                ),
              ),
              if (dataCenter.isAdmin) ...[
                const SizedBox(height: _rowGap),
                ActivityRow(
                  icon: Image.asset(AppAssetsPath.dinoWriteIcon),
                  iconBackground: AppStyles.colorCardYellow,
                  title: AppStrings.commonWordAttendees,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const AttendeesScreen()),
                  ),
                ),
              ],
              const SizedBox(height: _rowGap),
              const ChannelsCard(),
              const SponsorsContent(),
              const SizedBox(height: 20),
              FutureBuilder(
                future: PackageInfo.fromPlatform(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<PackageInfo> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      }
                      return Text(
                        "${AppStrings.versionApp}: ${snapshot.data?.version ?? ""}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppStyles.fontFaintColor,
                        ),
                      );
                    },
              ),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () async {
                  await launcherUrlInfo(AppLinks.developerLinkedIn);
                },
                child: const Text(AppStrings.developedBy),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      floatingActionButton: (dataCenter.userCompetitor != null)
          ? const ButtonScan()
          : null,
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      child: Row(
        children: [
          Image.asset(AppAssetsPath.logoGdg, height: 34),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.organizersGDGSucre,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
              Text(
                AppStrings.homeHeaderSubtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
