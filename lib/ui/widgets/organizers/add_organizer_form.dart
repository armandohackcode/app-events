import 'dart:io';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/organizer.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddOrganizerForm extends StatefulWidget {
  final List<String> availableTeams;
  final List<String> initialTeams;

  const AddOrganizerForm({
    super.key,
    this.availableTeams = const [
      AppStrings.organizersTeamApp,
      AppStrings.organizersTeamDesign,
      AppStrings.organizersTeamStaging,
      AppStrings.organizersTeamMarketing,
      AppStrings.organizersTeamLogistics,
      AppStrings.organizersTeamAudioVideo,
      AppStrings.organizersTeamSponsors,
      AppStrings.organizersTeamRoadToDevFest,
      AppStrings.organizersTeamWeb,
      AppStrings.organizersTeamAccreditation,
    ],
    this.initialTeams = const [],
  });

  @override
  State<AddOrganizerForm> createState() => _AddOrganizerFormState();
}

class _AddOrganizerFormState extends State<AddOrganizerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _type = organizerValue; // 1: Organizador, 2: Lead
  final ImagePicker _picker = ImagePicker();
  late List<String> _teams;
  String? _organizerImagePath;
  bool isSaving = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _organizerImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _submit() async {
    if (isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => isSaving = true);

    final newOrganizer = Organizer(
      name: _nameController.text.trim(),
      link: "",
      type: _type,
      photoUrl: '',
      team: _teams,
    );

    try {
      final otherProvider = context.read<OtherProvider>();
      await otherProvider.addOrganizer(newOrganizer, _organizerImagePath);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.commonMessageSave)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _teams = List<String>.from(widget.initialTeams);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingTeams = widget.availableTeams
        .where((t) => !_teams.contains(t))
        .toList();
    final hasImage =
        _organizerImagePath != null && _organizerImagePath!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppStyles.fontFaintColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.organizerText,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 8),

            if (hasImage) ...[
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppStyles.fontFaintColor,
                      backgroundImage: FileImage(File(_organizerImagePath!)),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isSaving
                            ? null
                            : () => setState(() => _organizerImagePath = null),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppStyles.colorBaseRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppStyles.onAccentColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            Center(
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.colorNavbar,
                  foregroundColor: AppStyles.fontColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
                icon: const Icon(Icons.image),
                label: Text(
                  _organizerImagePath != null
                      ? AppStrings.eventSelectImage
                      : AppStrings.eventSelectImage,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nombre
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: AppStrings.profileName,
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.profileNameValidate
                  : null,
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.commonWordType,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 1,
                    label: Text(AppStrings.organizerText),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text(AppStrings.organizersTagLead),
                    icon: Icon(Icons.star_outline),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() => _type = selection.first);
                },
              ),
            ),
            const SizedBox(height: 8),

            // Equipos
            const Text(
              AppStrings.commonWordTeams,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(_teams.length), // reinicia el dropdown al elegir
              initialValue: null,
              hint: const Text(AppStrings.organizerAddTeams),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: remainingTeams
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (t) {
                FocusScope.of(context).unfocus();
                if (t != null) setState(() => _teams.add(t));
              },
            ),
            if (_teams.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _teams
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        onDeleted: () => setState(() => _teams.remove(t)),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Botones
            if (isSaving)
              Center(
                child: SizedBox(
                  width: 35,
                  height: 35,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppStyles.colorBaseRed,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.commonWordCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text(AppStrings.commonWordSave),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
