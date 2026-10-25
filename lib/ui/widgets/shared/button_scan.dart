import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/providers/user_provider.dart';
import 'package:app_events/ui/widgets/utils/qr_scan_content.dart';
import 'package:app_events/ui/widgets/utils/utils_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Opens the QR scanner and adds the scanned attendee as a friend.
class ButtonScan extends StatelessWidget {
  const ButtonScan({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppStyles.colorBaseBlue,
      child: const Icon(Icons.qr_code_scanner, size: 32),
      onPressed: () async {
        final dataCenter = Provider.of<UserProvider>(context, listen: false);
        var res = await Navigator.of(context).push<Barcode?>(
          MaterialPageRoute(
            builder: (context) =>
                const QRScanContent(msg: AppStrings.scanMessage),
          ),
        );
        if (res != null) {
          var info = await dataCenter.addNewFriend(res.code!);
          if (info != null && context.mounted) {
            customSnackbar(context, AppStrings.scanMessageAddedFriend);
          } else {
            if (context.mounted) {
              customSnackbar(
                context,
                AppStrings.scanMessageInvalidQR,
                color: AppStyles.colorBaseRed,
              );
            }
          }
        }
      },
    );
  }
}
