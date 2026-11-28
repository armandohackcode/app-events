import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:app_events/config/theme/app_assets_path.dart';
import 'package:app_events/config/theme/app_strings.dart';
import 'package:app_events/config/theme/app_styles.dart';
import 'package:app_events/ui/widgets/shared/chunky_button.dart';
import 'package:app_events/ui/widgets/shared/hard_shadow_box.dart';
import 'package:app_events/ui/widgets/shared/tilted_tag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Signature for checking current camera permission status.
typedef CameraPermissionCheck = Future<PermissionStatus> Function();

/// Signature for requesting camera permission from the operating system.
typedef CameraPermissionRequest = Future<PermissionStatus> Function();

/// Signature for opening the OS app settings page.
typedef OpenAppSettingsCallback = Future<bool> Function();

/// Full-screen QR scanner styled with pop-brutalist camera controls and footer.
class QRScanContent extends StatefulWidget {
  final String msg;
  final CameraPermissionCheck? checkCameraPermission;
  final CameraPermissionRequest? requestCameraPermission;
  final OpenAppSettingsCallback? openSettings;

  const QRScanContent({
    super.key,
    this.msg = AppStrings.scanMessageCredential,
    this.checkCameraPermission,
    this.requestCameraPermission,
    this.openSettings,
  });

  @override
  State<StatefulWidget> createState() => _QRScanContentState();
}

class _QRScanContentState extends State<QRScanContent>
    with WidgetsBindingObserver {
  Barcode? result;
  QRViewController? controller;
  StreamSubscription<Barcode>? _subscription;
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;
  bool _isPermanentlyDenied = false;
  bool _cleanedUp = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final hasCustomHandlers =
        widget.checkCameraPermission != null ||
        widget.requestCameraPermission != null;
    final supportsRuntimePermission =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!hasCustomHandlers && !supportsRuntimePermission) {
      _hasPermission = true;
      _isCheckingPermission = false;
    } else {
      unawaited(_ensureCameraPermission());
    }
  }

  Future<PermissionStatus> _safeCheckPermission() async {
    try {
      final checker = widget.checkCameraPermission;
      if (checker != null) return await checker();
      return await Permission.camera.status;
    } on MissingPluginException {
      return PermissionStatus.granted;
    } catch (e) {
      log('Error checking camera permission: $e');
      return PermissionStatus.granted;
    }
  }

  Future<PermissionStatus> _safeRequestPermission() async {
    try {
      final requester = widget.requestCameraPermission;
      if (requester != null) return await requester();
      return await Permission.camera.request();
    } on MissingPluginException {
      return PermissionStatus.granted;
    } catch (e) {
      log('Error requesting camera permission: $e');
      return PermissionStatus.granted;
    }
  }

  Future<void> _ensureCameraPermission() async {
    if (mounted && !_isCheckingPermission) {
      setState(() => _isCheckingPermission = true);
    }
    var status = await _safeCheckPermission();
    if (!status.isGranted && !status.isLimited && !status.isPermanentlyDenied) {
      status = await _safeRequestPermission();
    }
    if (!mounted) return;
    setState(() {
      _hasPermission = status.isGranted || status.isLimited;
      _isPermanentlyDenied = status.isPermanentlyDenied;
      _isCheckingPermission = false;
    });
  }

  Future<void> _recheckPermissionOnResume() async {
    final status = await _safeCheckPermission();
    if (!mounted) return;
    if (status.isGranted || status.isLimited) {
      setState(() {
        _hasPermission = true;
        _isPermanentlyDenied = false;
        _isCheckingPermission = false;
      });
    } else if (status.isPermanentlyDenied != _isPermanentlyDenied) {
      setState(() => _isPermanentlyDenied = status.isPermanentlyDenied);
    }
  }

  Future<void> _handleOpenSettings() async {
    try {
      final opener = widget.openSettings;
      if (opener != null) {
        await opener();
      } else {
        await openAppSettings();
      }
    } on MissingPluginException {
      // Ignore in headless test environments without platform plugin handlers.
    } catch (e) {
      log('Error opening app settings: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_hasPermission) {
      unawaited(_recheckPermissionOnResume());
      return;
    }
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
                  if (_hasPermission)
                    _buildQrView(context)
                  else
                    _buildPermissionPlaceholder(context),
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
                          if (_hasPermission) ...[
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

  Widget _buildPermissionPlaceholder(BuildContext context) {
    if (_isCheckingPermission) {
      return const Center(
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: 48,
          color: AppStyles.colorBaseYellow,
        ),
      );
    }
    return SafeArea(
      bottom: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: HardShadowBox(
              color: AppStyles.cardColor,
              radius: 18,
              shadowOffset: 4,
              borderWidth: 2.5,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off_rounded,
                    size: 42,
                    color: AppStyles.fontColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    AppStrings.scanCameraPermissionDenied,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppStyles.fontColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.scanCameraPermissionBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppStyles.fontSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ChunkyButton(
                    label: _isPermanentlyDenied
                        ? AppStrings.scanOpenSettings
                        : AppStrings.spinRetryAction,
                    color: AppStyles.colorBaseYellow,
                    expand: true,
                    onPressed: _isPermanentlyDenied
                        ? _handleOpenSettings
                        : _ensureCameraPermission,
                  ),
                ],
              ),
            ),
          ),
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
        if (mounted) {
          Navigator.of(this.context).pop();
        }
      });
    }
  }

  Future<void> _cleanupCamera() async {
    if (_cleanedUp) return;
    _cleanedUp = true;
    final currentController = controller;
    controller = null;
    try {
      await _subscription?.cancel();
      _subscription = null;
      await currentController?.pauseCamera();
      // ignore: deprecated_member_use
      currentController?.dispose();
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
