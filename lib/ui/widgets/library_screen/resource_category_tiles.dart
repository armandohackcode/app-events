import 'dart:math' as math;

import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';

/// Technology area used to browse the library. A null [type] means every
/// resource. Label, icon and color come from the shared technology helpers.
class ResourceCategory {
  final String? type;

  /// Tilt of the tile, in degrees.
  final double angle;

  const ResourceCategory({required this.type, required this.angle});

  String get label => type ?? AppStrings.organizersFilterAll;
  IconData get icon =>
      type == null ? Icons.view_headline_rounded : technologyIcon(type!);
  Color get color =>
      type == null ? AppStyles.primaryColor : technologyColor(type!);
}

const List<ResourceCategory> resourceCategories = [
  ResourceCategory(type: null, angle: 0),
  ResourceCategory(type: AppStrings.technologyMobile, angle: -4),
  ResourceCategory(type: AppStrings.technologyAI, angle: 3),
  ResourceCategory(type: AppStrings.technologyCloud, angle: -3),
  ResourceCategory(type: AppStrings.technologyWeb, angle: 4),
  ResourceCategory(type: AppStrings.technologyUIUX, angle: -2),
];

/// Horizontally scrollable row of category tiles. The tile of
/// [selectedType] is highlighted; null selects "all".
class ResourceCategoryTiles extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onSelected;

  const ResourceCategoryTiles({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  AppStrings.resourceLibraryExplore,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppStyles.fontColor,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                AppStrings.resourceLibrarySwipeHint,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppStyles.fontSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
          child: Row(
            children: [
              for (var i = 0; i < resourceCategories.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                _CategoryTile(
                  category: resourceCategories[i],
                  selected: resourceCategories[i].type == selectedType,
                  onTap: () => onSelected(resourceCategories[i].type),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ResourceCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  static const double _size = 66;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 78,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: const Duration(milliseconds: 200),
                child: Transform.rotate(
                  angle: category.angle * math.pi / 180,
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          category.color,
                          AppStyles.darken(category.color),
                        ],
                      ),
                      border: Border.all(
                        color: AppStyles.borderColor,
                        width: 2.5,
                      ),
                      boxShadow: [
                        if (selected)
                          const BoxShadow(
                            color: AppStyles.colorBaseYellow,
                            spreadRadius: 3,
                          ),
                        const BoxShadow(
                          color: AppStyles.borderColor,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      category.icon,
                      size: 28,
                      color: AppStyles.onAccentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppStyles.fontColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
