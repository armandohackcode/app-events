import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/title_pill.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Pop-brutalist dialog displaying the attendee's personal connection QR code.
class ModalQrIdentify extends StatelessWidget {
  final String identify;

  const ModalQrIdentify({super.key, required this.identify});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: HardShadowBox(
                  color: AppStyles.cardColor,
                  radius: 22,
                  shadowOffset: 5,
                  borderWidth: 2.5,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(AppAssetsPath.logoGdg, height: 22),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              AppStrings.organizersGDGSucre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppStyles.fontColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      HardShadowBox(
                        color: AppStyles.cardColor,
                        radius: 16,
                        shadowOffset: 3,
                        borderWidth: 2,
                        padding: const EdgeInsets.all(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 210,
                            maxHeight: 210,
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: QrImageView(
                              data: identify,
                              backgroundColor: AppStyles.cardColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        AppStrings.profileQrModalHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.fontSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ChunkyButton(
                        label: AppStrings.commonWordClose,
                        color: AppStyles.colorBaseYellow,
                        expand: true,
                        minHeight: 44,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: TitlePill(
                    text: AppStrings.profileQrModalTitle,
                    color: AppStyles.colorBaseYellow,
                    angle: -1.5,
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
