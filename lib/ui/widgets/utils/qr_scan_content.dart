import 'dart:developer';
import 'dart:io';

import 'package:app_events/config/theme/app_styles.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demo Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            var res =
                await Navigator.of(context).push<Barcode?>(MaterialPageRoute(
              builder: (context) => const QRScanContent(),
            ));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: AppStyles.colorBaseBlue,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(20),
                  duration: const Duration(seconds: 3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  content: Row(
                    children: [
                      Image.asset(
                        'assets/img/fire-ped.png',
                        width: 45,
                        height: 45,
                      ),
                      Text(res?.code ?? ""),
                    ],
                  )));
            }
          },
          child: const Text('qrView'),
        ),
      ),
    );
  }
}

class QRScanContent extends StatefulWidget {
  final String msg;
  const QRScanContent(
      {super.key, this.msg = " Escanea el código QR de tu manilla"});

  @override
  State<StatefulWidget> createState() => _QRScanContentState();
}

class _QRScanContentState extends State<QRScanContent> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

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
                  _buildQrView(context),
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
                                  await controller?.toggleFlash();
                                  setState(() {});
                                },
                                icon: FutureBuilder(
                                  future: controller?.getFlashStatus(),
                                  builder: (context, snapshot) {
                                    // Text('Flash: ${snapshot.data}');
                                    return Icon(
                                      ((snapshot.data ?? false))
                                          ? Icons.flash_on_rounded
                                          : Icons.flash_off_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    );
                                  },
                                )),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            child: IconButton(
                                onPressed: () async {
                                  await controller?.flipCamera();
                                  setState(() {});
                                },
                                icon: FutureBuilder(
                                  future: controller?.getCameraInfo(),
                                  builder: (context, snapshot) {
                                    if (snapshot.data != null) {
                                      // return Text(
                                      //     'Camera facing ${describeEnum(snapshot.data!)}');
                                      return const Icon(
                                        Icons.flip_camera_android_outlined,
                                        color: Colors.white,
                                        size: 32,
                                      );
                                    } else {
                                      return const Text('loading');
                                    }
                                  },
                                )),
                          )
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
              )),
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
                        "assets/img/fire-ped.png",
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
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      controller.dispose();
      if (!mounted) return;
      Navigator.pop(context, scanData);
      // setState(() {
      //   result = scanData;
      // });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
