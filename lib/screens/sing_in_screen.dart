import 'dart:io';

import 'package:app_events/bloc/sign_in_social_network.dart';
import 'package:app_events/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    return Scaffold(
      body: Stack(
        alignment: const Alignment(0, 1),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                child: SvgPicture.asset(
                  'assets/img/logo.svg',
                  width: MediaQuery.of(context).size.width * 0.85,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              if (auth.loadingAuth)
                const Center(
                  child: CircularProgressIndicator(),
                )
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
                              side:
                                  const BorderSide(color: AppStyles.fontColor),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () async {
                            await auth.googleAuth();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SvgPicture.asset('assets/img/icon-google.svg',
                                  width: 32, height: 32),
                              const Text(
                                "Iniciar sesión con Google",
                                style: TextStyle(color: AppStyles.fontColor),
                              )
                            ],
                          )),
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
                              side:
                                  const BorderSide(color: AppStyles.fontColor),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () async {
                            await auth.appleAuth();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SvgPicture.asset('assets/img/icon-apple.svg',
                                  width: 32, height: 32),
                              const Text(
                                "Iniciar sesión con Apple",
                                style:
                                    TextStyle(color: AppStyles.backgroundColor),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          Image.asset('assets/img/bottom_login_img.png')
        ],
      ),
    );
  }
}
