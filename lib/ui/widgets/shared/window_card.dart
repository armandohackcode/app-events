import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/window_bar.dart';
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
            WindowBar(
              title: title,
              trailing: trailing == null
                  ? null
                  : Text(
                      trailing!,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppStyles.fontSecondaryColor,
                      ),
                    ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
