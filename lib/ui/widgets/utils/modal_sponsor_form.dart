import 'dart:io';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';



class AddSponsorForm extends StatefulWidget {
  const AddSponsorForm({super.key});

  @override
  State<AddSponsorForm> createState() => _AddSponsorFormState();
}

class _AddSponsorFormState extends State<AddSponsorForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newSponsor = Sponsor(
        name: _nameController.text,
        link: _linkController.text,
        photoUrl: _logoUrlController.text,
      );

      try {
        final otherProvider =
            Provider.of<OtherProvider>(context, listen: false);
        await otherProvider.addSponsor(newSponsor);
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding sponsor: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la empresa'),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                return null;
              },
            ),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(labelText: 'Enlace web'),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                if (!Uri.tryParse(value!)!.isAbsolute ?? true) {
                  return 'URL inválida';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _logoUrlController,
              decoration: const InputDecoration(labelText: 'URL del logo'),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                if (!Uri.tryParse(value!)!.isAbsolute ?? true) {
                  return 'URL inválida';
                }
                return null;
              },
            ),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Guardar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}