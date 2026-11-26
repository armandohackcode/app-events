import 'dart:math' as math;

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/home/home_backdrop.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/sign_in/devfest_logo.dart';
import 'package:app_events/ui/widgets/sign_in/event_schedule_badge.dart';
import 'package:app_events/ui/widgets/sign_in/sign_in_card.dart';
import 'package:app_events/ui/widgets/sign_in/sign_in_footer.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  static const double _maxContentWidth = 420;

  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.homeBackgroundColor,
      body: HomeBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const horizontalPadding = 20.0;
              const verticalPadding = 18.0;
              final contentWidth = math.min(
                _maxContentWidth,
                math.max(0.0, constraints.maxWidth - horizontalPadding * 2),
              );
              final minHeight = math.max(
                0.0,
                constraints.maxHeight - verticalPadding * 2,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: contentWidth,
                      maxWidth: contentWidth,
                      minHeight: minHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Center(child: EventScheduleBadge()),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: DevFestLogo()),
                            const SizedBox(height: 28),
                            SignInCard(
                              onOpenInfoModal: () => showDialog<void>(
                                context: context,
                                builder: (_) => const ModalGDG(),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: SignInFooter(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ModalGDG extends StatelessWidget {
  const ModalGDG({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 5, bottom: 5),
          child: HardShadowBox(
            color: AppStyles.cardColor,
            radius: 24,
            shadowOffset: 5,
            borderWidth: 2.5,
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppAssetsPath.logoGdg, height: 28),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        AppStrings.organizersGDGSucre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppStyles.fontColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.signInGDGDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppStyles.fontSecondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                ChunkyButton(
                  label: AppStrings.commonWordClose,
                  color: AppStyles.colorBaseYellow,
                  expand: true,
                  minHeight: 46,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
