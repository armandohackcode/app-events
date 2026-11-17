import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// One destination of the [FloatingNavBar].
class FloatingNavItem {
  final String icon;
  final String label;

  const FloatingNavItem({required this.icon, required this.label});
}

/// Bottom navigation drawn as a floating rounded bar with a hard shadow. The
/// selected item shows a blue underline and the others are dimmed.
class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            color: AppStyles.homeBackgroundColor,
            border: Border.all(color: AppStyles.borderColor, width: 2.5),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: AppStyles.borderColor, offset: Offset(4, 4)),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: selected ? 1 : 0.45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                item.icon,
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  AppStyles.fontColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: AppStyles.fontColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 26,
                height: 3,
                decoration: BoxDecoration(
                  color: selected
                      ? AppStyles.colorBaseBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
