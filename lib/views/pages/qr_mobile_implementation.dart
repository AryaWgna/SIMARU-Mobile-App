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
      borderColor: const Color(0xFF213268),
      borderRadius: 10,
      borderLength: 30,
      borderWidth: 10,
      cutOutSize: 250,
      overlayColor: Colors.black.withOpacity(0.5),
    ),
    onPermissionSet: (ctrl, p) {
      if (!p) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin kamera tidak diberikan')),
        );
      }
    },
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
