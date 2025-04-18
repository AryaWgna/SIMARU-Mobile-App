import 'package:flutter/material.dart';

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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pemindai QR Web',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Masukkan kode QR aset secara manual:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Contoh: ANMD-250324-0001',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Untuk testing/demo, ini bisa diubah ke ID yang berbeda
                onCodeDetected('ANMD-250324-0001');
              },
              child: const Text('Gunakan ID Demo (ANMD-250324-0001)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213268),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                // Untuk testing dengan ID yang berbeda
                onCodeDetected('10');
              },
              child: const Text('Gunakan Asset ID: 10'),
            ),
          ],
        ),
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
