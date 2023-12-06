import 'dart:async';
import 'dart:io';

import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/bloc/sign_in_social_network.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/models/user_competitor.dart';
import 'package:app_events/screens/delete_account.dart';
import 'package:app_events/screens/home.dart';
import 'package:app_events/widgets/card_content.dart';
import 'package:app_events/widgets/profile/edit_profile.dart';
import 'package:app_events/widgets/profile/modal_qr_identify.dart';
import 'package:app_events/widgets/profile/profile_friend.dart';
import 'package:app_events/widgets/profile/profile_public.dart';
// import 'package:app_events/widgets/utils/qr_scan_content.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription? _sub;
  // StreamSubscription? _sub2;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // print("Ejecutando init");
      final data = Provider.of<DataCenter>(context, listen: false);
      if (data.userCompetitor != null) {
        _sub = data.streamInfoUser().listen((event) {
          // print("Emitiendo");
          // print(event.data() != null);
          if (event.data() != null) {
            data.userCompetitor = UserCompetitor.fromJson(event.data()!);
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    // _sub2?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<SignInSocialNetworkProvider>(context);
    final data = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/img/title-devfest.png'),
        actions: [
          IconButton(
              onPressed: () async {
                await auth.logOut();
                data.userCompetitor = null;
                auth.isAuth = false;
              },
              icon: const Icon(
                Icons.output,
                color: AppStyles.fontColor,
                size: 32,
              )),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          HeaderProfile(auth: auth),
          const SizedBox(height: 20),
          if (data.userCompetitor != null) const BodyProfile()
        ],
      ),
      floatingActionButton:
          (data.userCompetitor != null) ? const ButtonScan() : null,
      // bottomNavigationBar: const BottonCustomNavApp(),
    );
  }
}

class HeaderProfile extends StatelessWidget {
  const HeaderProfile({
    super.key,
    required this.auth,
  });

