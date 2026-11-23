import 'dart:math' as math;

import 'package:app_events/config/theme/app_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Computes up to 2 uppercase initials from [name], falling back to `'G'`.
String computeNameInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'G';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, math.min(2, word.length)).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

/// Circular avatar showing [photoUrl] with a crisp border and initials or asset fallback.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double borderWidth;
  final double? fontSize;
  final String? fallbackAsset;

  const InitialsAvatar({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.backgroundColor,
    this.foregroundColor = AppStyles.onAccentColor,
    this.size = 48,
    this.borderWidth = 2,
    this.fontSize,
    this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = photoUrl.trim();
    final innerSize = math.max(0.0, size - borderWidth * 2);
    final resolvedFontSize = fontSize ?? size * 0.34;

    Widget fallback = Center(
      child: fallbackAsset != null
          ? Padding(
              padding: EdgeInsets.all(size * 0.12),
              child: Image.asset(fallbackAsset!, fit: BoxFit.contain),
            )
          : Text(
              computeNameInitials(name),
              style: TextStyle(
                fontSize: resolvedFontSize,
                fontWeight: FontWeight.w900,
                color: foregroundColor,
                height: 1,
              ),
            ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppStyles.borderColor, width: borderWidth),
      ),
      child: ClipOval(
        child: SizedBox(
          width: innerSize,
          height: innerSize,
          child: trimmedUrl.isEmpty
              ? fallback
              : CachedNetworkImage(
                  imageUrl: trimmedUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
