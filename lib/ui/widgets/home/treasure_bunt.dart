import 'package:animate_do/animate_do.dart';
import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/treasure_hunt_model.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class TreasureBunt extends StatefulWidget {
  const TreasureBunt({super.key});

  @override
  State<TreasureBunt> createState() => _TreasureBuntState();
}

class _TreasureBuntState extends State<TreasureBunt> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final data = Provider.of<OtherProvider>(context, listen: false);
      if (data.treasureHuntItems.isEmpty) {
        await data.getTreasureHuntItems();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<OtherProvider>(context);
    final user = context.watch<UserProvider>();
    final youWin =
        data.treasureHuntItems.length == user.userCompetitor!.treasures.length;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.homeTreasureBunt)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppStyles.cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppStyles.fontColor, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      youWin
                          ? AppStrings.homeTreasureBuntMsgYouWin
                          : AppStrings.homeTreasureBuntDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      youWin
                          ? AppAssetsPath.sparkyYouWin
                          : AppAssetsPath.firePedExplorerIcon,
                      fit: BoxFit.cover,
                      width: MediaQuery.sizeOf(context).width * 0.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (!data.loadingTreasureHunt)
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: data.treasureHuntItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  final item = data.treasureHuntItems[index];
                  final hasItem = user.userCompetitor!.treasures.contains(
                    item.uuid,
                  );
                  return Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          if (hasItem) {
                            showDialog(
                              context: context,
                              builder: (_) => ModalAnswerSuccess(item: item),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppStyles.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasItem
                                  ? AppStyles.colorBaseYellow
                                  : AppStyles.fontColor,
                              width: 6,
                            ),
                          ),
                          child: Image.asset(
                            item.imgPath,
                            color: !hasItem
                                ? AppStyles.fontSecondaryColor
                                : null,
                          ),
                        ),
                      ),
                      if (hasItem)
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                    ],
                  );
                },
              )
            else
              Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyles.colorBaseYellow,
        child: const Icon(Icons.qr_code_scanner, size: 32),
        onPressed: () async {
          var res = await Navigator.of(context).push<Barcode?>(
            MaterialPageRoute(
              builder: (context) =>
                  const QRScanContent(msg: AppStrings.homeTreasureBuntMsgScan),
            ),
          );
          final list = data.treasureHuntItems
              .where((element) => element.uuid == res?.code)
              .toList();
          if (list.isNotEmpty) {
            final key = list.first.uuid;
            if (!user.userCompetitor!.treasures.contains(key)) {
              if (context.mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QuestionTreasure(item: list.first),
                  ),
                );
              }
            } else {
              if (context.mounted) {
                customSnackbar(
                  context,
                  AppStrings.homeTreasureBuntMsgNotValid,
                  color: AppStyles.colorBaseGreen,
                );
              }
            }
          } else {
            if (context.mounted) {
              customSnackbar(
                context,
                AppStrings.homeTreasureBuntQrNotValid,
                color: AppStyles.colorBaseRed,
              );
            }
          }
        },
      ),
    );
  }
}

class QuestionTreasure extends StatefulWidget {
  const QuestionTreasure({super.key, required this.item});
  final TreasureHuntModel item;

  @override
  State<QuestionTreasure> createState() => _QuestionTreasureState();
}

class _QuestionTreasureState extends State<QuestionTreasure> {
  TextEditingController answerController = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ZoomIn(
              child: Container(
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppStyles.colorBaseYellow,
                    width: 6,
                  ),
                ),
                child: Image.asset(
                  widget.item.imgPath,
                  width: MediaQuery.sizeOf(context).width * 0.6,
                  // color: AppStyles.fontSecondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(widget.item.question, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: answerController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: AppStrings.homeTreasureBuntResponse,
              ),
            ),
            const SizedBox(height: 20),
            if (loading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.colorBaseBlue,
                ),
                onPressed: () async {
                  if (answerController.text.trim().isEmpty) return;
                  if (answerController.text.trim().toLowerCase() ==
                      widget.item.answer.toLowerCase()) {
                    final user = context.read<UserProvider>();
                    setState(() {
                      loading = true;
                    });
                    await user.addItemTreasure(widget.item.uuid);
                    if (context.mounted) {
                      await showDialog(
                        context: context,
                        builder: (_) => ModalAnswerSuccess(item: widget.item),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    }
                  } else {
                    customSnackbar(
                      context,
                      AppStrings.homeTreasureBuntTryAgain,
                      color: AppStyles.colorBaseRed,
                    );
                  }
                  // Navigator.of(context).pop();
                },
                child: const Text(
                  AppStrings.homeTreasureBuntConfirmAnswer,
                  style: TextStyle(color: AppStyles.fontColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ModalAnswerSuccess extends StatelessWidget {
  const ModalAnswerSuccess({
    super.key,
    required this.item,
    this.hasItem = false,
  });
  final TreasureHuntModel item;
  final bool hasItem;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
        hasItem ? item.title : AppStrings.homeTreasureBuntCongratulations,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppStyles.fontSecondaryColor,
        ),
      ),
      contentPadding: const EdgeInsets.all(12),
      children: [
        Text(
          "${AppStrings.homeTreasureBuntMsgTitle} ${item.title}",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppStyles.fontSecondaryColor),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: AppStyles.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: AppStyles.colorBaseYellow, width: 6),
          ),
          child: Image.asset(
            item.imgPath,
            width: MediaQuery.sizeOf(context).width * 0.5,
            // color: AppStyles.fontSecondaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          item.description,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppStyles.fontSecondaryColor),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.colorBaseBlue,
          ),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text(
            AppStrings.commonWordClose,
            style: TextStyle(color: AppStyles.fontColor),
          ),
        ),
      ],
    );
  }
}
