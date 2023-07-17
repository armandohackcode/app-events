import 'package:app_events/bloc/sign_in_social_network.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/widgets/card_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset('assets/img/logo.svg'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          CardContent(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 15, left: 10, right: 10, bottom: 10),
                  child: ClipOval(
                    child: Image.network(
                      auth.userInfo.photoURL!,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.23,
                      height: MediaQuery.of(context).size.width * 0.23,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.only(top: 10, bottom: 10, right: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Text(
                          auth.userInfo.displayName ?? "Anonimo",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.fontColor),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: const Text(
                          'Estudiante',
                          style: TextStyle(
                            color: AppStyles.fontColor,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '150',
                                  style: TextStyle(fontSize: 28),
                                ),
                                Text('Puntos', style: TextStyle(height: 0.6))
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  '28',
                                  style: TextStyle(fontSize: 28),
                                ),
                                Text('Conexiones',
                                    style: TextStyle(height: 0.6))
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: const Text(
                  'Acerca de mi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SvgPicture.asset(
                'assets/img/icon_edit.svg',
                width: 40,
                height: 40,
              )
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Hoy hablaremos de como se puede hacer  de la inteligencia artificial una herramienta, que todos podemos utilizar, el mundo del desarrollo es fascinante, y hoy con la ayuda de la inteligencia artificial, cada vez todo es mas posible. Hoy hablaremos de como se puede hacer  de la inteligencia artificial una herramienta, que todos podemos utilizar, el mundo del desarrollo es fascinante, y hoy con la ayuda de la inteligencia artificial, cada vez todo es mas posible',
          ),
          const SizedBox(height: 20),
          const Text(
            'Conexiones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const CardNetworking(),
          const CardNetworking()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppStyles.colorBaseBlue,
        child: const Icon(
          Icons.qr_code_scanner,
          size: 32,
        ),
        onPressed: () {},
      ),
      // bottomNavigationBar: const BottonCustomNavApp(),
    );
  }
}

class CardNetworking extends StatelessWidget {
  const CardNetworking({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: AppStyles.fontColor,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
          child: ClipOval(
            child: Image.network(
              'https://imgv3.fotor.com/images/gallery/Realistic-Male-Profile-Picture.jpg',
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width * 0.15,
              height: MediaQuery.of(context).size.width * 0.15,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width * 0.7,
          child: const Text(
            'Angen Villanueva Condo',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppStyles.fontColor),
          ),
        ),
      ]),
    );
  }
}
