import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/card_content.dart';
import 'package:flutter/material.dart';

class ButtonActivity extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String text;
  const ButtonActivity({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CardContent(
      height: 90,
      child: TextButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 185,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
              icon,
            ],
          ),
        ),
      ),
    );
  }
}
