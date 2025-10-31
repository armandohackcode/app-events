import 'dart:io';
import 'package:app_events/domain/models/sponsor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:image_picker/image_picker.dart';


class AddSponsorForm extends StatefulWidget {
  const AddSponsorForm({super.key});

  @override
  State<AddSponsorForm> createState() => _AddSponsorFormState();
}

class _AddSponsorFormState extends State<AddSponsorForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  String? _sponsorImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _sponsorImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _submit() async {
    if (context.read<OtherProvider>().isLoading) return;

    if (_formKey.currentState!.validate()) {
      final newSponsor = Sponsor(
        name: _nameController.text,
        link: _linkController.text,
        photoUrl: '', // This will be set after uploading the image
      );

      try {
        final otherProvider = context.read<OtherProvider>();
        await otherProvider.addSponsor(newSponsor, _sponsorImagePath);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sponsor agregado exitosamente!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al agregar sponsor: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherProvider = context.watch<OtherProvider>();
    final bool isSaving = otherProvider.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título con estilo
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  'Registrar Nuevo Sponsor',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la empresa',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Enlace web (URL)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  if (!(Uri.tryParse(value!)?.isAbsolute ?? false)) {
                    return 'URL inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 💡 REEMPLAZO DEL CAMPO URL POR EL SELECTOR DE IMAGEN
              Row(
                children: [
                  // 1. Botón para seleccionar imagen
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Seleccionar Logo'),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 2. Vista previa de la imagen seleccionada (UX)
                  if (_sponsorImagePath != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(
                                File(_sponsorImagePath!),
                              ), // Mostrar imagen local
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(
                            () => _sponsorImagePath = null,
                          ), // Opción para quitar la imagen
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    )
                  else
                    // Placeholder si no hay imagen
                    const Text('No se ha seleccionado logo'),
                ],
              ),
              const SizedBox(height: 25),

              // 💡 MEJORA UX: Botones deshabilitados y con indicador de carga
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : _submit, // Deshabilitar si está guardando
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor, // Usar color primario
                      foregroundColor: Colors.white,
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSaving ? 'Guardando...' : 'Guardar Sponsor'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
