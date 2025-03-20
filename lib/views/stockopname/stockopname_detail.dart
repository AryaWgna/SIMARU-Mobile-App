// stockopname_detail_form_screen.dart
import 'package:flutter/material.dart';
import 'stockopname_scan_completed.dart';
import 'dart:io';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class StockopnameDetailFormScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  final Map<String, dynamic> task;

  const StockopnameDetailFormScreen({
    super.key,
    required this.asset,
    required this.task,
  });

  @override
  _StockopnameDetailFormScreenState createState() =>
      _StockopnameDetailFormScreenState();
}

class _StockopnameDetailFormScreenState
    extends State<StockopnameDetailFormScreen> {
  late TextEditingController _notesController;
  // Variabel untuk menyimpan nilai yang dipilih (awalnya null)
  String? _selectedCondition;
  final List<String> _conditions = ['Good', 'Fair', 'Poor', 'Damaged'];

  // Tambahkan state untuk menampilkan form
  bool _showForm = false;

  // Tambahkan variabel QR scanner
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Barcode? result;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.asset['notes'] ?? '');
    if (widget.asset['condition'] != null &&
        widget.asset['condition'].isNotEmpty &&
        _conditions.contains(widget.asset['condition'])) {
      _selectedCondition = widget.asset['condition'];
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    controller?.dispose();
    super.dispose();
  }

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

  // Ganti fungsi _scanQRCode dengan fungsi yang memanfaatkan hasil scan
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  // Navigasi ke completed screen
  void _navigateToCompleted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockopnameScanCompletedScreen(task: widget.task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // QR Scanner view dengan Expanded agar mengisi ruang tersisa
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

                // Judul - tetap terlihat meskipun bottom sheet muncul
                Positioned(
                  top: screenHeight * 0.12,
                  child: const Text(
                    'Scan your QR Code',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),

                // Frame scanner kustom - HANYA tampilkan jika bottom sheet TIDAK muncul
                if (!_showForm)
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
                              child: _buildCornerLine(true, true)),
                          Positioned(
                              top: 0,
                              right: 0,
                              child: _buildCornerLine(false, true)),
                          Positioned(
                              bottom: 0,
                              left: 0,
                              child: _buildCornerLine(true, false)),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: _buildCornerLine(false, false)),
                        ],
                      ),
                    ),
                  ),

                // Tombol flash dan flip kamera tetap terlihat
                Positioned(
                  top: 40,
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

                Positioned(
                  top: 40,
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

                // Tampilan hasil scan dan tombol scan - hanya tampil jika bottom sheet tidak muncul
                if (!_showForm) ...[
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
                  Positioned(
                    bottom: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (result != null && result!.code != null) {
                          setState(() {
                            _showForm = true;
                          });
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
              ],
            ),
          ),

          // Detail Form Container yang otomatis menampilkan semua konten
          if (_showForm)
            Container(
              height: screenHeight *
                  0.65, // Ukuran diperkecil sedikit agar lebih kelihatan QR code di atas
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    left: 24, right: 24, top: 25, bottom: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar di bagian atas
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Asset Name and Location - styling sesuai desain
                    const Text(
                      'Assets Name',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Building A, ICU 1st Floor',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Condition Dropdown
                    const Text(
                      'Actual Condition',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCondition,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.black54),
                          hint: const Text(
                            'Select Condition',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                          items: _conditions.map((String condition) {
                            return DropdownMenuItem<String>(
                              value: condition,
                              child: Text(
                                condition,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCondition = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notes TextField
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD9D9D9)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                          hintText: 'Enter Notes',
                          hintStyle: TextStyle(
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Insert Image Title
                    const Text(
                      'Insert Your Image',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const Text(
                      'Add your picture here, and you can upload max 5 mb',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF6D6D6D),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Image Upload area dengan border dashed berwarna biru
                    Container(
                      width: double.infinity,
                      height: 144,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF213268),
                          width: 1,
                          style: BorderStyle.none,
                        ),
                      ),
                      child: CustomPaint(
                        painter: DashedBlueBorderPainter(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload,
                              color: Color(0xFF213268),
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Drag your file(s) or ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1C),
                                  ),
                                ),
                                const Text(
                                  'browse',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF213268),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'jpg, png, or svg',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Color(0xFFAFAFAF),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tombol submit sekarang langsung di dalam Column
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF213268),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final condition = _selectedCondition ?? 'Good';
                            final updatedAsset = {
                              ...widget.asset,
                              'condition': condition,
                              'notes': _notesController.text,
                              'status': 'Found',
                            };
                            _navigateToCompleted();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Center(
                            child: Text(
                              'Submit',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFF5F5F5),
                              ),
                            ),
                          ),
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

  // Fungsi untuk membuat garis sudut pada frame luar (sama seperti di QRScannerScreen)
  Widget _buildCornerLine(bool isLeft, bool isTop) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: CornerLinePainter(isLeft, isTop),
      ),
    );
  }
}

// Painter untuk membuat garis sudut (sama seperti di QRScannerScreen)
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

// Ganti DashedBorderPainter dengan yang baru dengan warna biru
class DashedBlueBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = const Color(0xFF213268) // Warna biru sesuai desain
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Top line
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Right line
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Bottom line
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX + dashWidth, size.height),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Left line
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
