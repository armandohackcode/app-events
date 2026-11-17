import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/utils/modal_sponsor_form.dart';

class SponsorsContent extends StatefulWidget {
  const SponsorsContent({super.key});

  @override
  State<SponsorsContent> createState() => _SponsorsContentState();
}

class _SponsorsContentState extends State<SponsorsContent> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final dataCenter = Provider.of<OtherProvider>(context, listen: false);
      if (dataCenter.sponsors.isEmpty) {
        dataCenter.getSponsors();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<OtherProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    return FadeIn(
      child: Column(
        children: [
          const SizedBox(height: 22),
          Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: 1.5 * math.pi / 180,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppStyles.sponsorsPillColor,
                    border: Border.all(
                      color: AppStyles.borderColor,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: AppStyles.borderColor,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    AppStrings.homeSponsorsTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ),
              ),
              if (userProvider.isAdmin)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: const AddSponsorForm(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_business,
                      size: 32,
                      color: AppStyles.fontColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppStyles.colorCardBlue,
              border: Border.all(color: AppStyles.borderColor, width: 2),
              boxShadow: const [
                BoxShadow(color: AppStyles.borderColor, offset: Offset(4, 4)),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  AppStrings.homeSponsorsThanks,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                if (dataCenter.sponsors.isEmpty)
                  const _PlaceholderSponsors()
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var item in dataCenter.sponsors)
                        Tooltip(
                          message: item.name,
                          child: Stack(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await launcherUrlInfo(item.link);
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppStyles.cardColor,
                                    border: Border.all(
                                      color: AppStyles.borderColor,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  width:
                                      MediaQuery.of(context).size.width * 0.35,
                                  child: FadeInImage(
                                    placeholder: const AssetImage(
                                      AppAssetsPath.loadingSmallImage,
                                    ),
                                    image: CachedNetworkImageProvider(
                                      item.photoUrl,
                                    ),
                                  ),
                                ),
                              ),
                              if (userProvider.isAdmin)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    onPressed: () async {
                                      if (item.id == null) return;

                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text(
                                            AppStrings.sponsorDeleteTitle,
                                          ),
                                          content: Text(
                                            '${AppStrings.sponsorDeleteConfirm} ${item.name}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: const Text(
                                                AppStrings.commonWordCancel,
                                              ),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppStyles.colorBaseRed,
                                              ),
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              child: const Text(
                                                AppStrings.commonWordDelete,
                                                style: TextStyle(
                                                  color:
                                                      AppStyles.onAccentColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm != true) {
                                        return;
                                      }
                                      if (!context.mounted) {
                                        return;
                                      }

                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );

                                      await dataCenter.deleteSponsor(item.id!);

                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppStyles.colorBaseRed,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sponsor tiles of the design, shown while there are no loaded sponsors.
class _PlaceholderSponsors extends StatelessWidget {
  const _PlaceholderSponsors();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PlaceholderTile(
          name: AppStrings.homeSponsorPlaceholderOne,
          accent: AppStyles.backdropBlueColor,
        ),
        SizedBox(width: 14),
        _PlaceholderTile(
          name: AppStrings.homeSponsorPlaceholderTwo,
          accent: AppStyles.colorBaseGreen,
        ),
      ],
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final String name;
  final Color accent;
  const _PlaceholderTile({required this.name, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: AppStyles.cardColor,
          border: Border.all(color: AppStyles.borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              AppStrings.homeSponsorPlaceholderRegion,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
