import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../asset/asset_details.dart';
import '../../widgets/custom_app_bar.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // QR Camera View
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.transparent,
                    borderRadius: 4,
                    borderLength: 0,
                    borderWidth: 0,
                    cutOutSize: 200,
                  ),
                ),

                // Judul
                Positioned(
                  top: screenHeight * 0.15,
                  child: const Text(
                    'Scan your QR Code',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Frame scanner kustom dengan sudut
                Center(
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Stack(
                      children: [
                        // Kiri atas
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildCornerLine(true, true),
                        ),
                        // Kanan atas
                        Positioned(
                          top: 0,
                          right: 0,
                          child: _buildCornerLine(false, true),
                        ),
                        // Kiri bawah
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: _buildCornerLine(true, false),
                        ),
                        // Kanan bawah
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: _buildCornerLine(false, false),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tampilan hasil scan
                if (result != null)
                  Positioned(
                    bottom: 140,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Data: ${result!.code}',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),

                // Tombol flash
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      onPressed: () async {
                        await controller?.toggleFlash();
                      },
                    ),
                  ),
                ),

                // Tombol flip kamera
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white),
                      onPressed: () async {
                        await controller?.flipCamera();
                      },
                    ),
                  ),
                ),

                // Tombol Scan
                Positioned(
                  bottom: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (result != null && result!.code != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AssetDetails(qrData: result!.code!),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Silakan scan QR code terlebih dahulu'),
                            backgroundColor: Color(0xFF213268),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A3F7E),
                      minimumSize: const Size(220, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Stack(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Garis di dalam kotak
                              Positioned(
                                top: 6,
                                left: 6,
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Scan QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membuat garis sudut pada frame luar
  Widget _buildCornerLine(bool isLeft, bool isTop) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: CornerLinePainter(isLeft, isTop),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// Painter untuk membuat garis sudut
class CornerLinePainter extends CustomPainter {
  final bool isLeft;
  final bool isTop;

  CornerLinePainter(this.isLeft, this.isTop);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    final length = size.width * 0.8; // Panjang garis

    if (isLeft && isTop) {
      // Kiri atas - L shape
      path.moveTo(0, length);
      path.lineTo(0, 0);
      path.lineTo(length, 0);
    } else if (!isLeft && isTop) {
      // Kanan atas - ┐ shape
      path.moveTo(size.width - length, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, length);
    } else if (isLeft && !isTop) {
      // Kiri bawah - └ shape
      path.moveTo(0, size.height - length);
      path.lineTo(0, size.height);
      path.lineTo(length, size.height);
    } else {
      // Kanan bawah - ┘ shape
      path.moveTo(size.width - length, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
