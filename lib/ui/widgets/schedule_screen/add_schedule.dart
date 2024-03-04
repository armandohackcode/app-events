import 'package:app_events/domain/bloc/data_center.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddSchedule extends StatefulWidget {
  const AddSchedule({super.key});

  @override
  State<AddSchedule> createState() => _AddScheduleState();
}

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
  final _twiter = TextEditingController();
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
    _twiter.dispose();
    _blog.dispose();

    super.dispose();
  }

  TextStyle textStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agregar Speaker o actividad"),
      ),
      body: Form(
        key: _keyForm,
        child: ListView(
          padding: const EdgeInsets.all(15),
          children: [
            Text("Taller/Conferencia/Actividad", style: textStyle),
            DropdownButtonFormField(
              dropdownColor: AppStyles.colorAppbar,
              value: type,
              items: const [
                DropdownMenuItem(value: "Taller", child: Text("Taller")),
                DropdownMenuItem(
                    value: "Conferencia", child: Text("Conferencia")),
                DropdownMenuItem(value: "Actividad", child: Text("Actividad")),
              ],
              onChanged: (value) {
                setState(() {
                  type = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Text("Area Técnica", style: textStyle),
            DropdownButtonFormField(
                value: technologyType,
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
                ],
                onChanged: (value) {
                  setState(() {
                    technologyType = value;
                  });
                }),
            const SizedBox(height: 10),
            Text("Título", style: textStyle),
            TextFormField(
              controller: _title,
            ),
            const SizedBox(height: 10),
            Text("Descripción", style: textStyle),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            Text("Nombre del Speaker", style: textStyle),
            TextFormField(
              controller: _name,
            ),
            const SizedBox(height: 10),
            Text("Profesión", style: textStyle),
            TextFormField(
              controller: _profession,
            ),
            const SizedBox(height: 10),
            Text("foto Url", style: textStyle),
            TextFormField(
              controller: _photoUrl,
            ),
            const SizedBox(height: 10),
            Text("Descripción profesional", style: textStyle),
            TextFormField(
              controller: _aboutMe,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 10),
            Text("Posición", style: textStyle),
            TextFormField(
              controller: _position,
            ),
            const SizedBox(height: 10),
            Text("Horario", style: textStyle),
            TextFormField(
              controller: _schedule,
            ),
            const SizedBox(height: 10),
            Text("Github", style: textStyle),
            TextFormField(
              controller: _github,
            ),
            const SizedBox(height: 10),
            Text("Instagram", style: textStyle),
            TextFormField(
              controller: _instagram,
            ),
            const SizedBox(height: 10),
            Text("Facebook", style: textStyle),
            TextFormField(
              controller: _facebook,
            ),
            const SizedBox(height: 10),
            Text("Linkedin", style: textStyle),
            TextFormField(
              controller: _linkedin,
            ),
            const SizedBox(height: 10),
            Text("Twitter", style: textStyle),
            TextFormField(
              controller: _twiter,
            ),
            const SizedBox(height: 10),
            Text("Blog", style: textStyle),
            TextFormField(
              controller: _blog,
            ),
            const SizedBox(height: 20),
            if (loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                  });
                  var listSocial = <SocialNetwork>[];
                  if (_github.text.isNotEmpty) {
                    listSocial
                        .add(SocialNetwork(type: "GITHUB", link: _github.text));
                  }
                  if (_instagram.text.isNotEmpty) {
                    listSocial.add(SocialNetwork(
                        type: "INSTAGRAM", link: _instagram.text));
                  }
                  if (_linkedin.text.isNotEmpty) {
                    listSocial.add(
                        SocialNetwork(type: "LINKEDIN", link: _linkedin.text));
                  }
                  if (_twiter.text.isNotEmpty) {
                    listSocial.add(
                        SocialNetwork(type: "TWITTER", link: _twiter.text));
                  }
                  if (_blog.text.isNotEmpty) {
                    listSocial
                        .add(SocialNetwork(type: "BLOG", link: _blog.text));
                  }
                  await dataCenter.addNewShedule(
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
                child: const Text("Guardar"),
              )
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
          child: SizedBox(
            child: Text(text),
          ),
        ),
      ],
    );
  }
}
