import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddSchedule extends StatefulWidget {
  const AddSchedule({super.key});

  @override
  State<AddSchedule> createState() => _AddScheduleState();
}

// TO DO : Refactor this form
class _AddScheduleState extends State<AddSchedule> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _name = TextEditingController();
  final _profession = TextEditingController();
  final _aboutMe = TextEditingController();
  final _photoUrl = TextEditingController();
  final _schedule = TextEditingController();
  final _position = TextEditingController();

  final _github = TextEditingController();
  final _facebook = TextEditingController();
  final _instagram = TextEditingController();
  final _linkedin = TextEditingController();
  final _twitter = TextEditingController();
  final _blog = TextEditingController();

  final _keyForm = GlobalKey<FormFieldState>();

  String? type;
  String? technologyType;
  bool loading = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _name.dispose();
    _profession.dispose();
    _aboutMe.dispose();
    _photoUrl.dispose();
    _schedule.dispose();
    _position.dispose();

    _github.dispose();
    _facebook.dispose();
    _instagram.dispose();
    _linkedin.dispose();
    _twitter.dispose();
    _blog.dispose();

    super.dispose();
  }

  TextStyle textStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<ScheduleProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scheduleAddSpeakerOrActivity),
      ),
      body: Form(
        key: _keyForm,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            Text(AppStrings.scheduleWorkshopTitle, style: textStyle),

            DropdownButtonFormField<String>(
              dropdownColor: AppStyles.colorAppbar,
              initialValue: type,
              items: EventTypeSpeaker.values
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e.value, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  type = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleArea, style: textStyle),
            DropdownButtonFormField(
              initialValue: technologyType,
              dropdownColor: AppStyles.colorAppbar,
              items: [
                DropdownMenuItem(
                  value: "Mobile",
                  child: _selectType("Mobile", AppStyles.colorBaseGreen),
                ),
                DropdownMenuItem(
                  value: "Web",
                  child: _selectType("Web", AppStyles.colorBaseBlue),
                ),
                DropdownMenuItem(
                  value: "Cloud",
                  child: _selectType("Cloud", AppStyles.colorBaseRed),
                ),
                DropdownMenuItem(
                  value: "IA",
                  child: _selectType("IA", AppStyles.colorBaseYellow),
                ),
                DropdownMenuItem(
                  value: "UI/UX",
                  child: _selectType("UI/UX", AppStyles.colorBasePurple),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  technologyType = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleTitle, style: textStyle),
            TextFormField(controller: _title),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleDescription, style: textStyle),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleNameSpeaker, style: textStyle),
            TextFormField(controller: _name),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleProfession, style: textStyle),
            TextFormField(controller: _profession),
            const SizedBox(height: 10),
            Text(AppStrings.schedulePhotoUrl, style: textStyle),
            TextFormField(controller: _photoUrl),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleDescriptionProfession, style: textStyle),
            TextFormField(
              controller: _aboutMe,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            Text(AppStrings.schedulePosition, style: textStyle),
            TextFormField(
              controller: _position,
              keyboardType: TextInputType.numberWithOptions(),
            ),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleHours, style: textStyle),
            TextFormField(controller: _schedule),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleGithub, style: textStyle),
            TextFormField(controller: _github),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleInstagram, style: textStyle),
            TextFormField(controller: _instagram),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleFacebook, style: textStyle),
            TextFormField(controller: _facebook),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleLinkedIn, style: textStyle),
            TextFormField(controller: _linkedin),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleTwitter, style: textStyle),
            TextFormField(controller: _twitter),
            const SizedBox(height: 10),
            Text(AppStrings.scheduleBlog, style: textStyle),
            TextFormField(controller: _blog),
            const SizedBox(height: 20),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                  });
                  var listSocial = <SocialNetwork>[];
                  if (_github.text.isNotEmpty) {
                    listSocial.add(
                      SocialNetwork(type: "GITHUB", link: _github.text),
                    );
                  }
                  if (_instagram.text.isNotEmpty) {
                    listSocial.add(
                      SocialNetwork(type: "INSTAGRAM", link: _instagram.text),
                    );
                  }
                  if (_linkedin.text.isNotEmpty) {
                    listSocial.add(
                      SocialNetwork(type: "LINKEDIN", link: _linkedin.text),
                    );
                  }
                  if (_twitter.text.isNotEmpty) {
                    listSocial.add(
                      SocialNetwork(type: "TWITTER", link: _twitter.text),
                    );
                  }
                  if (_blog.text.isNotEmpty) {
                    listSocial.add(
                      SocialNetwork(type: "BLOG", link: _blog.text),
                    );
                  }
                  await data.addNewSchedule(
                    Speaker(
                      uuid: const Uuid().v1(),
                      title: _title.text,
                      description: _description.text,
                      name: _name.text,
                      profession: _profession.text,
                      aboutMe: _aboutMe.text,
                      photoUrl: _photoUrl.text,
                      technologyType: technologyType ?? "",
                      type: type ?? "",
                      color: "",
                      schedule: _schedule.text,
                      position: int.tryParse(_position.text) ?? 0,
                      socialNetwork: listSocial,
                    ),
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text(AppStrings.commonWordSave),
              ),
          ],
        ),
      ),
    );
  }

  Row _selectType(String text, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(child: Text(text)),
        ),
      ],
    );
  }
}
