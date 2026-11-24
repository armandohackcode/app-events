import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Card of a library resource: a preview image with the technology tag, the
/// title, a short description and the site the link opens.
///
/// While there is no [image] the preview shows a gradient in the color of the
/// technology.
class ResourceCard extends StatelessWidget {
  final String title;
  final String link;
  final String type;
  final String? description;
  final ImageProvider? image;
  final VoidCallback onTap;

  const ResourceCard({
    super.key,
    required this.title,
    required this.link,
    required this.type,
    required this.onTap,
    this.description,
    this.image,
  });

  static const double _radius = 14;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final color = technologyColor(type);
    final summary = description?.trim() ?? '';
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
        child: Material(
          color: AppStyles.cardColor,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Preview(color: color, type: type, image: image),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppStyles.fontColor,
                        ),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppStyles.fontSecondaryColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _siteOf(link),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppStyles.fontFaintColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            AppStrings.resourceLibraryOpen,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppStyles.colorBaseBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.north_east_rounded,
                            size: 12,
                            color: AppStyles.colorBaseBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Host of [link] without the leading "www.", or the link itself when it
  /// cannot be parsed.
  static String _siteOf(String link) {
    final host = Uri.tryParse(link.trim())?.host ?? '';
    if (host.isEmpty) return link;
    return host.startsWith('www.') ? host.substring(4) : host;
  }
}

class _Preview extends StatelessWidget {
  final Color color;
  final String type;
  final ImageProvider? image;

  const _Preview({required this.color, required this.type, this.image});

  static const double _height = 150;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppStyles.borderColor, width: 2),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, AppStyles.darken(color)],
              ),
            ),
          ),
          if (image != null)
            Image(
              image: image!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypeTag(type: type, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTag extends StatelessWidget {
  final String type;
  final Color color;
  const _TypeTag({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppStyles.tagOverlayColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              type.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: AppStyles.onAccentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
