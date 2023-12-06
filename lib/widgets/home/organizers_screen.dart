import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class OrganizersScreen extends StatefulWidget {
  const OrganizersScreen({super.key});

  @override
  State<OrganizersScreen> createState() => _OrganizersScreenState();
}

class _OrganizersScreenState extends State<OrganizersScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final data = Provider.of<DataCenter>(context, listen: false);
      if (data.organizers.isEmpty) {
        data.getOrganizer();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Equipo de Organización"),
      ),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        const CardComunity(),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            InkWell(
              child: SvgPicture.asset(
                "assets/img/facebook-1-svgrepo-com.svg",
                width: 60,
                height: 40,
              ),
              onTap: () async {
                await laucherUrlInfo("https://www.facebook.com/gdgsucre");
              },
            ),
            InkWell(
              child: SvgPicture.asset(
                "assets/img/instagram-2016-logo-svgrepo-com.svg",
                width: 60,
                height: 40,
              ),
              onTap: () async {
                await laucherUrlInfo("https://www.instagram.com/gdgsucre/");
              },
            ),
            InkWell(
              child: SvgPicture.asset(
                "assets/img/linkedin-svgrepo-com.svg",
                width: 60,
                height: 40,
              ),
              onTap: () async {
                await laucherUrlInfo(
                    "https://www.linkedin.com/showcase/google-developer-groups/about/");
              },
            ),
            InkWell(
              child: SvgPicture.asset(
                "assets/img/twitter-3-logo-svgrepo-com.svg",
                width: 60,
                height: 40,
              ),
              onTap: () async {
                await laucherUrlInfo("https://twitter.com/gdg_sucre");
              },
            )
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          children: [
            for (var item in data.organizers)
              Container(
                margin: const EdgeInsets.all(10),
                child: InkWell(
                  onTap: () async {
                    await laucherUrlInfo(item.link);
                  },
                  child: Column(
                    children: [
                      Stack(
                        alignment: const Alignment(0, 1),
                        children: [
                          ClipOval(
                            child: FadeInImage(
                                width: MediaQuery.of(context).size.width * 0.25,
                                placeholder: const AssetImage(
                                    "assets/img/gitgoogle-loading.gif"),
                                image: NetworkImage(item.photoUrl)),
                          ),
                          if (item.type >= 3)
                            Container(
                              padding: const EdgeInsets.all(2),
                              alignment: Alignment.center,
                              height: 20,
                              width: MediaQuery.of(context).size.width * 0.15,
                              decoration: BoxDecoration(
                                border: Border.all(),
                                color: AppStyles.colorBaseRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "LEAD",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ],
        )
      ]),
    );
  }
}

class CardComunity extends StatelessWidget {
  const CardComunity({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: const Alignment(0, 1),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(width: 3, color: AppStyles.colorBaseYellow),
                borderRadius: BorderRadius.circular(15)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  FadeInImage(
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.22,
                    // height: 320,
                    placeholder:
                        const AssetImage("assets/img/gitgoogle-loading.gif"),
                    image: const NetworkImage(
                        "https://firebasestorage.googleapis.com/v0/b/gdgsucre-events.appspot.com/o/grupal2.jpeg?alt=media&token=ed6cc452-c3ea-4247-a528-5159d9a2b094"),
                  ),
                  Container(
                    alignment: const Alignment(-1, 1),
                    padding: const EdgeInsets.all(10),
                    color: Colors.black.withOpacity(0.4),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.22,
                    child: const Text(
                      "GDG Sucre",
                      style: TextStyle(
                          color: AppStyles.fontColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.colorBaseYellow,
                shape: RoundedRectangleBorder(
                    side: const BorderSide(color: AppStyles.fontColor),
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              laucherUrlInfo("https://gdg.community.dev/gdg-sucre/");
            },
            child: const Text(
              "Ver más",
              style: TextStyle(color: AppStyles.fontColor),
            )),
      ],
    );
  }
}
