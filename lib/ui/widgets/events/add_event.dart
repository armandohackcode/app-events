import 'dart:io';

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/event.dart';
import 'package:app_events/ui/providers/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddEvent extends StatefulWidget {
  const AddEvent({super.key});

  @override
  State<AddEvent> createState() => _AddEventState();
}

class _AddEventState extends State<AddEvent> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationUrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _imagePath;
  bool _loading = false;

  final _textStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

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
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light(),
        child: child!,
      ),
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
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.eventNew)),
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
              _startDate != null
                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                  : AppStrings.eventSelectDate,
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
              _endDate != null
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : AppStrings.eventSelectDate,
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
                if (_title.text.isEmpty ||
                    _startDate == null ||
                    _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.eventValidationRequired),
                    ),
                  );
                  return;
                }
                setState(() => _loading = true);
                final event = Event(
                  id: '',
                  title: _title.text,
                  description: _description.text,
                  startDate: _startDate!,
                  endDate: _endDate!,
                  locationUrl: _locationUrl.text,
                  imageUrl: '',
                  status: EventStatus.upcoming,
                );
                await eventProvider.addEvent(event, imagePath: _imagePath);
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
