import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Search box of the library: a rounded card with a hard shadow. It only
/// reports what the user does; the search itself is done by the caller.
class LibrarySearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const LibrarySearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        border: Border.all(color: AppStyles.borderColor, width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: onSubmitted,
              style: const TextStyle(fontSize: 15, color: AppStyles.fontColor),
              decoration: const InputDecoration(
                hintText: AppStrings.resourceLibrarySearchHint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const Icon(
                    Icons.search_rounded,
                    size: 24,
                    color: AppStyles.fontColor,
                  )
                : IconButton(
                    onPressed: onClear,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.clear, color: AppStyles.fontColor),
                  ),
          ),
        ],
      ),
    );
  }
}
