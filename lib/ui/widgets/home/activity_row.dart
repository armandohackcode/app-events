import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

/// Full-width row that opens a section of the app: a tinted icon box, a title
/// with a subtitle and a chevron.
class ActivityRow extends StatelessWidget {
  final Widget icon;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const ActivityRow({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  static const double _radius = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: const [
          BoxShadow(color: AppStyles.borderColor, offset: Offset(3, 3)),
        ],
      ),
      child: Material(
        color: AppStyles.cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppStyles.borderColor, width: 2),
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(width: 28, height: 28, child: icon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppStyles.fontColor,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppStyles.fontSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppStyles.fontSecondaryColor,
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
