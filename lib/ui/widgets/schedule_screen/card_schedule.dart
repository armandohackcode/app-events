import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CardSchedule extends StatelessWidget {
  final Speaker info;
  final bool showTitle;
  final bool action;
  final VoidCallback? onTap;

  const CardSchedule({
    required this.info,
    this.showTitle = false,
    this.action = true,
    this.onTap,
    super.key,
  });

  Color colorTag(String area) {
    switch (area) {
      case "Mobile":
        return AppStyles.colorBaseGreen;
      case "IA":
        return AppStyles.colorBaseYellow;
      case "Cloud":
        return AppStyles.colorBaseRed;
      case "Web":
        return AppStyles.colorBaseBlue;
      case "UI/UX":
        return AppStyles.colorBasePurple;
      default:
        return AppStyles.colorBaseRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextButton(
        onPressed: action ? onTap : null,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: const Alignment(1, 1),
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyles.fontColor, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 0.5,
                      child: FadeInImage(
                        placeholder: const AssetImage(
                          AppAssetsPath.loadingSmallImage,
                        ),
                        image: CachedNetworkImageProvider(info.photoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorTag(info.technologyType),
                        border: Border.all(color: AppStyles.fontColor),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                        ),
                      ),
                      child: Text(
                        info.technologyType,
                        style: const TextStyle(
                          color: AppStyles.fontColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppStyles.colorBaseRed,
                        border: Border.all(color: AppStyles.fontColor),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: Text(
                        '${info.type} | ${info.schedule}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: AppStyles.fontColor,
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: 5, bottom: 10, right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      info.title,
                      maxLines: showTitle ? 8 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.fontColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(
                      info.name,
                      style: const TextStyle(
                        color: AppStyles.fontColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Text(
                      info.profession,
                      style: const TextStyle(
                        color: AppStyles.fontSecondaryColor,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
