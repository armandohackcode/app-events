import 'package:animate_do/animate_do.dart';
import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/ui/providers/data_center.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SponsorsContent extends StatefulWidget {
  const SponsorsContent({super.key});

  @override
  State<SponsorsContent> createState() => _SponsorsContentState();
}

class _SponsorsContentState extends State<SponsorsContent> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final dataCenter = Provider.of<DataCenter>(context, listen: false);
      if (dataCenter.sponsors.isEmpty) {
        dataCenter.getSponsors();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<DataCenter>(context);
    return dataCenter.sponsors.isNotEmpty
        ? FadeIn(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sponsors",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
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
              ],
            ),
          )
        : const SizedBox();
  }
}
