import 'package:app_events/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ModalQrIdentify extends StatelessWidget {
  final String identify;
  const ModalQrIdentify({super.key, required this.identify});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: AppStyles.fontColor,
      children: [
        const SizedBox(height: 15),
        SvgPicture.asset("assets/img/io-logo-white.svg"),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.all(15),
          alignment: Alignment.bottomCenter,
          decoration: const BoxDecoration(color: AppStyles.backgroundColor),
          child: SizedBox(
            width: 250,
            height: 250,
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
