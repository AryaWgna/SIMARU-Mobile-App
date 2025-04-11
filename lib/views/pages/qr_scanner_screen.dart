import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../asset/asset_details.dart';

class QRScannerScreen extends StatefulWidget {
  final String previousScreen;

  const QRScannerScreen({super.key, this.previousScreen = 'home'});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;

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
    return Scaffold(
      // Penting: set false agar layout tidak berubah saat keyboard muncul
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // QR Camera View sebagai background
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

          // Judul di bagian atas
          const Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Pindai Kode QR',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Frame scanner di tengah
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildCornerLine(true, true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildCornerLine(false, true),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildCornerLine(true, false),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildCornerLine(false, false),
                  ),
                ],
              ),
            ),
          ),

          // Hasil scan
          if (result != null)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: () async {
                  await controller?.flipCamera();
                },
              ),
            ),
          ),
        ],
      ),

      // KUNCI SOLUSI: Tambahkan bottomNavigationBar agar floatingActionButton centerDocked bisa berfungsi
      // dengan benar dan menghilang saat keyboard muncul
      bottomNavigationBar: Container(
        // Atur height minimal untuk invisible bottomNavigationBar
        height: 1,
        color: Colors.transparent,
      ),

      // Gunakan floatingActionButtonLocation yang sama dengan Dashboard
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Pindahkan tombol Scan ke floatingActionButton
      floatingActionButton: Container(
        width: 220, // Sesuaikan dengan lebar button asli
        height: 50, // Sesuaikan dengan tinggi button asli
        margin: const EdgeInsets.only(bottom: 30), // Untuk posisi yang tepat
        child: FloatingActionButton.extended(
          elevation: 2,
          backgroundColor: const Color(0xFF2A3F7E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onPressed: () {
            FocusScope.of(context).unfocus();

            if (result != null && result!.code != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssetDetails(
                    qrData: result!.code!,
                    previousScreen: widget.previousScreen,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Silakan scan QR code terlebih dahulu'),
                  backgroundColor: Color(0xFF213268),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          icon: SizedBox(
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
          label: const Text(
            'Pindai Kode QR',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

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
    final length = size.width * 0.8;

    if (isLeft && isTop) {
      path.moveTo(0, length);
      path.lineTo(0, 0);
      path.lineTo(length, 0);
    } else if (!isLeft && isTop) {
      path.moveTo(size.width - length, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, length);
    } else if (isLeft && !isTop) {
      path.moveTo(0, size.height - length);
      path.lineTo(0, size.height);
      path.lineTo(length, size.height);
    } else {
      path.moveTo(size.width - length, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, size.height - length);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