  final SignInSocialNetworkProvider auth;

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataCenter>(context);
    return CardContent(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 15, left: 10, right: 10, bottom: 10),
            child: ClipOval(
              child: (auth.userInfo.photoURL != null)
                  ? Image.network(
                      auth.userInfo.photoURL!,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.23,
                      height: MediaQuery.of(context).size.width * 0.23,
                    )
                  : Image.asset(
                      "assets/img/fire-ped.png",
                      // fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.23,
                      height: MediaQuery.of(context).size.width * 0.23,
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    data.userCompetitor?.name ??
                        auth.userInfo.displayName ??
                        "Anonimo",
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
                  child: Text(
                    data.userCompetitor?.profession ?? '-',
                    style: const TextStyle(
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
                        children: [
                          Text(
                            (data.userCompetitor?.score ?? 0).toString(),
                            style: const TextStyle(fontSize: 28),
                          ),
                          const Text(
                            'Puntos',
                            style: TextStyle(height: 0.6),
                          )
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (data.userCompetitor?.friends.length ?? 0)
                                .toString(),
                            style: const TextStyle(fontSize: 28),
                          ),
                          const Text('Conexiones',
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
    );
  }
}

class BodyProfile extends StatelessWidget {
  const BodyProfile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataCenter>(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: const Text(
                'Acerca de mí',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (data.userCompetitor!.uuid.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () async {
                  showDialog(
                      context: context,
                      builder: (_) =>
                          ModalQrIdentify(identify: data.userCompetitor!.uuid));
                },
                child: const Icon(
                  Icons.qr_code_outlined,
                  size: 32,
                  color: AppStyles.fontColor,
                ),
              ),
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () async {
                showDialog(
                    context: context,
                    builder: (_) =>
                        ModalProfilePublic(user: data.userCompetitor!));
              },
              child: SvgPicture.asset('assets/img/receipt-svgrepo-com.svg',
                  width: 45,
                  height: 45,
                  colorFilter: const ColorFilter.mode(
                      AppStyles.fontColor, BlendMode.srcIn)),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () async {
                var res = await Navigator.of(context).push<bool?>(
                  CupertinoPageRoute(
                    builder: (_) => const EditProfile(),
                  ),
                );
                if (res == true && context.mounted) {
                  customSnackbar(
                      context, "Feliciadades, ganastes los puntos extras");
                }
              },
              child: SvgPicture.asset('assets/img/icon_edit.svg',
                  width: 45,
                  height: 45,
                  colorFilter: const ColorFilter.mode(
                      AppStyles.fontColor, BlendMode.srcIn)),
            ),
            if (Platform.isIOS)
              Tooltip(
                message: "Eliminar cuenta",
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () async {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const DeleteAccount()));
                  },
                  child: const Icon(
                    Icons.delete_forever_outlined,
                    size: 32,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (data.userCompetitor!.aboutMe != "")
          Column(
            children: [
              Text(data.userCompetitor!.aboutMe),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var item in data.userCompetitor!.socialNetwork)
                    SizedBox(
                      child: InkWell(
                        child: SvgPicture.asset(
                          getSVG(item),
                          width: 60,
                          height: 40,
                          colorFilter: const ColorFilter.mode(
                              AppStyles.fontColor, BlendMode.srcIn),
                        ),
                        onTap: () async {
                          await laucherUrlInfo(item.link);
                        },
                      ),
                    )
                ],
              )
            ],
          )
        else
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/img/dino-write.png',
                  height: 150,
                ),
                const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    "Deja que el mundo te conozca, escribe algo sobre tí mismo 😊 y gana puntos, completa tu información en la sección de editar Perfil. 📝",
                    textAlign: TextAlign.center,
                  ),
                )
              ],
            ),
          ),
        const SizedBox(height: 20),
        // if (data.userCompetitor!.tokenAutorization.isEmpty)
        //   Center(
        //     child: ElevatedButton.icon(
        //       style: ElevatedButton.styleFrom(
        //         shape: RoundedRectangleBorder(
        //           side: const BorderSide(
        //             width: 1.5,
        //           ),
        //           borderRadius: BorderRadius.circular(15),
        //         ),
        //       ),
        //       onPressed: () async {
        //         var res = await Navigator.of(context).push<Barcode?>(
        //           MaterialPageRoute(
        //             builder: (context) => const QRScanContent(),
        //           ),
        //         );
        //         if (res != null) {
        //           if (context.mounted) {
        //             customSnackbar(context, "Habilitando usuario...");
        //             await data.updateToken(res.code!);
        //           }
        //         }
        //       },
        //       icon: SvgPicture.asset('assets/img/gamepad-svgrepo-com.svg',
        //           width: 60,
        //           height: 60,
        //           colorFilter:
        //               const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        //       label: const Text(
        //         "Empezar a Jugar",
        //         style: TextStyle(fontSize: 22),
        //       ),
        //     ),
        //   ),
        if (data.userCompetitor!.friends.isNotEmpty)
          const Text(
            'Conexiones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 10),
        for (var item in data.userCompetitor!.friends)
          CardNetworking(friend: item),
        const SizedBox(height: 60),
      ],
    );
  }
}

class CardNetworking extends StatelessWidget {
  final Friend friend;
  const CardNetworking({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
            context: context,
            builder: (_) => ModalProfileFriend(uuid: friend.uuid));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: AppStyles.fontColor,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
            child: ClipOval(
              // child: Image.network(
              //   'https://imgv3.fotor.com/images/gallery/Realistic-Male-Profile-Picture.jpg',
              //   fit: BoxFit.cover,
              //   width: MediaQuery.of(context).size.width * 0.15,
              //   height: MediaQuery.of(context).size.width * 0.15,
              // ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.15,
                height: MediaQuery.of(context).size.width * 0.15,
                child: (friend.photoUrl.isEmpty)
                    ? Image.asset("assets/img/dino-runs.png")
                    : FadeInImage(
                        placeholder: const AssetImage(
                            "assets/img/gitgoogle-loading.gif"),
                        image: NetworkImage(friend.photoUrl)),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width * 0.7,
            child: Text(
              friend.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppStyles.fontColor),
            ),
          ),
        ]),
      ),
    );
  }
}
