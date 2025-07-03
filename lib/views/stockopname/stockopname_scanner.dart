import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'scan_result_screen.dart';
import '../../controllers/stockopname_controller.dart';
import 'stockopname_scanner_stub.dart';
import '../../utils/logger_util.dart';

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

// Class untuk overlay pemindai
class ScannerOverlayShape extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;
  final Color overlayColor;

  ScannerOverlayShape({
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

class _StockopnameScannerState extends State<StockopnameScanner>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  dynamic controller;
  Timer? debounceTimer;
  late StockOpnameController _stockOpnameController;

  // Animasi untuk scanner
  late AnimationController _animationController;
  late Animation<double> _animation;

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

    // Tambahkan post-frame callback untuk menghindari setState selama build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Inisialisasi controller di sini jika perlu
      }
    });
  }

  @override
  void dispose() {
    disposeController(controller);
    debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    handleReassemble(controller);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (controller == null) return;

    if (state == AppLifecycleState.resumed) {
      if (controller is MobileScannerController) {
        controller.start();
      }
    } else {
      if (controller is MobileScannerController) {
        controller.stop();
      }
    }
  }

  void _onBarcodeDetect(String? code) {
    if (code == null) return;

    if (!_stockOpnameController.processingQR) {
      // Langsung proses QR tanpa debounce untuk respons yang lebih cepat
      if (code != _stockOpnameController.lastScannedCode) {
        _stockOpnameController.setScannedCode(code);
        // Gunakan post-frame callback untuk menghindari setState selama build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_stockOpnameController.isLoading) {
            _processScannedQR(code);
          }
        });
      }
    }
  }

  Future<void> _processScannedQR(String qrCode) async {
    _stockOpnameController.setProcessingQR(true);

    try {
      // Validate and extract asset code from QR
      final String assetCode = _extractAssetCode(qrCode);

      bool success = await _stockOpnameController.processScannedQR(
          assetCode, widget.opnameId, widget.roomId, context);

      if (success) {
        // Notifikasi sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aset berhasil dipindai: $assetCode'),
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
    } catch (e) {
      // Handle exceptions from QR code extraction or processing
      _showError(e.toString().replaceAll('Exception: ', ''));
      LoggerUtil.e('Error processing QR code', e, StackTrace.current);
    } finally {
      _stockOpnameController.setProcessingQR(false);
    }
  }

  // Extract asset code from QR code, handling different formats
  String _extractAssetCode(String code) {
    if (code.trim().isEmpty) {
      throw Exception('Format kode QR tidak valid: kode kosong');
    }

    String assetCode;

    try {
      if (code.contains('/')) {
        // Extract asset code from URL
        final uri = Uri.parse(code);
        final pathSegments = uri.pathSegments;

        if (pathSegments.isEmpty) {
          throw Exception(
              'Format kode QR tidak valid: URL tidak memiliki path');
        }

        assetCode = pathSegments.last;
      } else {
        // Use the code directly as asset code
        assetCode = code.trim();
      }

      // Validate asset code format if needed
      if (assetCode.isEmpty) {
        throw Exception('Kode aset tidak valid: kode kosong');
      }

      return assetCode;
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Format kode QR tidak valid: bukan URL yang valid');
      }
      throw e; // Re-throw other exceptions
    }
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
    toggleFlash(controller);
    _stockOpnameController.toggleFlash();
  }

  void _flipCamera() {
    flipCamera(controller);
    _stockOpnameController.toggleCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StockOpnameController>(
      builder: (context, stockOpnameController, _) => Scaffold(
        body: Stack(
          children: [
            // QR Scanner View menggunakan implementasi kondisional
            buildScannerView(
              context,
              qrKey,
              _onBarcodeDetect,
              (scannerController) {
                // Gunakan post-frame callback untuk menghindari setState selama build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      controller = scannerController;
                    });
                  }
                });
              },
              stockOpnameController,
            ),

            // Animasi Garis Scanner (hanya ditampilkan jika bukan web)
            if (!kIsWeb)
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

            // Bottom Bar dengan Informasi dan Action
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).padding.bottom > 0 ? 34.0 : 16.0,
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info Panel
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              const Icon(
                                Icons.qr_code_scanner,
                                color: Color(0xFF213268),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stockopname: ${widget.roomName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF213268),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progress
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Progress: ${stockOpnameController.scannedItems.length}/${widget.totalAssets}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: widget.totalAssets > 0
                                          ? stockOpnameController
                                                  .scannedItems.length /
                                              widget.totalAssets
                                          : 0,
                                      backgroundColor: Colors.grey[200],
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF213268)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF213268),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: stockOpnameController.isLoading
                                    ? null
                                    : _completeScan,
                                child: Text(
                                  'Selesai',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading Indicator
            if (stockOpnameController.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
