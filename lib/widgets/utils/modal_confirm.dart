import 'package:app_events/constants.dart';
import 'package:flutter/material.dart';

class ModalConfirm extends StatelessWidget {
  final String text;
  const ModalConfirm({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(15),
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: 15,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("NO")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.colorBaseRed),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("SI")),
          ],
        )
      ],
    );
  }
}
