import 'package:animate_do/animate_do.dart';
import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
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
      dataCenter.getSponsors();
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
                for (var item in dataCenter.sponsors)
                  InkWell(
                    onTap: () async {
                      await laucherUrlInfo(item.link);
                    },
                    child: Column(
                      children: [
                        // Image.network(
                        //   item.photoUrl,
                        //   height: 180,
                        // ),
                        SizedBox(
                          height: 180,
                          width: 300,
                          child: FadeInImage(
                              placeholder: const AssetImage(
                                  "assets/img/GoogleIO_Logo.gif"),
                              image: NetworkImage(item.photoUrl)),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppStyles.colorBaseYellow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(width: 1.2)),
                          child: Text(
                            item.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
              ],
            ),
          )
        : const SizedBox();
  }
}
