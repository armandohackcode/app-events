import 'dart:async';

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/user_competitor.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RankingData extends StatefulWidget {
  const RankingData({super.key});

  @override
  State<RankingData> createState() => _RankingDataState();
}

class _RankingDataState extends State<RankingData> {
  StreamSubscription? _sub;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final data = Provider.of<OtherProvider>(context, listen: false);
      _sub = data.getRanking().listen((list) {
        data.ranking = list;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<OtherProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Ranking")),
      body: data.ranking.length >= 3
          ? Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  AppAssetsPath.androidPed,
                                  height: 55,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 50,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: AppStyles.colorBaseGreen,
                                  ),
                                  child: const Text(
                                    "2",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppStyles.cardColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  data.ranking[1].score.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  AppAssetsPath.firePedIcon,
                                  height: 50,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 50,
                                  height: 110,
                                  decoration: const BoxDecoration(
                                    color: AppStyles.colorBaseYellow,
                                  ),
                                  child: const Text(
                                    "1",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppStyles.cardColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  data.ranking[0].score.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(AppAssetsPath.dashPed, height: 50),
                                Container(
                                  alignment: Alignment.center,
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: AppStyles.colorBaseBlue,
                                  ),
                                  child: const Text(
                                    "3",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppStyles.cardColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  data.ranking[2].score.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Image.asset(AppAssetsPath.partyAnimation, height: 110),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: data.ranking.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        return CardRanking(
                          data: data.ranking[index],
                          index: index + 1,
                          color: AppStyles.colorBaseYellow,
                        );
                      }
                      if (index == 1) {
                        return CardRanking(
                          data: data.ranking[index],
                          index: index + 1,
                          color: AppStyles.colorBaseGreen,
                        );
                      }
                      if (index == 2) {
                        return CardRanking(
                          data: data.ranking[index],
                          index: index + 1,
                          color: AppStyles.colorBaseBlue,
                        );
                      }
                      return CardRanking(
                        data: data.ranking[index],
                        index: index + 1,
                        color: AppStyles.fontColor,
                      );
                    },
                  ),
                ),
              ],
            )
          : Center(
              child: Image.asset(
                AppAssetsPath.loadingAnimation,
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
    );
  }
}

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
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.all(5),
      // padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppStyles.colorBaseYellow, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Text(
          index.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        trailing: Text(
          data.score.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        title: Text(
          data.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
