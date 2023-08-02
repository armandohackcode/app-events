import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/models/speaker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _name = TextEditingController();
  final _aboutme = TextEditingController();
  final _profession = TextEditingController();
  final _facebook = TextEditingController(text: "https://www.facebook.com/");
  final _instagram = TextEditingController(text: "https://www.instagram.com/");
  final _github = TextEditingController(text: "https://github.com/");
  final _linkedin = TextEditingController(text: "https://www.linkedin.com/in/");

  final keyForm = GlobalKey<FormState>();
  bool loading = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final data = Provider.of<DataCenter>(context, listen: false);
      var info = data.userCompetitor!;
      setState(
        () {
          _name.text = info.name;
          _aboutme.text = info.aboutMe;
          _profession.text = info.profession;
          for (var element in info.socialNetwork) {
            if (element.type == "GITGUB") {
              _github.text = element.link;
            }
            if (element.type == "FACEBOOK") {
              _facebook.text = element.link;
            }
            if (element.type == "INSTAGRAM") {
              _instagram.text = element.link;
            }
            if (element.type == "LINKEDIN") {
              _linkedin.text = element.link;
            }
          }
        },
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _aboutme.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _github.dispose();
    _linkedin.dispose();
    _profession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<DataCenter>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
      ),
      body: Form(
        key: keyForm,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            Text(
              "Nombre *",
              style: textStyle(),
            ),
            TextFormField(
              controller: _name,
              validator: (value) {
                if (value!.isEmpty) {
                  return "El nombre es requerido";
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              "Profesión u ocupación *",
              style: textStyle(),
            ),
            TextFormField(
              controller: _profession,
              validator: (value) {
                if (value!.isEmpty) {
                  return "El campo es requerido";
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              "Acerca de mi *",
              style: textStyle(),
            ),
            const Text(
              "Cuentanos algo sobre tí, tienes que usar como minimo 200 catacteres, para ganar los puntos de esta sección",
            ),
            TextFormField(
              controller: _aboutme,
              maxLength: 400,
              maxLines: 4,
              validator: (value) {
                if (value!.isEmpty) {
                  return "El campo es requerido";
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            const Text(
              "Añade como mínimo una red social para ganar puntos extra, el link tiene que ser real",
            ),
            const SizedBox(height: 10),
            Text(
              "Facebook URL",
              style: textStyle(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _facebook,
              validator: (value) {
                if (value != "https://www.facebook.com/" && value!.isNotEmpty) {
                  RegExp facebookRegex = RegExp(
                    r"^(?:https?:\/\/)?(?:www\.|m\.)?facebook\.com\/.+",
                    caseSensitive: false,
                  );
                  if (!facebookRegex.hasMatch(value)) {
                    return 'Ingrese un enlace de Facebook válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              "Instrgram URL",
              style: textStyle(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _instagram,
              validator: (value) {
                if (value != "https://www.instagram.com/" &&
                    value!.isNotEmpty) {
                  RegExp instagramRegex = RegExp(
                    r"^(?:https?:\/\/)?(?:www\.)?instagram\.com\/[a-zA-Z0-9_\.]+\/?$",
                    caseSensitive: false,
                  );
                  if (!instagramRegex.hasMatch(value)) {
                    return 'Ingrese un enlace de Instagram válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              "Github URL",
              style: textStyle(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _github,
              validator: (value) {
                if (value != "https://github.com/" && value!.isNotEmpty) {
                  RegExp githubRegex = RegExp(
                    r"^(?:https?:\/\/)?(?:www\.)?github\.com\/[a-zA-Z0-9_-]+\/?[a-zA-Z0-9_\-\/]+?$",
                    caseSensitive: false,
                  );
                  if (!githubRegex.hasMatch(value)) {
                    return 'Ingrese un enlace de GitHub válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(
              "Linkedin URL",
              style: textStyle(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _linkedin,
              validator: (value) {
                if (value != "https://www.linkedin.com/in/" &&
                    value!.isNotEmpty) {
                  RegExp linkedinRegex = RegExp(
                    r"^(?:https?:\/\/)?(?:www\.)?linkedin\.com\/in\/[a-zA-Z0-9_-]+\/?$",
                    caseSensitive: false,
                  );
                  if (!linkedinRegex.hasMatch(value)) {
                    return 'Ingrese un enlace de LinkedIn válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () async {
                  if (keyForm.currentState!.validate()) {
                    setState(() {
                      loading = true;
                    });
                    int score = data.userCompetitor!.score;
                    print(score);

                    /// usuario completo su perfil
                    if (_aboutme.text.length >= 200 &&
                        data.userCompetitor!.scoreProfile == false) {
                      score = score + 20;
                      data.userCompetitor =
                          data.userCompetitor!.copyWith(scoreProfile: true);
                    }
                    print(score);

                    /// usuario borro su perfil
                    if (_aboutme.text.length < 200 &&
                        data.userCompetitor!.scoreProfile) {
                      score = score - 20;
                      data.userCompetitor =
                          data.userCompetitor!.copyWith(scoreProfile: false);
                      (score < 0) ? 0 : score;
                    }
                    print(score);
                    var socialNerwors = <SocialNetwork>[];

                    if (_linkedin.text != "https://www.linkedin.com/in/" &&
                        _linkedin.text.isNotEmpty) {
                      socialNerwors.add(SocialNetwork(
                          type: "LINKEDIN", link: _linkedin.text));
                    }
                    if (_github.text != "https://github.com/" &&
                        _github.text.isNotEmpty) {
                      socialNerwors.add(
                          SocialNetwork(type: "GITHUB", link: _github.text));
                    }
                    if (_instagram.text != "https://www.instagram.com/" &&
                        _instagram.text.isNotEmpty) {
                      socialNerwors.add(SocialNetwork(
                          type: "INSTAGRAM", link: _instagram.text));
                    }
                    if (_facebook.text != "https://www.facebook.com/" &&
                        _facebook.text.isNotEmpty) {
                      socialNerwors.add(SocialNetwork(
                          type: "FACEBOOK", link: _facebook.text));
                    }
                    print(score);

                    /// reduce el score asigando por redes sociales anterior
                    score =
                        score - data.userCompetitor!.socialNetwork.length * 3;
                    print(score);

                    /// Nuevo score asigando por redes sociales
                    score = score + socialNerwors.length * 3;
                    print(score);
                    var user = data.userCompetitor!.copyWith(
                      score: score,
                      name: _name.text,
                      profession: _profession.text,
                      aboutMe: _aboutme.text,
                      socialNetwork: socialNerwors,
                    );
                    await data.editCompetitor(user);
                    if (context.mounted) {
                      Navigator.pop(context,
                          (_aboutme.text.length >= 200) ? true : false);
                    }
                  }
                },
                child: const Text("Guardar")),
          ],
        ),
      ),
    );
  }

  TextStyle textStyle() =>
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
}
