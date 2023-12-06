import 'package:app_events/bloc/data_center.dart';
import 'package:app_events/constants.dart';
import 'package:app_events/models/resource_library.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddResource extends StatefulWidget {
  const AddResource({super.key});

  @override
  State<AddResource> createState() => _AddResourceState();
}

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
          child: SizedBox(
            child: Text(text),
          ),
        ),
      ],
    );
  }

  TextStyle textStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  @override
  Widget build(BuildContext context) {
    final dataCenter = Provider.of<DataCenter>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Añadir Recurso"),
      ),
      body: ListView(padding: const EdgeInsets.all(15), children: [
        const SizedBox(height: 10),
        Text("Area Técnica", style: textStyle),
        DropdownButtonFormField(
            dropdownColor: AppStyles.colorAppbar,
            value: technologyType,
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
        Text("Título o Descripción", style: textStyle),
        TextFormField(
          controller: _title,
        ),
        const SizedBox(height: 10),
        Text("Link del recurso", style: textStyle),
        TextFormField(
          controller: _link,
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
                await dataCenter.addResources(ResourceLibrary(
                    title: _title.text,
                    link: _link.text,
                    type: technologyType ?? ''));
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar"))
      ]),
    );
  }
}
