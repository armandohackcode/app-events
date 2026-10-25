import 'dart:io';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speaker.dart';
import 'package:app_events/ui/providers/schedule_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditSchedule extends StatefulWidget {
  final String eventId;
  final Speaker info;
  const EditSchedule({super.key, required this.eventId, required this.info});

  @override
  State<EditSchedule> createState() => _EditScheduleState();
}

class _EditScheduleState extends State<EditSchedule> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _name;
  late final TextEditingController _profession;
  late final TextEditingController _aboutMe;
  late final TextEditingController _schedule;
  late final TextEditingController _position;
  late final TextEditingController _github;
  late final TextEditingController _facebook;
  late final TextEditingController _instagram;
  late final TextEditingController _linkedin;
  late final TextEditingController _twitter;
  late final TextEditingController _blog;

  late String? _type;
  late String? _technologyType;
  String? _newImagePath;
  bool _loading = false;

  String _linkFor(String type) => widget.info.socialNetwork
      .firstWhere(
        (s) => s.type == type,
        orElse: () => SocialNetwork(type: type, link: ''),
      )
      .link;

  @override
  void initState() {
    super.initState();
    final s = widget.info;
    _title = TextEditingController(text: s.title);
    _description = TextEditingController(text: s.description);
    _name = TextEditingController(text: s.name);
    _profession = TextEditingController(text: s.profession);
    _aboutMe = TextEditingController(text: s.aboutMe);
    _schedule = TextEditingController(text: s.schedule);
    _position = TextEditingController(text: s.position.toString());
    _github = TextEditingController(text: _linkFor('GITHUB'));
    _facebook = TextEditingController(text: _linkFor('FACEBOOK'));
    _instagram = TextEditingController(text: _linkFor('INSTAGRAM'));
    _linkedin = TextEditingController(text: _linkFor('LINKEDIN'));
    _twitter = TextEditingController(text: _linkFor('TWITTER'));
    _blog = TextEditingController(text: _linkFor('BLOG'));
    _type = s.type.isEmpty ? null : s.type;
    _technologyType = s.technologyType.isEmpty ? null : s.technologyType;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _name,
      _profession,
      _aboutMe,
      _schedule,
      _position,
      _github,
      _facebook,
      _instagram,
      _linkedin,
      _twitter,
      _blog,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  final _labelStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _newImagePath = picked.path);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final social = <SocialNetwork>[
      if (_github.text.isNotEmpty)
        SocialNetwork(type: 'GITHUB', link: _github.text),
      if (_instagram.text.isNotEmpty)
        SocialNetwork(type: 'INSTAGRAM', link: _instagram.text),
      if (_linkedin.text.isNotEmpty)
        SocialNetwork(type: 'LINKEDIN', link: _linkedin.text),
      if (_twitter.text.isNotEmpty)
        SocialNetwork(type: 'TWITTER', link: _twitter.text),
      if (_blog.text.isNotEmpty) SocialNetwork(type: 'BLOG', link: _blog.text),
      if (_facebook.text.isNotEmpty)
        SocialNetwork(type: 'FACEBOOK', link: _facebook.text),
    ];
    final updated = widget.info.copyWith(
      title: _title.text,
      description: _description.text,
      name: _name.text,
      profession: _profession.text,
      aboutMe: _aboutMe.text,
      schedule: _schedule.text,
      position: int.tryParse(_position.text) ?? widget.info.position,
      type: _type ?? widget.info.type,
      technologyType: _technologyType ?? widget.info.technologyType,
      socialNetwork: social,
    );
    final scheduleProvider = Provider.of<ScheduleProvider>(
      context,
      listen: false,
    );
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await scheduleProvider.updateSchedule(
      widget.eventId,
      updated,
      imagePath: _newImagePath,
    );
    setState(() => _loading = false);
    nav.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.scheduleUpdateSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.scheduleEditEntry)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Text(AppStrings.scheduleWorkshopTitle, style: _labelStyle),
          DropdownButtonFormField<String>(
            dropdownColor: AppStyles.colorAppbar,
            initialValue: _type,
            items: EventTypeSpeaker.values
                .map(
                  (e) => DropdownMenuItem(value: e.value, child: Text(e.value)),
                )
                .toList(),
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleArea, style: _labelStyle),
          DropdownButtonFormField<String>(
            dropdownColor: AppStyles.colorAppbar,
            initialValue: _technologyType,
            items: [
              for (final entry in const {
                'Mobile': AppStyles.colorBaseGreen,
                'Web': AppStyles.colorBaseBlue,
                'Cloud': AppStyles.colorBaseRed,
                'IA': AppStyles.colorBaseYellow,
                'UI/UX': AppStyles.colorBasePurple,
              }.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: entry.value),
                      const SizedBox(width: 10),
                      Text(entry.key),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _technologyType = v),
          ),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleTitle, style: _labelStyle),
          TextFormField(controller: _title),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleDescription, style: _labelStyle),
          TextFormField(
            controller: _description,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleNameSpeaker, style: _labelStyle),
          TextFormField(controller: _name),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleProfession, style: _labelStyle),
          TextFormField(controller: _profession),
          const SizedBox(height: 16),
          Text(AppStrings.schedulePhotoUrl, style: _labelStyle),
          const SizedBox(height: 8),
          _PhotoPreview(
            newImagePath: _newImagePath,
            existingPhotoUrl: widget.info.photoUrl,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(
              _newImagePath == null && widget.info.photoUrl.isEmpty
                  ? Icons.add_photo_alternate
                  : Icons.edit,
              size: 18,
            ),
            label: Text(
              _newImagePath == null && widget.info.photoUrl.isEmpty
                  ? AppStrings.eventSelectImage
                  : AppStrings.eventChangeImage,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppStyles.colorBaseBlue,
              side: const BorderSide(color: AppStyles.colorBaseBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _pickImage,
          ),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleDescriptionProfession, style: _labelStyle),
          TextFormField(
            controller: _aboutMe,
            minLines: 4,
            maxLines: 6,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          Text(AppStrings.schedulePosition, style: _labelStyle),
          TextFormField(
            controller: _position,
            keyboardType: const TextInputType.numberWithOptions(),
          ),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleHours, style: _labelStyle),
          TextFormField(controller: _schedule),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleGithub, style: _labelStyle),
          TextFormField(controller: _github),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleInstagram, style: _labelStyle),
          TextFormField(controller: _instagram),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleFacebook, style: _labelStyle),
          TextFormField(controller: _facebook),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleLinkedIn, style: _labelStyle),
          TextFormField(controller: _linkedin),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleTwitter, style: _labelStyle),
          TextFormField(controller: _twitter),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleBlog, style: _labelStyle),
          TextFormField(controller: _blog),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _save,
              child: const Text(AppStrings.eventSaveChanges),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final String? newImagePath;
  final String existingPhotoUrl;
  const _PhotoPreview({
    required this.newImagePath,
    required this.existingPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (newImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(newImagePath!),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    if (existingPhotoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: existingPhotoUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorWidget: (ctx, url, err) => const SizedBox.shrink(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
