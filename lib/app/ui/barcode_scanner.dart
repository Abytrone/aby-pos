import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/settings.dart';
import '../services/settings_service.dart';
import '../theme/aby_theme.dart';
import 'l10n.dart';

/// The camera scans on Android phones and tablets (Windows tills use a
/// keyboard-mode scanner), unless this device turned it off.
bool get canScanWithCamera =>
    Platform.isAndroid && Get.isRegistered<SettingsService>() && Get.find<SettingsService>().get(AppSettings.cameraScan);

/// Opens the camera and returns the first barcode or QR code it reads, or
/// null when closed.
Future<String?> scanWithCamera() async => Get.to<String>(() => const _ScannerPage(), fullscreenDialog: true);

/// A "Scan" icon button, only where the camera can scan.
Widget? cameraScanButton(void Function(String code) onCode) {
  if (!canScanWithCamera) return null;
  return Builder(
    builder: (context) => IconButton(
      tooltip: context.l10n.scanWithCamera,
      icon: const Icon(Icons.photo_camera_outlined),
      onPressed: () async {
        final code = await scanWithCamera();
        if (code != null && code.trim().isNotEmpty) onCode(code.trim());
      },
    ),
  );
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final _camera = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _done = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _detected(BarcodeCapture capture) {
    final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (code == null || _done) return;
    _done = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l.scanWithCamera),
        actions: [
          IconButton(tooltip: l.scanTorch, onPressed: _camera.toggleTorch, icon: const Icon(Icons.flashlight_on_outlined)),
        ],
      ),
      body: Stack(fit: StackFit.expand, children: [
        MobileScanner(
          controller: _camera,
          onDetect: _detected,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AbySpace.s6),
              child: Text(
                error.errorCode == MobileScannerErrorCode.permissionDenied ? l.scanNoPermission : l.scanCameraError,
                textAlign: TextAlign.center,
                style: AbyText.body.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
        // Where to hold the code.
        Center(
          child: Container(
            width: 260,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AbySpace.s8,
          child: Text(l.scanHint, textAlign: TextAlign.center, style: AbyText.body.copyWith(color: Colors.white)),
        ),
      ]),
    );
  }
}
