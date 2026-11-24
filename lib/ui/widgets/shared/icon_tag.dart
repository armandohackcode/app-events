import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';

/// Small pill with an icon and a short text, used for the technology and the
/// type of an activity.
class IconTag extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final Color foregroundColor;

  const IconTag({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.foregroundColor = AppStyles.fontColor,
  });

  @override
  Widget build(BuildContext context) {
    return HardShadowBox(
      color: color,
      radius: 999,
      shadowOffset: 2,
      borderWidth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
