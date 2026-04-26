import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final _dateFmtEdit = DateFormat('dd/MM/yyyy', 'es');

class EditEvent extends StatefulWidget {
  final Event event;
  const EditEvent({super.key, required this.event});

  @override
  State<EditEvent> createState() => _EditEventState();
}

class _EditEventState extends State<EditEvent> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _locationUrl;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _newImagePath;
  bool _loading = false;

  final _textStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.event.title);
    _description = TextEditingController(text: widget.event.description);
    _locationUrl = TextEditingController(text: widget.event.locationUrl);
    _startDate = widget.event.startDate;
    _endDate = widget.event.endDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _locationUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(data: ThemeData.light(), child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _newImagePath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.eventEdit)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          Text(AppStrings.scheduleTitle, style: _textStyle),
          TextFormField(controller: _title),
          const SizedBox(height: 10),
          Text(AppStrings.scheduleDescription, style: _textStyle),
          TextFormField(
            controller: _description,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          Text(AppStrings.eventStartDate, style: _textStyle),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _dateFmtEdit.format(_startDate),
              style: const TextStyle(color: AppStyles.fontColor),
            ),
            trailing: const Icon(Icons.calendar_today,
                color: AppStyles.fontSecondaryColor),
            onTap: () => _pickDate(context, true),
          ),
          Text(AppStrings.eventEndDate, style: _textStyle),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _dateFmtEdit.format(_endDate),
              style: const TextStyle(color: AppStyles.fontColor),
            ),
            trailing: const Icon(Icons.calendar_today,
                color: AppStyles.fontSecondaryColor),
            onTap: () => _pickDate(context, false),
          ),
          const SizedBox(height: 10),
          Text(AppStrings.eventLocationUrl, style: _textStyle),
          TextFormField(
            controller: _locationUrl,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          Text(AppStrings.eventImageUrl, style: _textStyle),
          const SizedBox(height: 8),
          _ImagePreview(
            newImagePath: _newImagePath,
            existingImageUrl: widget.event.imageUrl,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: Icon(
              _newImagePath == null ? Icons.add_photo_alternate : Icons.edit,
              size: 18,
            ),
            label: Text(
              _newImagePath == null
                  ? AppStrings.eventSelectImage
                  : AppStrings.eventChangeImage,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppStyles.colorBaseBlue,
              side: const BorderSide(color: AppStyles.colorBaseBlue),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _pickImage,
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: () async {
                if (_title.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(AppStrings.eventValidationRequired)),
                  );
                  return;
                }
                setState(() => _loading = true);
                final updated = widget.event.copyWith(
                  title: _title.text.trim(),
                  description: _description.text.trim(),
                  startDate: _startDate,
                  endDate: _endDate,
                  locationUrl: _locationUrl.text.trim(),
                );
                await eventProvider.updateEvent(
                  updated,
                  imagePath: _newImagePath,
                );
                setState(() => _loading = false);
                if (context.mounted) {
                  customSnackbar(context, AppStrings.eventUpdatedSuccess);
                  Navigator.of(context).pop();
                }
              },
              child: const Text(AppStrings.eventSaveChanges),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String? newImagePath;
  final String existingImageUrl;

  const _ImagePreview({
    required this.newImagePath,
    required this.existingImageUrl,
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
    if (existingImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: existingImageUrl,
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
