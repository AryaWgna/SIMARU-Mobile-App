import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Jenis callback yang sama dengan implementasi mobile
typedef QRViewCallback = void Function(MobileScannerController controller);
typedef QRCodeCallback = void Function(String? code);

// Gunakan StatefulWidget untuk mempertahankan state kamera
class WebQRScanner extends StatefulWidget {
  final GlobalKey key;
  final QRCodeCallback onCodeDetected;
  final QRViewCallback onControllerCreated;

  const WebQRScanner({
    required this.key,
    required this.onCodeDetected,
    required this.onControllerCreated,
  });

  @override
  State<WebQRScanner> createState() => _WebQRScannerState();
}

class _WebQRScannerState extends State<WebQRScanner> {
  bool isUsingCamera = false;
  MobileScannerController? controller;

  void toggleScanMode() {
    setState(() {
      isUsingCamera = !isUsingCamera;
      if (isUsingCamera) {
        controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
        widget.onControllerCreated(controller!);
      } else {
        controller?.dispose();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isUsingCamera) {
      return Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                widget.onCodeDetected(barcodes.first.rawValue);
              }
            },
          ),
          // Scanner Overlay
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
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF213268),
                ),
                onPressed: toggleScanMode,
                child: const Text('Gunakan Input Manual'),
              ),
            ),
          ),
        ],
      );
    }

    // Input manual untuk web
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Background hitam dengan overlay
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFF213268),
                    width: 10,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // Form input di tengah
          Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: const Color(0xFF213268),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pemindai QR Web',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213268),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Masukkan kode QR aset secara manual:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Contoh: ANMD-250324-0001',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          widget.onCodeDetected(value.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF213268),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Untuk testing/demo, ini bisa diubah ke ID yang berbeda
                      widget.onCodeDetected('ANMD-250324-0001');
                    },
                    child: Text(
                      'Gunakan ID Demo (ANMD-250324-0001)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF213268),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Untuk testing dengan ID yang berbeda
                      widget.onCodeDetected('10');
                    },
                    child: Text(
                      'Gunakan Asset ID: 10',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: toggleScanMode,
                    child: Text(
                      'Coba Gunakan Kamera',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Function untuk membangun QR view
Widget buildQRView(BuildContext context, GlobalKey key,
    QRCodeCallback onCodeDetected, QRViewCallback onControllerCreated) {
  return WebQRScanner(
    key: key,
    onCodeDetected: onCodeDetected,
    onControllerCreated: onControllerCreated,
  );
}

// Dummy methods untuk web
void handleReassemble(dynamic controller) {
  // Tidak perlu implementasi di web
}

void toggleFlash(dynamic controller) {
  // Tidak perlu implementasi flash di web
}

void flipCamera(dynamic controller) {
  // Tidak perlu implementasi flip camera di web
}

void disposeController(dynamic controller) {
  if (controller != null && controller is MobileScannerController) {
    controller.dispose();
  }
}

// Kelas untuk overlay scanner
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
