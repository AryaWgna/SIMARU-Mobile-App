import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Jenis callback yang sama dengan implementasi mobile
typedef QRViewCallback = void Function(dynamic controller);
typedef QRCodeCallback = void Function(String? code);

Widget buildQRView(BuildContext context, GlobalKey key,
    QRCodeCallback onCodeDetected, QRViewCallback onControllerCreated) {
  // Implementasi web dengan input manual untuk QR code
  // Sebagai pengganti pemindai yang tidak tersedia di web
  return StatefulBuilder(builder: (context, setState) {
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
                          onCodeDetected(value.trim());
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
                      onCodeDetected('ANMD-250324-0001');
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
                      onCodeDetected('10');
                    },
                    child: Text(
                      'Gunakan Asset ID: 10',
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
  });
}

// Dummy methods untuk web
void handleReassemble(dynamic controller) {
  // Tidak perlu implementasi di web
}

void toggleFlash(dynamic controller) {
  // Tidak perlu implementasi di web
}

void flipCamera(dynamic controller) {
  // Tidak perlu implementasi di web
}

void disposeController(dynamic controller) {
  // Tidak perlu implementasi di web
}
