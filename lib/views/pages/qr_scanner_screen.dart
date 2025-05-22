import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import '../asset/asset_details.dart';
import '../../services/socket_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../controllers/auth_controller.dart' as auth;

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
    with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  dynamic controller;
  String? scannedCode;
  String? lastScannedCode;
  Timer? debounceTimer;
  bool isProcessing = false;
  bool flashOn = false;
  final _storage = const FlutterSecureStorage();

  // Pengaturan kamera untuk efisiensi
  QRViewController? qrViewController;
  bool isCameraInitialized = false;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    // Mendaftarkan observer untuk lifecycle aplikasi
    WidgetsBinding.instance.addObserver(this);

    // Koneksikan socket saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      if (!socketService.isConnected) {
        socketService.connect();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mengelola siklus hidup kamera berdasarkan state aplikasi
    if (qrViewController == null || !isCameraInitialized) return;

    // Jika aplikasi di background/tidak terlihat, pause kamera
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseCamera();
    }
    // Jika aplikasi kembali ke foreground, resume kamera
    else if (state == AppLifecycleState.resumed && isPaused) {
      resumeCamera();
    }
  }

  void pauseCamera() {
    if (qrViewController != null && !isPaused) {
      qrViewController!.pauseCamera();
      isPaused = true;
    }
  }

  void resumeCamera() {
    if (qrViewController != null && isPaused) {
      qrViewController!.resumeCamera();
      isPaused = false;
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      qrViewController = controller;
      this.controller = controller;
      isCameraInitialized = true;
    });

    // Konfigurasi scanning yang efisien
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !isProcessing) {
        // Pemrosesan kode QR dengan debounce untuk mencegah pemrosesan ganda
        if (scanData.code != lastScannedCode) {
          setState(() {
            scannedCode = scanData.code;
          });

          // Debounce menunggu 500ms sebelum memproses QR untuk menghindari multiple scans
          debounceTimer?.cancel();
          debounceTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted && !isProcessing) {
              final socketService =
                  Provider.of<SocketService>(context, listen: false);
              _processScannedQR(scanData.code!, socketService);
            }
          });
        }
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (!kIsWeb && qrViewController != null) {
      if (Platform.isAndroid) {
        qrViewController!.pauseCamera();
      }
      qrViewController!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        // Matikan kamera sebelum kembali ke halaman sebelumnya
        if (qrViewController != null) {
          qrViewController!.pauseCamera();
          isPaused = true;
        }

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // QR Camera View sebagai background dengan kontrol pemindaian efisien
            kIsWeb
                ? buildQRView(context, qrKey, (code) {
                    // Callback ketika QR terdeteksi untuk web
                    if (code != null && !isProcessing) {
                      setState(() {
                        scannedCode = code;
                      });

                      // Proses QR langsung tanpa debounce jika berbeda
                      if (code != lastScannedCode) {
                        _processScannedQR(code, socketService);
                      }
                    }
                  }, (controller) {
                    this.controller = controller;
                  })
                : QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: const Color(0xFFFFFFFF),
                      borderRadius: 20,
                      borderLength: 40,
                      borderWidth: 12,
                      cutOutSize: 250,
                      cutOutBottomOffset: 0,
                      overlayColor: Colors.black.withOpacity(0.8),
                    ),
                    // Pengaturan optimal untuk efisiensi baterai dan performa
                    formatsAllowed: const [BarcodeFormat.qrcode],
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
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Informasi format QR yang didukung
            const Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Format: ASSET-XXX, MED-XXX, NMED-XXX, ANMD-XXX',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),

            // Hasil scan
            if (scannedCode != null)
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'QR Code:',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          scannedCode!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Indikator proses
            if (isProcessing)
              Positioned(
                bottom: 210,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF213268).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Memproses QR...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tombol flash - hanya ditampilkan di mobile
            if (!kIsWeb)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: Icon(flashOn ? Icons.flash_off : Icons.flash_on,
                        color: Colors.white),
                    onPressed: () {
                      if (qrViewController != null) {
                        qrViewController!.toggleFlash();
                        setState(() {
                          flashOn = !flashOn;
                        });
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          height: 1,
          color: Colors.transparent,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Hapus observer lifecycle aplikasi
    WidgetsBinding.instance.removeObserver(this);

    // Hapus kamera secara bersih
    qrViewController?.dispose();

    // Hapus controller lama jika ada
    disposeController(controller);

    // Hapus timer
    debounceTimer?.cancel();

    super.dispose();
  }

  void showNotice(String message,
      {bool isError = false, bool isWarning = false, bool isSuccess = false}) {
    // Skip notifikasi jika bukan error, bukan warning, atau isSuccess=true
    if (!isError && !isWarning && isSuccess) {
      return;
    }

    // Hanya tampilkan notifikasi penting (pemrosesan QR dan asset code) dan errors
    // Skip notifikasi jika bukan error dan bukan informasi penting tentang QR code
    if (!isError &&
        !isWarning &&
        !message.contains("QR") &&
        !message.contains("aset")) {
      return;
    }

    Color backgroundColor = Colors.blue; // Default blue

    if (isError) {
      backgroundColor = Colors.red;
      // Tambahkan informasi lebih detail untuk pesan error format QR
      if (message.contains('Format kode QR tidak valid')) {
        message =
            'Format kode QR tidak valid. Gunakan format ASSET-XXX, MED-XXX, NMED-XXX, atau ANMD-XXX.';
      }
      // Tambahkan informasi lebih detail untuk error aset tidak ditemukan
      else if (message.contains('Aset tidak ditemukan')) {
        message =
            'Aset tidak ditemukan. Pastikan QR code terdaftar dalam sistem.';
      }
    } else if (isWarning) {
      backgroundColor = Colors.orange;
    }

    if (mounted) {
      // Tutup snackbar sebelumnya jika ada
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Tampilkan snackbar baru hanya untuk pesan penting
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.1,
            left: 20,
            right: 20,
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
  }

  Future<void> _processScannedQR(
      String qrCode, SocketService socketService) async {
    // Jika sedang memproses, batalkan
    if (isProcessing) return;

    // Set state processing untuk mencegah multiple scans
    setState(() {
      isProcessing = true;
    });

    try {
      // Pause kamera saat memproses untuk menghemat baterai
      if (qrViewController != null) {
        qrViewController!.pauseCamera();
        isPaused = true;
      }

      // Ekstrak ID aset dari QR code
      final assetCode = qrCode.trim();

      // Log QR yang dipindai untuk debugging
      print('[DEBUG] QR Code dipindai: $assetCode');

      // Tampilkan notifikasi untuk membantu debugging
      showNotice(
          "QR: ${assetCode.substring(0, assetCode.length > 15 ? 15 : assetCode.length)}...",
          isSuccess: true);

      // Kirim ke server melalui WebSocket jika berbeda dari scan terakhir
      if (assetCode != lastScannedCode) {
        socketService.sendMessage(assetCode, context);
        lastScannedCode = assetCode;
      }

      // Helper method untuk mengaktifkan kamera kembali dan reset state
      void resetCameraAndState() {
        if (qrViewController != null && isPaused) {
          qrViewController!.resumeCamera();
          isPaused = false;
        }
        setState(() {
          isProcessing = false;
          scannedCode = null; // Reset kode QR yang ditampilkan setelah error
          lastScannedCode =
              null; // Reset lastScannedCode agar bisa memindai kode yang sama lagi
        });
      }

      // Cek apakah QR code sesuai dengan format ANMD-YYMMDD-XXXX
      bool isValidFormat = assetCode.startsWith('ANMD-') ||
          RegExp(r'^\d+$').hasMatch(assetCode) ||
          assetCode.startsWith('NMED-') ||
          assetCode.startsWith('MED-') ||
          assetCode.startsWith('ASSET-');

      if (!isValidFormat) {
        print('[DEBUG] Format QR tidak valid: $assetCode');
        print(
            '[DEBUG] Format yang diterima: ANMD-*, NMED-*, MED-*, ASSET-*, atau angka');
        if (mounted) {
          showNotice(
              'Format kode QR tidak valid. Gunakan QR code aset yang benar.',
              isWarning: true);
          // Aktifkan kamera segera
          resetCameraAndState();
        }
        return;
      }

      // Mencoba mendapatkan aset dengan endpoint yang benar sesuai dokumentasi API
      try {
        // Langsung menggunakan endpoint /assets/qr/{assetCode}
        var endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';
        print(
            '[DEBUG] Mencoba endpoint: $endpoint dengan assetCode: $assetCode');

        var response = await auth.ApiService.get(endpoint, context: context);
        print('[DEBUG] Status response: ${response.statusCode}');

        // Tampilkan respons untuk debugging
        print('[DEBUG] Response body: ${response.body}');

        // Jika endpoint pertama berhasil, proses responsnya
        if (response.statusCode == 200) {
          _processSuccessResponse(response, assetCode);
          return;
        }

        // Jika kode dimulai dengan ASSET-, coba dengan /assets/qr/{assetCode}
        if (assetCode.startsWith('ASSET-')) {
          endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';
          print('[DEBUG] Mencoba endpoint alternatif untuk ASSET-: $endpoint');

          response = await auth.ApiService.get(endpoint, context: context);
          print('[DEBUG] Status response alternatif: ${response.statusCode}');
          print('[DEBUG] Response body alternatif: ${response.body}');

          if (response.statusCode == 200) {
            _processSuccessResponse(response, assetCode);
            return;
          }
        }

        // Jika gagal, coba endpoint alternatif
        var assetId = '';
        // Jika QR code adalah angka, mungkin itu ID aset
        if (RegExp(r'^\d+$').hasMatch(assetCode)) {
          assetId = assetCode;
          endpoint = '/assets/$assetId';
          print('[DEBUG] Mencoba endpoint dengan assetId: $endpoint');

          response = await auth.ApiService.get(endpoint, context: context);
          print('[DEBUG] Status response: ${response.statusCode}');

          if (response.statusCode == 200) {
            _processSuccessResponse(response, assetCode);
            return;
          }
        }

        // Jika masih gagal, coba endpoint pencarian
        endpoint = '/assets?search=${Uri.encodeComponent(assetCode)}';
        print('[DEBUG] Mencoba endpoint pencarian: $endpoint');

        response = await auth.ApiService.get(endpoint, context: context);
        print('[DEBUG] Status response pencarian: ${response.statusCode}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true &&
              responseData['data'] != null &&
              responseData['data'] is List &&
              responseData['data'].isNotEmpty) {
            // Jika pencarian mengembalikan hasil, proses hasil pertama
            print('[DEBUG] Hasil pencarian ditemukan!');
            _processSuccessResponse(response, assetCode);
            return;
          }
        }

        // Jika semua upaya gagal
        if (mounted) {
          if (response.statusCode == 403) {
            showNotice('Tidak memiliki izin akses', isError: true);
          } else if (response.statusCode == 404) {
            showNotice('Aset tidak ditemukan', isError: true);
          } else {
            showNotice('QR tidak terdaftar', isError: true);
          }
          resetCameraAndState();
        }
      } catch (e) {
        print('[DEBUG] Error saat mengambil data aset: $e');
        if (mounted) {
          showNotice(
              'Error: ${e is ApiException ? e.getUserFriendlyMessage() : "Gagal mendapatkan data aset"}',
              isError: true);
        }
        return;
      }
    } catch (e) {
      print('[DEBUG] Error keseluruhan: $e');
      if (mounted) {
        showNotice('Error: $e', isError: true);
      }
      return;
    }
  }

  // Helper method untuk memproses respons yang berhasil dan navigasi ke halaman detail
  void _processSuccessResponse(http.Response response, String assetCode) {
    if (!mounted) return;

    try {
      print('[DEBUG] Memproses respons sukses');
      final responseData = jsonDecode(response.body);
      print('[DEBUG] Respons data lengkap: $responseData');

      // Periksa struktur response: API baru menggunakan "success" bukan "status"
      final bool isSuccess = responseData['success'] == true;

      // Tambahkan pengecekan khusus untuk pesan "asset retrieved successfully"
      final message = responseData['message'] ?? '';
      final bool isSuccessMessage =
          message.toLowerCase().contains('asset retrieved successfully') ||
              message.toLowerCase().contains('aset berhasil diambil');

      if (isSuccessMessage) {
        print('[DEBUG] Terdeteksi pesan sukses: $message');
        showNotice("Aset ditemukan (pesan sukses)", isSuccess: true);

        // Periksa apakah ada data
        if (responseData['data'] == null) {
          print('[DEBUG] Data null meskipun pesan sukses');
          showNotice("Data null, mencoba alternatif", isWarning: true);

          // Coba ambil data dengan API call lain
          print('[DEBUG] Mencoba mendapatkan data dengan API call tambahan...');
          _getAssetByCode(assetCode);
          return;
        }
      }

      if (isSuccess && responseData['data'] != null) {
        var assetData = responseData['data'];
        print('[DEBUG] Tipe data aset: ${assetData.runtimeType}');
        print('[DEBUG] Struktur data aset lengkap: $assetData');

        // Jika data adalah List, periksa apakah list kosong
        if (assetData is List) {
          if (assetData.isEmpty) {
            print('[DEBUG] Data adalah List kosong');
            if (mounted) {
              showNotice('Tidak ada data aset yang ditemukan', isWarning: true);
            }
            return;
          } else {
            print('[DEBUG] Data adalah List, mengambil item pertama');
            assetData = assetData.first;
          }
        }

        // Memastikan field-field yang diperlukan ada
        if (assetData is Map<String, dynamic>) {
          // Buat salinan data yang dibersihkan berdasarkan format API baru
          final Map<String, dynamic> cleanAssetData = {
            'asset_id': assetData['asset_id'] ?? 0,
            'asset_code': assetData['asset_code'] ?? assetCode,
            'asset_name': assetData['asset_master']?['asset_name'] ??
                assetData['asset_master_name'] ??
                'Tidak diketahui',
            'current_status': assetData['current_status'] ?? 'available',
            'condition': assetData['condition'] ?? '-',
            'brand': {'brand_name': assetData['brand_name'] ?? '-'},
            'model_number':
                assetData['serial_number'] ?? assetData['model_number'] ?? '-',
            'warranty_end_date': assetData['warranty_end_date'] ?? '-',
            'subcategory': {
              'subcategory_name': assetData['asset_master']
                      ?['subcategory_name'] ??
                  assetData['subcategory_name'] ??
                  '-',
              'asset_type': assetData['asset_master']?['asset_type'] ??
                  assetData['asset_type'] ??
                  '-'
            },
            'room': {'room_name': assetData['room_name'] ?? '-'},
            'picture_path': assetData['qr_code'] ?? assetData['picture_path'],
          };

          // Tambahkan asset_master_id untuk mengambil data master aset
          if (assetData['asset_master_id'] != null) {
            cleanAssetData['asset_master_id'] = assetData['asset_master_id'];
          } else if (assetData['asset_master'] != null &&
              assetData['asset_master']['asset_master_id'] != null) {
            cleanAssetData['asset_master_id'] =
                assetData['asset_master']['asset_master_id'];
          }

          // Tambahkan data asset_master jika tersedia
          if (assetData['asset_master'] != null) {
            cleanAssetData['asset_master'] = assetData['asset_master'];
          }

          // Ganti assetData dengan versi yang telah dibersihkan
          assetData = cleanAssetData;
          print('[DEBUG] Data aset yang telah dibersihkan: $assetData');
        }

        bool isValidAssetData = assetData is Map<String, dynamic> &&
            assetData.containsKey('asset_id') &&
            assetData.containsKey('asset_code') &&
            assetData.containsKey('asset_name');

        if (isValidAssetData) {
          print(
              '[DEBUG] Data aset berhasil ditemukan dan valid! Data: $assetData');

          if (mounted) {
            print('[DEBUG] Mencoba navigasi ke halaman AssetDetails');

            // Tampilkan toast sukses hanya sekali
            showNotice('Aset ditemukan!', isSuccess: true);

            // Delay navigasi selama 500ms agar toast terlihat
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                print(
                    '[DEBUG] Navigasi ke AssetDetails dengan data: $assetData');

                // PENTING: Tambahkan ini untuk memastikan navigasi terjadi di main thread
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetails(
                          qrData: assetCode,
                          previousScreen: widget.previousScreen,
                          assetData: assetData,
                        ),
                      ),
                    );
                    print(
                        '[DEBUG] Navigator.pushReplacement berhasil dipanggil');
                  } catch (e) {
                    print('[DEBUG] Error navigasi: $e');
                    showNotice(
                        "Error navigasi: ${e.toString().substring(0, e.toString().length > 30 ? 30 : e.toString().length)}",
                        isError: true);
                    // Coba cara lain jika navigasi gagal
                    if (mounted) {
                      print(
                          '[DEBUG] Mencoba navigator.push sebagai alternatif');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AssetDetails(
                            qrData: assetCode,
                            previousScreen: widget.previousScreen,
                            assetData: assetData,
                          ),
                        ),
                      );
                    }
                  }
                });
              }
            });
          } else {
            print('[DEBUG] Widget tidak mounted saat memproses data');
          }
        } else {
          print('[DEBUG] Data aset tidak lengkap: $assetData');
          if (mounted) {
            showNotice('Data aset tidak lengkap atau tidak valid');
          }
        }
      } else {
        print('[DEBUG] API mengembalikan status false atau data null');

        // Periksa apakah pesan berisi "asset retrieved successfully"
        final message = responseData['message'] ?? 'Data aset tidak ditemukan';
        if (message.toLowerCase().contains('asset retrieved successfully') ||
            message.toLowerCase().contains('aset berhasil diambil')) {
          print(
              '[DEBUG] Pesan berisi "asset retrieved successfully" tapi data null');

          // Tambahkan penanganan khusus untuk kasus ini - coba ambil data dengan cara lain
          _getAssetByCode(assetCode);
          return;
        }

        // Tampilkan pesan dari API dalam bentuk toast
        if (mounted) {
          showNotice(message);
        }
      }
    } catch (e) {
      print('[DEBUG] Error memproses respons: $e');
      if (mounted) {
        showNotice('Error memproses data: $e', isError: true);
      }
    }
  }

  // Metode untuk mendapatkan aset berdasarkan kode setelah menerima "asset retrieved successfully"
  Future<void> _getAssetByCode(String assetCode) async {
    print('[DEBUG] Mencoba mendapatkan data aset dengan kode: $assetCode');
    showNotice("Mencoba cara alternatif untuk mendapatkan aset",
        isWarning: true);

    try {
      // Langsung gunakan endpoint yang benar sesuai dokumentasi API
      var endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';
      print('[DEBUG] _getAssetByCode: Mencoba endpoint: $endpoint');

      var response = await auth.ApiService.get(endpoint, context: context);
      print('[DEBUG] _getAssetByCode: Status response: ${response.statusCode}');
      print('[DEBUG] _getAssetByCode: Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Proses respons dan langsung navigasi ke halaman detail
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          var assetData = responseData['data'];

          print('[DEBUG] Berhasil mendapatkan data dari endpoint alternatif');
          print('[DEBUG] Data: $assetData');
          showNotice("Data aset berhasil didapatkan! Menuju halaman detail...",
              isSuccess: true);

          // Lakukan navigasi langsung ke halaman detail
          if (mounted) {
            _processSuccessResponse(response, assetCode);
          }
          return;
        } else {
          print('[DEBUG] Endpoint alternatif berhasil tapi tidak ada data');
        }
      }

      // Jika kode dimulai dengan ASSET-, coba dengan endpoint /assets/qr/{assetCode}
      if (assetCode.startsWith('ASSET-')) {
        endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';
        print(
            '[DEBUG] _getAssetByCode: Mencoba endpoint spesifik untuk ASSET-: $endpoint');

        response = await auth.ApiService.get(endpoint, context: context);
        print(
            '[DEBUG] _getAssetByCode: Status response ASSET-: ${response.statusCode}');
        print(
            '[DEBUG] _getAssetByCode: Response body ASSET-: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            print(
                '[DEBUG] Berhasil mendapatkan data ASSET- dari endpoint spesifik');
            _processSuccessResponse(response, assetCode);
            return;
          }
        }
      }

      // Coba pendekatan terakhir - pencarian
      final searchEndpoint = '/assets?search=${Uri.encodeComponent(assetCode)}';
      print(
          '[DEBUG] _getAssetByCode: Mencoba endpoint pencarian: $searchEndpoint');

      final searchResponse =
          await auth.ApiService.get(searchEndpoint, context: context);
      print(
          '[DEBUG] _getAssetByCode: Status response pencarian: ${searchResponse.statusCode}');
      print(
          '[DEBUG] _getAssetByCode: Response body pencarian: ${searchResponse.body}');

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        if (searchData['success'] == true &&
            searchData['data'] != null &&
            searchData['data'] is List &&
            searchData['data'].isNotEmpty) {
          print('[DEBUG] Berhasil mendapatkan data dari endpoint pencarian');
          _processSuccessResponse(searchResponse, assetCode);
          return;
        }
      }

      print('[DEBUG] Semua endpoint alternatif gagal');
      if (mounted) {
        showNotice('Aset ditemukan tapi detail tidak dapat diambil',
            isWarning: true);
      }
    } catch (e) {
      print('[DEBUG] Error pada _getAssetByCode: $e');
      if (mounted) {
        showNotice('Error: $e', isError: true);
      }
    }
  }

  // Fungsi helper untuk menampilkan toast
  void showToast(BuildContext context, String message,
      {Color backgroundColor = Colors.red, VoidCallback? onShown}) {
    // Skip notifikasi sukses (hijau)
    if (backgroundColor == Colors.green) {
      // Langsung jalankan callback tanpa menampilkan toast
      onShown?.call();
      return;
    }

    // Hanya tampilkan notifikasi penting dan errors
    if (backgroundColor != Colors.red &&
        !message.contains("QR") &&
        !message.contains("aset")) {
      // Langsung jalankan callback tanpa menampilkan toast
      onShown?.call();
      return;
    }

    // Tutup snackbar sebelumnya jika ada
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Tampilkan snackbar baru
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 20,
          right: 20,
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

    // Panggil callback jika disediakan
    onShown?.call();
  }
}
