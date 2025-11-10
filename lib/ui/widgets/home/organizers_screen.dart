import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class OrganizersScreen extends StatefulWidget {
  const OrganizersScreen({super.key});

  @override
  State<OrganizersScreen> createState() => _OrganizersScreenState();
}

class _OrganizersScreenState extends State<OrganizersScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final data = Provider.of<OtherProvider>(context, listen: false);
      if (data.organizers.isEmpty) {
        data.getOrganizer();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<OtherProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.organizersTitle)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const CardCommunity(),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: [
              for (var item in data.organizers)
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 60) / 3,
                  child: GestureDetector(
                    onTap: () async {
                      await laucherUrlInfo(item.link);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                FadeInImage(
                                  fit: BoxFit.cover,
                                  placeholder: const AssetImage(
                                    AppAssetsPath.loadingSmallImage,
                                  ),
                                  image: NetworkImage(item.photoUrl),
                                ),
                                if (item.lead)
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppStyles.colorBaseRed
                                            .withValues(alpha: 0.9),
                                      ),
                                      child: const Text(
                                        AppStrings.organizersTagLead,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (item.team.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.center,
                            children: [
                              for (var teamName in item.team)
                                TeamTag(teamName: teamName),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// TO DO: Refactor logic get teamColor
class TeamTag extends StatelessWidget {
  final String teamName;

  const TeamTag({super.key, required this.teamName});

  Color _getTeamColor(String team) {
    final teamLower = team.toLowerCase();
    if (teamLower.contains('speaker')) {
      return AppStyles.colorBaseRed;
    } else if (teamLower.contains('logística') ||
        teamLower.contains('logistica')) {
      return const Color(0xFF2196F3);
    } else if (teamLower.contains('acreditación') ||
        teamLower.contains('acreditacion')) {
      return AppStyles.colorBaseGreen;
    } else if (teamLower.contains('escenografía') ||
        teamLower.contains('escenografia')) {
      return const Color(0xFF9C27B0);
    } else if (teamLower.contains('diseño') || teamLower.contains('diseno')) {
      return const Color(0xFFE91E63);
    } else if (teamLower.contains('web')) {
      return AppStyles.colorBaseBlue;
    } else if (teamLower.contains('mobile')) {
      return const Color(0xFF00BCD4);
    } else if (teamLower.contains('marketing')) {
      return const Color(0xFFFF9800);
    } else if (teamLower.contains('audio') || teamLower.contains('video')) {
      return const Color(0xFFFF5722);
    } else if (teamLower.contains('sponsor')) {
      return AppStyles.colorBaseYellow;
    } else {
      return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getTeamColor(teamName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        teamName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class CardCommunity extends StatelessWidget {
  const CardCommunity({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: const Alignment(0, 1),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(width: 3, color: AppStyles.colorBaseYellow),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FadeInImage(
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.22,
                    placeholder: const AssetImage(
                      AppAssetsPath.loadingSmallImage,
                    ),
                    image: const NetworkImage(
                      "https://firebasestorage.googleapis.com/v0/b/gdgsucre-events.appspot.com/o/banner%2Fbanner.jpg?alt=media&token=23be97a8-c096-4f12-bfe7-6d7adb1604c7",
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          AppStrings.organizersGDGSucre,
                          style: TextStyle(
                            color: AppStyles.fontColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SocialMediaButton(
                              iconPath: AppAssetsPath.iconFacebook,
                              url: "https://www.facebook.com/gdg.sucre",
                            ),
                            const SizedBox(width: 8),
                            SocialMediaButton(
                              iconPath: AppAssetsPath.iconInstagram,
                              url: "https://www.instagram.com/gdg.sucre",
                            ),
                            const SizedBox(width: 8),
                            SocialMediaButton(
                              iconPath: AppAssetsPath.iconLinkedIn,
                              url:
                                  "https://www.linkedin.com/showcase/google-developer-groups/about/",
                            ),
                            const SizedBox(width: 8),
                            SocialMediaButton(
                              iconPath: AppAssetsPath.iconTwitter,
                              url: "https://twitter.com/gdg_sucre",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.colorBaseYellow,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppStyles.fontColor),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            await laucherUrlInfo("https://gdg.community.dev/gdg-sucre/");
          },
          child: const Text(
            AppStrings.commonWordSeeMore,
            style: TextStyle(color: AppStyles.fontColor),
          ),
        ),
      ],
    );
  }
}

class SocialMediaButton extends StatelessWidget {
  final String iconPath;
  final String url;
  final double size;

  const SocialMediaButton({
    super.key,
    required this.iconPath,
    required this.url,
    this.size = 25,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: SvgPicture.asset(iconPath, width: size, height: size),
      onTap: () async {
        await laucherUrlInfo(url);
      },
    );
  }
}
