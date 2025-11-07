import 'package:animate_do/animate_do.dart';
import 'package:app_events/config/theme/app_assets_path.dart';
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
    return dataCenter.sponsors.isNotEmpty
        ? FadeIn(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Sponsors",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (userProvider.isAdmin)
                      IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: const AddSponsorForm(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_business, size: 32, color: AppStyles.borderColor),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  padding: EdgeInsets.only(top: 20, bottom: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyles.fontColor, width: 2),
                    borderRadius: BorderRadius.circular(15),
                    color: const Color.fromARGB(255, 167, 167, 167),
                  ),
                  child: Wrap(
                    children: [
                      for (var item in dataCenter.sponsors)
                        Tooltip(
                          message: item.name,
                          child: TextButton(
                            onPressed: () async {
                              await laucherUrlInfo(item.link);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(5),
                              width: MediaQuery.of(context).size.width * 0.35,
                              // height: MediaQuery.of(context).size.width * 0.35,
                              child: FadeInImage(
                                placeholder: const AssetImage(
                                  AppAssetsPath.loadingSmallImage,
                                ),
                                image: NetworkImage(item.photoUrl),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : const SizedBox();
  }
}
