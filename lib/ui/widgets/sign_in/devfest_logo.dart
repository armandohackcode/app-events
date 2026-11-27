import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:flutter/material.dart';

/// Official DevFest logo artwork scaled responsively to preserve its aspect ratio.
class DevFestLogo extends StatelessWidget {
  static const double _aspectRatio = 515 / 149;
  static const double _maxWidth = 310;

  const DevFestLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Image.asset(
          AppAssetsPath.logoDevFest,
          fit: BoxFit.contain,
          semanticLabel: AppStrings.signInEventName,
        ),
      ),
    );
  }
}
