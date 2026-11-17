import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Round, glossy button that shows a single-color [glyph] over a brand
/// [color]. With [hardShadow] it also casts the app's offset shadow.
class SocialCircleButton extends StatelessWidget {
  final Color color;
  final String glyph;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double glyphSize;
  final double borderWidth;
  final bool hardShadow;

  const SocialCircleButton({
    super.key,
    required this.color,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
    this.size = 42,
    this.glyphSize = 20,
    this.borderWidth = 2,
    this.hardShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final glossWidth = size * 0.38;
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: hardShadow
              ? const [
                  BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
                ]
              : null,
        ),
        child: Material(
          color: color,
          shape: CircleBorder(
            side: BorderSide(color: AppStyles.borderColor, width: borderWidth),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: size * 0.1,
                    left: size * 0.21,
                    child: _Gloss(width: glossWidth),
                  ),
                  SvgPicture.asset(
                    glyph,
                    width: glyphSize,
                    height: glyphSize,
                    colorFilter: const ColorFilter.mode(
                      AppStyles.onAccentColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small tilted highlight that gives the round buttons their glossy look.
class _Gloss extends StatelessWidget {
  final double width;
  const _Gloss({required this.width});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -24 * math.pi / 180,
      child: ClipOval(
        child: SizedBox(
          width: width,
          height: width / 2,
          child: ColoredBox(
            color: AppStyles.onAccentColor.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
