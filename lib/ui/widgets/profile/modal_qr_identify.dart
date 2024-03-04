import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ModalQrIdentify extends StatelessWidget {
  final String identify;
  const ModalQrIdentify({super.key, required this.identify});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppStyles.backgroundColor,
      children: [
        // const SizedBox(height: 15),
        Image.asset("assets/img/title-devfest.png"),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.all(15),
          alignment: Alignment.bottomCenter,
          decoration: const BoxDecoration(color: AppStyles.fontColor),
          child: SizedBox(
            width: 260,
            height: 260,
            child: QrImageView(
              // foregroundColor: AppStyles.backgroundColor,
              data: identify, size: 250,
              // You can include embeddedImageStyle Property if you
              //wanna embed an image from your Asset folder
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(
                  100,
                  100,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
