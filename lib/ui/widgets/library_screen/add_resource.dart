import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/domain/models/resource_library.dart';
import 'package:app_events/ui/providers/resources_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddResource extends StatefulWidget {
  const AddResource({super.key});

  @override
  State<AddResource> createState() => _AddResourceState();
}

// TO DO : refactor this screen to use form key and validators and enum for types
class _AddResourceState extends State<AddResource> {
  final _title = TextEditingController();
  final _link = TextEditingController();

  bool loading = false;
  String? technologyType;

  @override
  void dispose() {
    _title.dispose();
    _link.dispose();
    super.dispose();
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

  TextStyle textStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  @override
  Widget build(BuildContext context) {
    final data = Provider.of<ResourcesProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.resourceLibraryAddResource)),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          const SizedBox(height: 10),
          Text(AppStrings.resourceLibraryTechnicalArea, style: textStyle),
          DropdownButtonFormField(
            dropdownColor: AppStyles.colorAppbar,
            initialValue: technologyType,
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
          Text(AppStrings.resourceLibraryDescription, style: textStyle),
          TextFormField(controller: _title),
          const SizedBox(height: 10),
          Text(AppStrings.resourceLibraryResourceLink, style: textStyle),
          TextFormField(controller: _link),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  loading = true;
                });
                await data.addResources(
                  ResourceLibrary(
                    title: _title.text,
                    link: _link.text,
                    type: technologyType ?? '',
                    keywords: _title.text
                        .split(RegExp(r'\s+'))
                        .toSet()
                        .toList(),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text(AppStrings.commonWordSave),
            ),
        ],
      ),
    );
  }
}
