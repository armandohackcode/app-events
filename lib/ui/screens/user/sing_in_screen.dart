import 'dart:io';

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/sign_in_social_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: const Alignment(0, -1),
          children: [
            Stack(
              alignment: const Alignment(0.9, 0.9),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Align(
                      child: Image.asset(
                        AppAssetsPath.titleEvent,
                        width: MediaQuery.of(context).size.width * 0.7,
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    if (auth.loadingAuth)
                      const Center(child: CircularProgressIndicator())
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.85,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                                elevation: 0,
                                backgroundColor: AppStyles.backgroundColor,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: AppStyles.fontColor,
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              onPressed: () async {
                                await auth.googleAuth();
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  SvgPicture.asset(
                                    AppAssetsPath.iconGoogle,
                                    width: 32,
                                    height: 32,
                                  ),
                                  const Text(
                                    AppStrings.signInGoogleButton,
                                    style: TextStyle(
                                      color: AppStyles.fontColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (Platform.isIOS)
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(8),
                                  elevation: 0,
                                  backgroundColor: AppStyles.fontColor,
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      color: AppStyles.fontColor,
                                    ),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                onPressed: () async {
                                  // print("click");
                                  await auth.appleAuth();
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    SvgPicture.asset(
                                      AppAssetsPath.iconApple,
                                      width: 32,
                                      height: 32,
                                      colorFilter: const ColorFilter.mode(
                                        AppStyles.backgroundColor,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const Text(
                                      AppStrings.signInAppleButton,
                                      style: TextStyle(
                                        color: AppStyles.backgroundColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    // if (Platform.isIOS)
                    TextButton(
                      child: const Text(AppStrings.signInGDGAsk),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ModalGDG(),
                        );
                      },
                    ),
                  ],
                ),
                Image.asset(
                  AppAssetsPath.footerImage,
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(AppAssetsPath.headerImage),
            ),
          ],
        ),
      ),
    );
  }
}

class ModalGDG extends StatelessWidget {
  const ModalGDG({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(20),
      children: [
        Image.asset(
          AppAssetsPath.logoGDGSucre,
          width: MediaQuery.of(context).size.width * 0.4,
        ),
        const SizedBox(height: 20),
        const Text(
          AppStrings.signInGDGDescription,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppStyles.backgroundColor),
        ),
      ],
    );
  }
}
