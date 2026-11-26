import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/sign_in/sign_in_auth_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main pop-brutalist sign-in card containing welcome copy, social login
/// buttons, and the GDG info modal link.
class SignInCard extends StatelessWidget {
  final VoidCallback onOpenInfoModal;

  const SignInCard({super.key, required this.onOpenInfoModal});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return HardShadowBox(
      color: AppStyles.cardColor,
      radius: 24,
      borderWidth: 2,
      shadowOffset: 5,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            AppStrings.signInTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppStyles.fontColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            AppStrings.signInSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppStyles.fontSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          if (auth.loadingAuth)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SignInAuthButton(
              label: AppStrings.signInGoogleButton,
              iconAssetPath: AppAssetsPath.iconGoogle,
              backgroundColor: AppStyles.cardColor,
              foregroundColor: AppStyles.fontColor,
              shadowHeight: 3,
              onPressed: auth.googleAuth,
            ),
            if (isIos) ...[
              const SizedBox(height: 14),
              SignInAuthButton(
                label: AppStrings.signInAppleButton,
                iconAssetPath: AppAssetsPath.iconApple,
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: AppStyles.onAccentColor,
                tintIcon: true,
                onPressed: auth.appleAuth,
              ),
            ],
          ],
          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: AppStyles.dividerColor),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onOpenInfoModal,
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.colorBaseBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.help_outline_rounded, size: 18),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppStrings.signInGDGAsk,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
