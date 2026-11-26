import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cancelText;
  final String acceptText;
  final Color? acceptColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.subtitle,
    this.cancelText = AppStrings.commonWordCancel,
    this.acceptText = AppStrings.commonWordAccept,
    this.acceptColor,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    String cancelText = AppStrings.commonWordCancel,
    String acceptText = AppStrings.commonWordAccept,
    Color? acceptColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        subtitle: subtitle,
        cancelText: cancelText,
        acceptText: acceptText,
        acceptColor: acceptColor,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: AppStyles.fontColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: acceptColor != null
                        ? ElevatedButton.styleFrom(
                            backgroundColor: acceptColor,
                            foregroundColor: AppStyles.onAccentColor,
                          )
                        : null,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(acceptText),
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
