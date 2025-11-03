import 'package:app_events/domain/models/sponsor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_events/ui/providers/other_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/config/theme/app_strings.dart';

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
        photoUrl: '',
      );

      try {
        final otherProvider = context.read<OtherProvider>();
        await otherProvider.addSponsor(newSponsor, _sponsorImagePath);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.sponsorSuccessMessage)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppStrings.sponsorErrorMessage} : ${e.toString()}',
              ),
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
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom + 20.0
        : mediaQuery.padding.bottom + 20.0;

    return Container(
      decoration: BoxDecoration(
        color: AppStyles.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        bottom: bottomPadding,
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                // ...
                children: [
                  Text(
                    AppStrings.sponsorModalTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.sponsorsNameLabel,
                    ),
                    validator: (value) => (value?.isEmpty ?? true)
                        ? AppStrings.profileAboutMeValidate
                        : null,
                  ),
                  SizedBox(height: 15),

                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: AppStrings.sponsorsLinkLabel,
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return AppStrings.profileAboutMeValidate;
                      if (!(Uri.tryParse(value!)?.isAbsolute ?? false)) {
                        return AppStrings.urlNotValidMessage;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  ElevatedButton.icon(
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
                      _sponsorImagePath != null
                          ? AppStrings.sponsorsChangeImageLabel
                          : AppStrings.sponsorsAddImageLabel,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(AppStrings.commonWordCancel),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.colorBaseBlue,
                          foregroundColor: AppStyles.fontColor,
                        ),
                        icon: const Icon(Icons.save),
                        label: Text(AppStrings.commonWordSave),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSaving)
            Positioned.fill(
              child: Container(
                color: AppStyles.backgroundColor.withOpacity(0.8),
                child: Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      color: AppStyles.colorBaseRed,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
