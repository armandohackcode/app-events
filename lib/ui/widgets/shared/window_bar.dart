import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Header strip of a retro window: the three window controls, a centered
/// [title] and an optional [trailing] widget, with a line underneath.
class WindowBar extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const WindowBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppStyles.windowChromeColor,
        border: Border(
          bottom: BorderSide(color: AppStyles.borderColor, width: 2),
        ),
      ),
      child: Row(
        children: [
          const _WindowControl(color: AppStyles.colorBaseRed),
          const SizedBox(width: 6),
          const _WindowControl(color: AppStyles.colorBaseYellow),
          const SizedBox(width: 6),
          const _WindowControl(color: AppStyles.colorBaseGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppStyles.monospaceFontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _WindowControl extends StatelessWidget {
  final Color color;
  const _WindowControl({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: AppStyles.borderColor, width: 1.5),
      ),
    );
  }
}
