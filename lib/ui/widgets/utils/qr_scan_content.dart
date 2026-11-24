import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Full-screen QR scanner styled with pop-brutalist camera controls and footer.
class QRScanContent extends StatefulWidget {
  final String msg;

  const QRScanContent({super.key, this.msg = AppStrings.scanMessageCredential});

  @override
  State<StatefulWidget> createState() => _QRScanContentState();
}

class _QRScanContentState extends State<QRScanContent>
    with WidgetsBindingObserver {
  Barcode? result;
  QRViewController? controller;
  StreamSubscription<Barcode>? _subscription;
  bool _isProcessing = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (controller == null) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        controller?.pauseCamera();
        break;
      case AppLifecycleState.resumed:
        if (!_isProcessing) {
          controller?.resumeCamera();
        }
        break;
      default:
        break;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _cleanupCamera();
        }
      },
      child: Scaffold(
        backgroundColor: AppStyles.borderColor,
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _buildQrView(context),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _ScannerControlButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: AppStrings.scanBackTooltip,
                            color: AppStyles.cardColor,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          FutureBuilder<bool?>(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              final flashOn = snapshot.data ?? false;
                              return _ScannerControlButton(
                                icon: flashOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                tooltip: AppStrings.scanToggleFlashTooltip,
                                color: flashOn
                                    ? AppStyles.colorBaseYellow
                                    : AppStyles.cardColor,
                                onPressed: () async {
                                  await controller?.toggleFlash();
                                  if (mounted) setState(() {});
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _ScannerControlButton(
                            icon: Icons.flip_camera_android_rounded,
                            tooltip: AppStrings.scanFlipCameraTooltip,
                            color: AppStyles.cardColor,
                            onPressed: () async {
                              await controller?.flipCamera();
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppStyles.homeBackgroundColor,
                border: Border(
                  top: BorderSide(color: AppStyles.borderColor, width: 2.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: HardShadowBox(
                    color: AppStyles.cardColor,
                    radius: 18,
                    shadowOffset: 3,
                    borderWidth: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppStyles.activitiesRankingTagColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppStyles.borderColor,
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            AppAssetsPath.firePedIcon,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const TiltedTag(
                                text: AppStrings.scanTitle,
                                color: AppStyles.colorBaseYellow,
                                angleDegrees: -1,
                                compact: true,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.msg,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppStyles.fontColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scanArea = (size.width < 400 || size.height < 400) ? 240.0 : 280.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: AppStyles.colorBaseYellow,
        borderRadius: 16,
        borderLength: 32,
        borderWidth: 8,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    _subscription = controller.scannedDataStream.listen((scanData) {
      if (!mounted || _isProcessing) return;

      _isProcessing = true;
      controller.pauseCamera();
      Navigator.pop(context, scanData);
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.scanCameraPermissionDenied),
          duration: Duration(seconds: 3),
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  Future<void> _cleanupCamera() async {
    try {
      await _subscription?.cancel();
      await controller?.pauseCamera();
      // ignore: deprecated_member_use
      controller?.dispose();
    } catch (e) {
      log('Error cleaning up camera: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupCamera();
    super.dispose();
  }
}

class _ScannerControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ScannerControlButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: HardShadowBox(
        color: color,
        radius: 14,
        shadowOffset: 3,
        borderWidth: 2,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, size: 22, color: AppStyles.fontColor),
            ),
          ),
        ),
      ),
    );
  }
}
