import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Pop-brutalist action button that opens the QR scanner to add a friend.
class ButtonScan extends StatelessWidget {
  const ButtonScan({super.key});

  Future<void> _openScanner(BuildContext context) async {
    final dataCenter = Provider.of<UserProvider>(context, listen: false);
    final res = await Navigator.of(context).push<Barcode?>(
      MaterialPageRoute(
        builder: (context) => const QRScanContent(msg: AppStrings.scanMessage),
      ),
    );
    final code = res?.code;
    if (res == null || code == null) return;
    final info = await dataCenter.addNewFriend(code);
    if (!context.mounted) return;
    if (info != null) {
      customSnackbar(context, AppStrings.scanMessageAddedFriend);
    } else {
      customSnackbar(
        context,
        AppStrings.scanMessageInvalidQR,
        color: AppStyles.colorBaseRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.scanActionTooltip,
      child: HardShadowBox(
        color: AppStyles.backdropBlueColor,
        radius: 18,
        shadowOffset: 3,
        borderWidth: 2.5,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15.5),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openScanner(context),
            child: const SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 28,
                color: AppStyles.onAccentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
