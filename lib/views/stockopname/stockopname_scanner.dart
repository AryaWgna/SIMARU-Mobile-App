import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'scan_result_screen.dart';
import '../../controllers/stockopname_controller.dart';

class StockopnameScanner extends StatefulWidget {
  final String previousScreen;
  final int roomId;
  final String roomName;
  final int totalAssets;
  final int opnameId;
  final String opnameCode;

  const StockopnameScanner({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.totalAssets,
    required this.opnameId,
    required this.opnameCode,
    this.previousScreen = 'stockopname',
  });

  @override
  State<StockopnameScanner> createState() => _StockopnameScannerState();
}

// Class untuk melukis garis scanner
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

class _StockopnameScannerState extends State<StockopnameScanner>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Timer? debounceTimer;
  late StockOpnameController _stockOpnameController;

  // Animasi untuk scanner
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Untuk zoom
  double _currentZoomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stockOpnameController =
        Provider.of<StockOpnameController>(context, listen: false);
    _stockOpnameController
        .resetItems(); // Reset item setiap kali buka scanner baru

    // Setup animasi naik turun
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: -35.0, end: 35.0).animate(_animationController);
  }

  @override
  void dispose() {
    controller?.dispose();
    debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller?.resumeCamera();
    } else {
      controller?.pauseCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    // Check flash availability
    controller.getFlashStatus().then((value) {
      _stockOpnameController.setFlashAvailability(value ?? false);
    });

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_stockOpnameController.processingQR) {
        // Langsung proses QR tanpa debounce untuk respons yang lebih cepat
        if (scanData.code != _stockOpnameController.lastScannedCode) {
          _stockOpnameController.setScannedCode(scanData.code);
          if (mounted && !_stockOpnameController.isLoading) {
            _processScannedQR(scanData.code!);
          }
        }
      }
    });
  }

  Future<void> _processScannedQR(String qrCode) async {
    _stockOpnameController.setProcessingQR(true);

    bool success = await _stockOpnameController.processScannedQR(
        qrCode, widget.opnameId, widget.roomId, context);

    if (success) {
      // Notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aset berhasil dipindai: $qrCode'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
            left: 20.0,
            right: 20.0,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (_stockOpnameController.error != null) {
      _showError(_stockOpnameController.error!);
    }

    _stockOpnameController.setProcessingQR(false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0 ? 90.0 : 70.0,
          left: 20.0,
          right: 20.0,
        ),
      ),
    );
  }

  Future<void> _completeScan() async {
    final success = await _stockOpnameController.completeStockOpname(
        widget.opnameId, context);

    if (success) {
      if (mounted) {
        // Navigate to scan result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(
              scannedAssets: _stockOpnameController.scannedItems
                  .map((item) => item.assetCode)
                  .toList(),
              roomName: widget.roomName,
              opnameId: widget.opnameId,
              opnameCode: widget.opnameCode,
            ),
          ),
        );
      }
    } else {
      // Tampilkan error jika gagal
      if (_stockOpnameController.error != null) {
        _showError(_stockOpnameController.error!);
      }
    }
  }

  void _toggleFlash() {
    controller?.toggleFlash();
    _stockOpnameController.toggleFlash();
  }

  void _flipCamera() {
    controller?.flipCamera();
    _stockOpnameController.toggleCamera();
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
    return Consumer<StockOpnameController>(
      builder: (context, stockOpnameController, _) => Scaffold(
        body: Stack(
          children: [
            // QR Scanner View with zoom
            Transform.scale(
              scale: _currentZoomFactor,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
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
                      const SnackBar(
                          content: Text('Izin kamera tidak diberikan')),
                    );
                  }
                },
              ),
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

            // Top Bar dengan Informasi
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
                              Navigator.pop(context);
                            },
                          ),
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            // Flash button pada posisi yang sama dengan tombol kamera sebelumnya
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
                                  stockOpnameController.flashOn
                                      ? Icons.flash_on
                                      : Icons.flash_off,
                                ),
                                color: const Color(0xFF213268),
                                onPressed: _toggleFlash,
                              ),
                            ),
                          ],
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

            // Bottom Bar dengan Informasi Scanning
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
                        // Info Section
                        Row(
                          children: [
                            // Room Icon
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF213268).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.meeting_room,
                                color: Color(0xFF213268),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Room Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.roomName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF213268),
                                    ),
                                  ),
                                  Text(
                                    'Total Aset: ${widget.totalAssets}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Scanned Counter
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF213268),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${stockOpnameController.scannedItems.length}/${widget.totalAssets}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Last scanned asset
                        if (stockOpnameController.scannedItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Terakhir Dipindai:',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        stockOpnameController
                                            .scannedItems.last.assetCode,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Button to Complete Scan
                        ElevatedButton.icon(
                          onPressed: stockOpnameController.isLoading
                              ? null
                              : _completeScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF213268),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          icon: stockOpnameController.isLoading
                              ? Container(
                                  width: 24,
                                  height: 24,
                                  padding: const EdgeInsets.all(2.0),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            stockOpnameController.isLoading
                                ? 'Memproses...'
                                : 'Selesaikan Pemindaian',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading Indicator saat Memproses QR
            if (stockOpnameController.processingQR)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
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
  }
}
