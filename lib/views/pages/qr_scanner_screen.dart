import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../asset/asset_details.dart';
import '../../services/socket_service.dart';
import '../../controllers/qr_scanner_controller.dart';

// Impor QR code scanner dengan conditional import
import 'qr_mobile_implementation.dart'
    if (dart.library.html) 'qr_web_implementation.dart';

class QRScannerScreen extends StatefulWidget {
  final String previousScreen;

  const QRScannerScreen({super.key, this.previousScreen = 'home'});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRScannerController _qrScannerController;

  // Untuk animasi scanner
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Untuk zoom
  double _currentZoomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    // Mendaftarkan observer untuk lifecycle aplikasi
    WidgetsBinding.instance.addObserver(this);

    _qrScannerController =
        Provider.of<QRScannerController>(context, listen: false);
    _qrScannerController.reset();

    // Tambahkan state ke controller
    _qrScannerController.setCameraInitialized(false);
    _qrScannerController.setCameraPaused(false);

    // Setup animasi naik turun
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: -35.0, end: 35.0).animate(_animationController);

    // Koneksikan socket saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (!socketService.isConnected) {
        socketService.connect();
      }
    });
  }

  @override
  void dispose() {
    // Unregister observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose QR controller
    _qrScannerController.disposeQRController();

    // Dispose animation controller
    _animationController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manage camera based on app lifecycle
    if (_qrScannerController.qrViewController == null) return;

    if (state == AppLifecycleState.resumed) {
      _qrScannerController.resumeCamera();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _qrScannerController.pauseCamera();
    }
  }

  // Show notification
  void showNotice(String message,
      {bool isSuccess = false, bool isError = false, bool isWarning = false}) {
    Color backgroundColor = Colors.blue;
    if (isSuccess) backgroundColor = Colors.green;
    if (isWarning) backgroundColor = Colors.orange;
    if (isError) backgroundColor = Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
          left: 20.0,
          right: 20.0,
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    if (!kIsWeb) {
      _qrScannerController.reassembleCamera();
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoomFactor += 0.2;
      if (_currentZoomFactor > 2.5) {
        _currentZoomFactor = 2.5;
      }
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoomFactor -= 0.2;
      if (_currentZoomFactor < 1.0) {
        _currentZoomFactor = 1.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Consumer<QRScannerController>(
      builder: (context, controller, _) {
        return WillPopScope(
          onWillPop: () async {
            // Matikan kamera sebelum kembali ke halaman sebelumnya
            controller.pauseCamera();

            // Kembali ke halaman sebelumnya
            Navigator.pop(context);
            return false;
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // QR Camera View dengan zoom
                Transform.scale(
                  scale: _currentZoomFactor,
                  child: kIsWeb
                      ? buildQRView(context, qrKey, (code) {
                          // Callback ketika QR terdeteksi untuk web
                          if (code != null && !controller.isProcessing) {
                            controller.setScannedCode(code);

                            // Proses QR langsung tanpa debounce jika berbeda
                            if (code != controller.lastScannedCode) {
                              _processQRCode(code, socketService, controller);
                            }
                          }
                        }, (webController) {
                          // Tidak perlu menyimpan controller untuk web
                        })
                      : buildQRView(context, qrKey, (code) {
                          // Callback ketika QR terdeteksi untuk mobile
                          if (code != null && !controller.isProcessing) {
                            controller.setScannedCode(code);

                            // Proses QR dengan debounce untuk mencegah multiple scans
                            if (code != controller.lastScannedCode) {
                              _processQRCode(code, socketService, controller);
                            }
                          }
                        }, (mobileController) {
                          // Simpan controller untuk mobile
                          controller.setQRViewController(mobileController);
                          // Resume camera jika sebelumnya paused
                          if (!controller.isCameraInitialized) {
                            controller.resumeCamera();
                            controller.setCameraInitialized(true);
                          }
                        }),
                ),

                // Animasi Garis Scanner
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ScannerLinePainter(_animation.value),
                      size: Size.infinite,
                    );
                  },
                ),

                // Top Bar dengan tombol kembali dan flash
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tombol Kembali
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                color: const Color(0xFF213268),
                                onPressed: () {
                                  controller.pauseCamera();
                                  Navigator.pop(context);
                                },
                              ),
                            ),

                            // Flash Button
                            if (!kIsWeb)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    controller.flashOn
                                        ? Icons.flash_on
                                        : Icons.flash_off,
                                  ),
                                  color: const Color(0xFF213268),
                                  onPressed: () {
                                    controller.toggleFlash();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Zoom Controls
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).size.height / 2 - 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          color: const Color(0xFF213268),
                          onPressed: _zoomIn,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.remove),
                          color: const Color(0xFF213268),
                          onPressed: _zoomOut,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Panel
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Row(
                              children: [
                                // QR Icon
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF213268)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Color(0xFF213268),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Scanner Info
                                Expanded(
                                  child: Text(
                                    'Scan QR Code Aset',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF213268),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Scanned Code
                            if (controller.scannedCode != null &&
                                controller.isProcessing)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.qr_code,
                                      color: Color(0xFF213268),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'QR Code Terdeteksi:',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            controller.scannedCode!,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Status Text
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF213268).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                controller.isProcessing
                                    ? 'Memproses QR Code...'
                                    : 'Arahkan kamera ke QR Code aset',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF213268),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            // Error Message
                            if (controller.errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.red.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        controller.errorMessage!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.red,
                                        ),
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

                // Loading Overlay
                if (controller.isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),

                // Zoom factor indicator
                Positioned(
                  top: 80,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${(_currentZoomFactor * 100).toInt()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Process QR Code
  Future<void> _processQRCode(String qrCode, SocketService socketService,
      QRScannerController controller) async {
    // Pause camera while processing
    controller.pauseCamera();

    // Process QR code using controller
    final assetData =
        await controller.processScannedQR(qrCode, socketService, context);

    if (assetData != null) {
      // Show success notification
      showNotice("QR Code berhasil dipindai", isSuccess: true);

      // Navigate to asset details
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetails(
              qrData: qrCode,
              previousScreen: widget.previousScreen,
              assetData: assetData,
            ),
          ),
        );
      }
    } else if (controller.errorMessage != null) {
      // Show error notification
      showNotice(controller.errorMessage!, isError: true);

      // Resume camera
      controller.resumeCamera();
    }
  }
}

// Scanner Line Painter
class ScannerLinePainter extends CustomPainter {
  final double yOffset;

  ScannerLinePainter(this.yOffset);

  @override
  void paint(Canvas canvas, Size size) {
    // Hitung ukuran dan posisi scanner
    const double scannerSize = 250;
    final double scannerLeft = (size.width - scannerSize) / 2;
    final double scannerTop = (size.height - scannerSize) / 2;

    // Posisi garis scanner dengan animasi
    final double lineY = scannerTop + (scannerSize / 2) + yOffset;

    // Buat paint untuk garis
    final Paint paint = Paint()
      ..color = const Color(0xFF213268)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Gambar garis utama
    canvas.drawLine(
      Offset(scannerLeft, lineY),
      Offset(scannerLeft + scannerSize, lineY),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScannerLinePainter oldDelegate) {
    return oldDelegate.yOffset != yOffset;
  }
}
