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
        alignment: const Alignment(0, -1),
        children: [
          Stack(
            alignment: const Alignment(1, 1),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2,
                  ),
                  Image.asset(
                    'assets/img/comunity.png',
                    height: MediaQuery.of(context).size.height * 0.08,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    child: SvgPicture.asset(
                      'assets/img/logo-devfest.svg',
                      width: MediaQuery.of(context).size.width * 0.65,
                    ),
                  ),
                  if (Platform.isIOS)
                    TextButton(
                      child: const Text(
                        "¿Qué es un Google Developer Groups?",
                      ),
                      onPressed: () {
                        showDialog(
                            context: context, builder: (_) => const ModalGDG());
                      },
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
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
                                  side: const BorderSide(
                                      color: AppStyles.fontColor),
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
                                  SvgPicture.asset('assets/img/icon-google.svg',
                                      width: 32, height: 32),
                                  const Text(
                                    "Iniciar sesión con Google",
                                    style:
                                        TextStyle(color: AppStyles.fontColor),
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
                                  side: const BorderSide(
                                      color: AppStyles.fontColor),
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
                                    'assets/img/icon-apple.svg',
                                    width: 32,
                                    height: 32,
                                    colorFilter: const ColorFilter.mode(
                                        AppStyles.backgroundColor,
                                        BlendMode.srcIn),
                                  ),
                                  const Text(
                                    "Iniciar sesión con Apple",
                                    style: TextStyle(
                                        color: AppStyles.backgroundColor),
                                  )
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              Image.asset(
                'assets/img/devfest-footer.png',
                height: MediaQuery.of(context).size.height * 0.1,
              )
            ],
          ),
          Image.asset('assets/img/devfest-header.png'),
        ],
      ),
    );
  }
}

class ModalGDG extends StatelessWidget {
  const ModalGDG({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(20),
      children: [
        Image.asset(
          'assets/img/gdgsucre-logo.png',
          width: MediaQuery.of(context).size.width * 0.4,
        ),
        const SizedBox(
          height: 20,
        ),
        const Text(
          'El "Google Developer Groups Sucre", es una comunidad sin fines de lucro de desarrolladores con enfoque al uso de las tecnologías de desarrollo de Google en Bolivia. No es una herramienta oficial de Google, esta aplicación está diseñada específicamente para ofrecer información detallada sobre los eventos que organizamos en Sucre, Bolivia. Descubre todo sobre nuestros eventos, mantente actualizado sobre las últimas tecnologías de Google, comparte conocimientos y conecta con la comunidad. Únete a nosotros mientras exploramos juntos las oportunidades emocionantes que ofrece el mundo de la tecnología y la innovación.',
          style: TextStyle(color: AppStyles.backgroundColor),
        ),
      ],
    );
  }
}
