import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

// TO DO : Refactor this form
class _EditProfileState extends State<EditProfile> {
  final _name = TextEditingController();
  final _aboutMe = TextEditingController();
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
      final data = Provider.of<UserProvider>(context, listen: false);
      var info = data.userCompetitor!;
      setState(() {
        _name.text = info.name;
        _aboutMe.text = info.aboutMe;
        _profession.text = info.profession;
        for (var element in info.socialNetwork) {
          if (element.type == "GITHUB") {
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
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _aboutMe.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _github.dispose();
    _linkedin.dispose();
    _profession.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileEditProfile)),
      body: Form(
        key: keyForm,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            Text("${AppStrings.profileEditProfile} *", style: textStyle()),
            TextFormField(
              controller: _name,
              validator: (value) {
                if (value!.isEmpty) {
                  return AppStrings.profileNameValidate;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(AppStrings.profileProfession, style: textStyle()),
            TextFormField(
              controller: _profession,
              validator: (value) {
                if (value!.isEmpty) {
                  return AppStrings.profileProfessionValidate;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text("${AppStrings.profileAboutMe} *", style: textStyle()),
            const Text(AppStrings.profileAboutMeHint),
            TextFormField(
              controller: _aboutMe,
              maxLength: 400,
              maxLines: 4,
              validator: (value) {
                if (value!.isEmpty) {
                  return AppStrings.profileAboutMeValidate;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            const Text(AppStrings.profileSocialNetworksHint),
            const SizedBox(height: 10),
            Text(AppStrings.profileFacebook, style: textStyle()),
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
                    return AppStrings.profileFacebookValidate;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(AppStrings.profileInstagram, style: textStyle()),
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
                    return AppStrings.profileInstagramValidate;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(AppStrings.profileGithub, style: textStyle()),
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
                    return AppStrings.profileGithubValidate;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Text(AppStrings.profileLinkedIn, style: textStyle()),
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
                    return AppStrings.profileLinkedInValidate;
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

                  /// user completes his profile
                  if (_aboutMe.text.length >= 200 &&
                      data.userCompetitor!.scoreProfile == false) {
                    score = score + 20;
                    data.userCompetitor = data.userCompetitor!.copyWith(
                      scoreProfile: true,
                    );
                  }

                  /// user deleted his profile
                  if (_aboutMe.text.length < 200 &&
                      data.userCompetitor!.scoreProfile) {
                    score = score - 20;
                    data.userCompetitor = data.userCompetitor!.copyWith(
                      scoreProfile: false,
                    );
                    (score < 0) ? 0 : score;
                  }

                  // TO DO : Use a enum type for social networks

                  var socialNetworks = <SocialNetwork>[];

                  if (_linkedin.text != "https://www.linkedin.com/in/" &&
                      _linkedin.text.isNotEmpty) {
                    socialNetworks.add(
                      SocialNetwork(type: "LINKEDIN", link: _linkedin.text),
                    );
                  }
                  if (_github.text != "https://github.com/" &&
                      _github.text.isNotEmpty) {
                    socialNetworks.add(
                      SocialNetwork(type: "GITHUB", link: _github.text),
                    );
                  }
                  if (_instagram.text != "https://www.instagram.com/" &&
                      _instagram.text.isNotEmpty) {
                    socialNetworks.add(
                      SocialNetwork(type: "INSTAGRAM", link: _instagram.text),
                    );
                  }
                  if (_facebook.text != "https://www.facebook.com/" &&
                      _facebook.text.isNotEmpty) {
                    socialNetworks.add(
                      SocialNetwork(type: "FACEBOOK", link: _facebook.text),
                    );
                  }

                  /// Reduce the score assigned by previous social networks
                  score = score - data.userCompetitor!.socialNetwork.length * 3;
                  // print(score);

                  /// New score assigned by social networks
                  score = score + socialNetworks.length * 3;
                  // print(score);
                  var user = data.userCompetitor!.copyWith(
                    score: score,
                    name: _name.text,
                    profession: _profession.text,
                    aboutMe: _aboutMe.text,
                    socialNetwork: socialNetworks,
                  );
                  await data.editCompetitor(user);
                  if (context.mounted) {
                    Navigator.pop(
                      context,
                      (_aboutMe.text.length >= 200) ? true : false,
                    );
                  }
                }
              },
              child: const Text(AppStrings.commonWordSave),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle textStyle() =>
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
}
