import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import '../asset/asset_details.dart';
import '../../services/socket_service.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../../controllers/auth_controller.dart' as auth;
import 'package:google_fonts/google_fonts.dart';
import 'scan_result_screen.dart';
import 'package:flutter/rendering.dart' as ui;

class StockopnameScanner extends StatefulWidget {
  final String previousScreen;
  final int roomId;
  final String roomName;
  final int totalAssets;
  final int opnameId;
  final String opnameCode;

  const StockopnameScanner({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.totalAssets,
    required this.opnameId,
    required this.opnameCode,
    this.previousScreen = 'stockopname',
  }) : super(key: key);

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
    final double scannerSize = 250;
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
  String? scannedCode;
  String? lastScannedCode;
  Timer? debounceTimer;
  bool isProcessing = false;
  bool flashOn = false;
  int scannedAssets = 0;
  List<String> scannedAssetCodes = [];

  // Animasi untuk scanner
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !isProcessing) {
        if (scanData.code != lastScannedCode) {
          setState(() {
            scannedCode = scanData.code;
          });

          debounceTimer?.cancel();
          debounceTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted && !isProcessing) {
              _processScannedQR(scanData.code!);
            }
          });
        }
      }
    });
  }

  Future<void> _processScannedQR(String qrCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final assetCode = qrCode.trim();

      // Validasi format QR
      bool isValidFormat =
          assetCode.startsWith('ANMD-') || RegExp(r'^\d+$').hasMatch(assetCode);
      if (!isValidFormat) {
        _showError('Format kode QR tidak valid');
        setState(() {
          isProcessing = false;
        });
        return;
      }

      // Cek apakah asset sudah di-scan sebelumnya
      if (scannedAssetCodes.contains(assetCode)) {
        _showError('Aset ini sudah dipindai sebelumnya');
        setState(() {
          isProcessing = false;
        });
        return;
      }

      // Kirim data scan ke API
      final response = await auth.ApiService.post(
        '/asset-opname-details',
        body: {
          'opname_id': widget.opnameId,
          'actual_location_id': widget.roomId,
          'asset_code': assetCode,
        },
        context: context,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          // Tambahkan ke daftar asset yang sudah di-scan
          setState(() {
            scannedAssetCodes.add(assetCode);
            scannedAssets++;
            lastScannedCode = assetCode;
          });

          // Tampilkan notifikasi sukses
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
        } else {
          throw data['message'] ?? 'Gagal memindai aset';
        }
      } else {
        final data = jsonDecode(response.body);
        throw data['message'] ?? 'Gagal memindai aset';
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
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
    if (scannedAssets == 0) {
      _showError('Belum ada aset yang dipindai');
      return;
    }

    try {
      setState(() {
        isProcessing = true;
      });

      // Kirim data ke server untuk menyelesaikan stockopname
      final response = await auth.ApiService.post(
        '/asset-opnames/${widget.opnameId}/complete',
        body: {},
        context: context,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          if (mounted) {
            // Navigate to scan result screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ScanResultScreen(
                  scannedAssets: scannedAssetCodes,
                  roomName: widget.roomName,
                  opnameId: widget.opnameId,
                  opnameCode: widget.opnameCode,
                ),
              ),
            );
          }
        } else {
          throw data['message'] ?? 'Gagal menyelesaikan stockopname';
        }
      } else {
        final data = jsonDecode(response.body);
        throw data['message'] ?? 'Gagal menyelesaikan stockopname';
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // QR Scanner View
          Positioned.fill(
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: const Color(0xFF213268),
                borderRadius: 20,
                borderLength: 40,
                borderWidth: 10,
                cutOutSize: 250,
                cutOutBottomOffset: 0,
                overlayColor: Colors.black.withOpacity(0.7),
              ),
              formatsAllowed: const [BarcodeFormat.qrcode],
            ),
          ),

          // Animasi garis scanner yang lebih jelas
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ScannerLinePainter(_animation.value),
                  );
                },
              ),
            ),
          ),

          // Header dengan icon dan title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF213268),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SCAN IN PROGRESS',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.opnameCode} - ${widget.roomName}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status Panel
          Positioned(
            top: 120,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF213268).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1)),
              child: Column(
                children: [
                  _buildStatusRow('Total Asset', widget.totalAssets.toString()),
                  const SizedBox(height: 8),
                  _buildStatusRow('Scanned Asset', scannedAssets.toString()),
                  const SizedBox(height: 8),
                  if (widget.totalAssets > 0)
                    LinearProgressIndicator(
                      value: scannedAssets / widget.totalAssets,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                ],
              ),
            ),
          ),

          // Scanned Tag ID
          if (scannedCode != null)
            Positioned(
              top: 200,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TagID:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scannedCode!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF213268),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Complete Scan Button
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _completeScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213268),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: Text(
                'COMPLETE SCAN',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Flash Toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () {
                controller?.toggleFlash();
                setState(() {
                  flashOn = !flashOn;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF213268),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  flashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Loading Indicator
          if (isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memproses Data...',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
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

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
