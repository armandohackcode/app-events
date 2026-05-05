import 'dart:io';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/speed_run_challenge.dart';
import 'package:app_events/ui/providers/speed_run_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddChallengeScreen extends StatefulWidget {
  const AddChallengeScreen({super.key});

  @override
  State<AddChallengeScreen> createState() => _AddChallengeScreenState();
}

class _AddChallengeScreenState extends State<AddChallengeScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _position = TextEditingController();
  ChallengeState _state = ChallengeState.active;
  String? _imagePath;
  bool _loading = false;

  final _labelStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SpeedRunProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.speedRunAddChallenge)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Text(AppStrings.scheduleTitle, style: _labelStyle),
          TextFormField(controller: _title),
          const SizedBox(height: 10),
          Text(AppStrings.speedRunChallengeContent, style: _labelStyle),
          TextFormField(
            controller: _content,
            minLines: 5,
            maxLines: null,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          Text(AppStrings.speedRunChallengePosition, style: _labelStyle),
          TextFormField(
            controller: _position,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          Text(AppStrings.speedRunChallengeState, style: _labelStyle),
          const SizedBox(height: 6),
          DropdownButtonFormField<ChallengeState>(
            initialValue: _state,
            items: [
              DropdownMenuItem(
                value: ChallengeState.active,
                child: Text(AppStrings.speedRunChallengeActive),
              ),
              DropdownMenuItem(
                value: ChallengeState.inactive,
                child: Text(AppStrings.speedRunChallengeInactive),
              ),
            ],
            onChanged: (v) => setState(() => _state = v!),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.eventImageUrl, style: _labelStyle),
          const SizedBox(height: 8),
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_imagePath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            icon: Icon(
              _imagePath == null ? Icons.add_photo_alternate : Icons.edit,
              size: 18,
            ),
            label: Text(
              _imagePath == null
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
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: () async {
                if (_title.text.isEmpty || _content.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.speedRunAddValidation),
                    ),
                  );
                  return;
                }
                setState(() => _loading = true);
                final challenge = SpeedRunChallenge(
                  id: '',
                  title: _title.text,
                  challenge: _content.text,
                  imageUrl: '',
                  state: _state,
                  position: int.tryParse(_position.text) ?? 0,
                );
                await provider.addChallenge(challenge, imagePath: _imagePath);
                setState(() => _loading = false);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text(AppStrings.commonWordSave),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
