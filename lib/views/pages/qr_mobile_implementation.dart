import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Callback typedefs
typedef QRViewCallback = void Function(MobileScannerController controller);
typedef QRCodeCallback = void Function(String? code);

Widget buildQRView(BuildContext context, GlobalKey key,
    QRCodeCallback onCodeDetected, QRViewCallback onControllerCreated) {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  onControllerCreated(controller);

  return Stack(
    children: [
      MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            onCodeDetected(barcodes.first.rawValue);
          }
        },
      ),
      CustomPaint(
        painter: ScannerOverlayPainter(
          borderColor: const Color(0xFF213268),
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
          overlayColor: Colors.black.withOpacity(0.5),
        ),
        child: Container(),
      ),
    ],
  );
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;
  final Color overlayColor;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
    required this.overlayColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cutOutLeft = (width - cutOutSize) / 2;
    final cutOutTop = (height - cutOutSize) / 2;
    final cutOutRect = Rect.fromLTWH(
      cutOutLeft,
      cutOutTop,
      cutOutSize,
      cutOutSize,
    );
    final cutOutRRectPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
      );

    // Draw overlay
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addPath(cutOutRRectPath, Offset.zero)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, Paint()..color = overlayColor);

    // Draw border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft, cutOutTop + borderLength)
        ..lineTo(cutOutLeft, cutOutTop + borderRadius)
        ..arcToPoint(
          Offset(cutOutLeft + borderRadius, cutOutTop),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft + borderLength, cutOutTop),
      borderPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + cutOutSize - borderLength, cutOutTop)
        ..lineTo(cutOutLeft + cutOutSize - borderRadius, cutOutTop)
        ..arcToPoint(
          Offset(cutOutLeft + cutOutSize, cutOutTop + borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft + cutOutSize, cutOutTop + borderLength),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + cutOutSize, cutOutTop + cutOutSize - borderLength)
        ..lineTo(cutOutLeft + cutOutSize, cutOutTop + cutOutSize - borderRadius)
        ..arcToPoint(
          Offset(
              cutOutLeft + cutOutSize - borderRadius, cutOutTop + cutOutSize),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(
            cutOutLeft + cutOutSize - borderLength, cutOutTop + cutOutSize),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + borderLength, cutOutTop + cutOutSize)
        ..lineTo(cutOutLeft + borderRadius, cutOutTop + cutOutSize)
        ..arcToPoint(
          Offset(cutOutLeft, cutOutTop + cutOutSize - borderRadius),
          radius: Radius.circular(borderRadius),
        )
        ..lineTo(cutOutLeft, cutOutTop + cutOutSize - borderLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

void handleReassemble(dynamic controller) {
  if (controller != null && controller is MobileScannerController) {
    if (Platform.isAndroid) {
      controller.stop();
      controller.start();
    }
  }
}

void toggleFlash(dynamic controller) async {
  if (controller != null && controller is MobileScannerController) {
    await controller.toggleTorch();
  }
}

void flipCamera(dynamic controller) async {
  if (controller != null && controller is MobileScannerController) {
    await controller.switchCamera();
  }
}

void disposeController(dynamic controller) {
  if (controller != null && controller is MobileScannerController) {
    controller.dispose();
  }
}
