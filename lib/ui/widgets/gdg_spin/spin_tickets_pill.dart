import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Yellow pill showing the user's current ticket balance.
class SpinTicketsPill extends StatelessWidget {
  final int tickets;
  final VoidCallback? onTap;

  const SpinTicketsPill({super.key, required this.tickets, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pill = HardShadowBox(
      color: AppStyles.spinBezelColor,
      radius: 999,
      shadowOffset: 2.5,
      borderWidth: 2,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(AppAssetsPath.spinIconTicket, width: 14, height: 14),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppStrings.spinTicketCount(tickets),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppStyles.fontColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return pill;

    return Semantics(
      button: true,
      label: AppStrings.spinTicketsSemantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(child: pill),
        ),
      ),
    );
  }
}
