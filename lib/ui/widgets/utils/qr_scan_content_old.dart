import 'dart:io';

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanContent extends StatefulWidget {
  final String msg;
  const QRScanContent({super.key, this.msg = AppStrings.scanMessageCredential});

  @override
  State<StatefulWidget> createState() => _QRScanContentState();
}

class _QRScanContentState extends State<QRScanContent> {
  late MobileScannerController controller;

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    // controller = MobileScannerController(torchEnabled: true, invertImage: true);
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.stop();
    }
    controller.start();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {});
    }
  }

  // Widget _barcodePreview(Barcode? value) {
  //   if (value == null) {
  //     return const Text(
  //       'Scan a QR!',
  //       overflow: TextOverflow.fade,
  //       style: TextStyle(color: Colors.white),
  //     );
  //   }

  //   return Text(
  //     value.displayValue ?? 'No display value.',
  //     overflow: TextOverflow.fade,
  //     style: const TextStyle(color: Colors.white),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                _buildQrView(context, controller),
                // Align(
                //   alignment: Alignment.bottomCenter,
                //   child: Container(
                //     alignment: Alignment.bottomCenter,
                //     height: 100,
                //     color: const Color.fromRGBO(0, 0, 0, 0.4),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //       children: [
                //         Expanded(
                //           child: Center(child: _barcodePreview(_barcode)),
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.all(8),
                          child: IconButton(
                            color: Colors.red,
                            onPressed: () async {
                              await controller.toggleTorch();
                              setState(() {});
                            },
                            icon: ValueListenableBuilder(
                              valueListenable: controller,
                              builder: (context, snapshot, child) {
                                return Icon(
                                  snapshot.torchState == TorchState.on
                                      ? Icons.flash_on_rounded
                                      : Icons.flash_off_rounded,
                                  color: Colors.white,
                                  size: 32,
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          child: IconButton(
                            onPressed: () async {
                              await controller.switchCamera();
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.flip_camera_android_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                            // icon: FutureBuilder(
                            //   future: controller.switchCamera(),
                            //   builder: (context, snapshot) {
                            //     if (snapshot.data != null) {
                            //       // return Text(
                            //       //     'Camera facing ${describeEnum(snapshot.data!)}');
                            //       return const Icon(
                            //         Icons.flip_camera_android_outlined,
                            //         color: Colors.white,
                            //         size: 32,
                            //       );
                            //     } else {
                            //       return const Text('loading');
                            //     }
                            //   },
                            // ),
                          ),
                        ),
                      ],
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   children: <Widget>[
                    //     Container(
                    //       margin: const EdgeInsets.all(8),
                    //       child: ElevatedButton(
                    //         onPressed: () async {
                    //           await controller?.pauseCamera();
                    //         },
                    //         child: const Text('pause',
                    //             style: TextStyle(fontSize: 20)),
                    //       ),
                    //     ),
                    //     Container(
                    //       margin: const EdgeInsets.all(8),
                    //       child: ElevatedButton(
                    //         onPressed: () async {
                    //           await controller?.resumeCamera();
                    //         },
                    //         child: const Text('resume',
                    //             style: TextStyle(fontSize: 20)),
                    //       ),
                    //     )
                    //   ],
                    // ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // if (result != null)
                  //   Text(
                  //       'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  // else
                  //   const Text('Scan a code'),
                  Row(
                    children: [
                      Image.asset(
                        AppAssetsPath.firePedIcon,
                        height: 80,
                        width: MediaQuery.of(context).size.width * 0.2,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            widget.msg,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrView(
    BuildContext context,
    MobileScannerController? controller,
  ) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    // var scanArea =
    //     (MediaQuery.of(context).size.width < 400 ||
    //         MediaQuery.of(context).size.height < 400)
    //     ? 250.0
    //     : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return MobileScanner(controller: controller, onDetect: _handleBarcode);
    // return QRView(
    //   key: qrKey,
    //   onQRViewCreated: _onQRViewCreated,
    //   overlay: QrScannerOverlayShape(
    //     borderColor: Colors.red,
    //     borderRadius: 10,
    //     borderLength: 30,
    //     borderWidth: 10,
    //     cutOutSize: scanArea,
    //   ),
    //   onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    // );
  }

  // void _onQRViewCreated(QRViewController controller) {
  //   setState(() {
  //     this.controller = controller;
  //   });
  //   controller.scannedDataStream.listen((scanData) {
  //     controller.dispose();
  //     if (!mounted) return;
  //     Navigator.pop(context, scanData);
  //     // setState(() {
  //     //   result = scanData;
  //     // });
  //   });
  // }

  // void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
  //   log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
  //   if (!p) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text('no Permission')));
  //   }
  // }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
