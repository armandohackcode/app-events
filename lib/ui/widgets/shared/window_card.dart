import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Card framed as a retro window: a header strip with window controls, a
/// centered [title] and an optional [trailing] text, over a hard drop shadow.
class WindowCard extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WindowCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  static const double _radius = 20;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        border: Border.all(color: AppStyles.borderColor, width: _borderWidth),
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(color: AppStyles.borderColor, offset: Offset(4, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius - _borderWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: title, trailing: trailing),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? trailing;
  const _Header({required this.title, this.trailing});

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
          const _WindowControl(color: AppStyles.windowCloseColor),
          const SizedBox(width: 6),
          const _WindowControl(color: AppStyles.windowMinimizeColor),
          const SizedBox(width: 6),
          const _WindowControl(color: AppStyles.windowMaximizeColor),
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
          if (trailing != null)
            Text(
              trailing!,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppStyles.fontSecondaryColor,
              ),
            ),
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
