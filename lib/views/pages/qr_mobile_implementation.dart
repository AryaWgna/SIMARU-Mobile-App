import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

// Callback typedefs
typedef QRViewCallback = void Function(QRViewController controller);
typedef QRCodeCallback = void Function(String? code);

Widget buildQRView(BuildContext context, GlobalKey key,
    QRCodeCallback onCodeDetected, QRViewCallback onControllerCreated) {
  return QRView(
    key: key,
    onQRViewCreated: (controller) {
      onControllerCreated(controller);

      controller.scannedDataStream.listen((scanData) {
        if (scanData.code != null) {
          onCodeDetected(scanData.code);
        }
      });
    },
    overlay: QrScannerOverlayShape(
      borderColor: Colors.transparent,
      borderRadius: 4,
      borderLength: 0,
      borderWidth: 0,
      cutOutSize: 200,
    ),
  );
}

void handleReassemble(dynamic controller) {
  if (controller != null) {
    if (Platform.isAndroid) {
      controller.pauseCamera();
    } else if (Platform.isIOS) {
      controller.resumeCamera();
    }
  }
}

void toggleFlash(dynamic controller) async {
  if (controller != null) {
    await controller.toggleFlash();
  }
}

void flipCamera(dynamic controller) async {
  if (controller != null) {
    await controller.flipCamera();
  }
}

void disposeController(dynamic controller) {
  if (controller != null) {
    controller.dispose();
  }
}
