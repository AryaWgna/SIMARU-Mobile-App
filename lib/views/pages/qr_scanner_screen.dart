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
      this.qrViewController = controller;
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
                    child: Text(
                      'Data: $scannedCode',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontFamily: 'Inter',
                      ),
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
          "QR: " +
              assetCode.substring(
                  0, assetCode.length > 15 ? 15 : assetCode.length) +
              "...",
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
          assetCode.startsWith('MED-');

      if (!isValidFormat) {
        print('[DEBUG] Format QR tidak valid: $assetCode');
        if (mounted) {
          showNotice(
              'Format kode QR tidak valid. Gunakan QR code aset yang benar.',
              isWarning: true);
          // Aktifkan kamera segera
          resetCameraAndState();
        }
        return;
      }

      // Ekstrak ID dari kode QR dengan pendekatan yang lebih fleksibel
      String assetId;

      // Cek apakah QR code sesuai dengan format baru NMED-ITEQ-250422-0002-01 atau MED-MEEQ-250422-0002-01
      if ((assetCode.startsWith('NMED-') || assetCode.startsWith('MED-')) &&
          assetCode.contains('-')) {
        final parts = assetCode.split('-');
        print('[DEBUG] QR format baru dipecah menjadi: $parts');

        // Format baru: NMED-ITEQ-250422-0002-01 atau MED-MEEQ-250422-0002-01
        if (parts.length >= 5) {
          // Gunakan seluruh kode QR untuk format baru
          assetId = assetCode;
          print('[DEBUG] Format baru - menggunakan kode QR lengkap: $assetId');
        } else {
          // Format tidak sesuai, gunakan seluruh kode QR
          assetId = assetCode;
          print(
              '[DEBUG] Format baru tidak standar, gunakan QR lengkap: $assetId');
        }
      }
      // Cek apakah QR code sesuai dengan format ANMD-YYMMDD-XXXX (format lama)
      else if (assetCode.startsWith('ANMD-') && assetCode.contains('-')) {
        final parts = assetCode.split('-');
        print('[DEBUG] QR dipecah menjadi: $parts');

        // Format diketahui dari tabel: ANMD-250324-0001, ANMD-250324-0002, ANMD-250324-0003
        if (parts.length == 3) {
          // Ambil bagian terakhir (0001, 0002, dll) dan hapus leading zeros
          var numericId = parts[2].replaceAll(RegExp(r'^0+(?=\d)'), '');
          if (numericId.isEmpty) numericId = '0';
          assetId = numericId;
          print('[DEBUG] ID diekstrak dari ANMD-YYMMDD-XXXX: $assetId');
        } else {
          // Format tidak sesuai, gunakan seluruh kode QR
          assetId = assetCode;
          print(
              '[DEBUG] Format ANMD- tidak standar, gunakan QR lengkap: $assetId');
        }
      } else if (RegExp(r'^\d+$').hasMatch(assetCode)) {
        // Jika QR code hanya berisi angka, gunakan langsung sebagai ID
        assetId = assetCode;
        print('[DEBUG] QR adalah ID numerik: $assetId');
      } else {
        // Format lain, gunakan QR code lengkap
        assetId = assetCode;
        print('[DEBUG] Format QR tidak dikenali, gunakan QR lengkap: $assetId');
      }

      // Mencoba mendapatkan aset dengan endpoint yang benar
      try {
        // Cek apakah format baru (NMED-ITEQ-... atau MED-MEEQ-...)
        bool isNewFormat =
            (assetCode.startsWith('NMED-') || assetCode.startsWith('MED-'));

        // Pendekatan untuk format QR baru
        if (isNewFormat) {
          print('[DEBUG] Menggunakan pendekatan khusus untuk format QR baru');

          // Gunakan endpoint by-asset-code sebagai pendekatan pertama untuk format baru
          var endpoint = '/assets/code/' + Uri.encodeComponent(assetCode);
          print(
              '[DEBUG] PENDEKATAN KHUSUS: Mencoba endpoint by-asset-code: $endpoint');

          var response = await auth.ApiService.get(endpoint, context: context);
          print(
              '[DEBUG] PENDEKATAN KHUSUS: Status response: ${response.statusCode}');

          // Jika salah satu endpoint khusus berhasil, proses responsnya
          if (response.statusCode == 200) {
            // Process response dan navigate ke halaman detail
            print('[DEBUG] Pendekatan khusus format baru berhasil!');
            _processSuccessResponse(response, assetCode);
            return;
          }
        }

        // Pendekatan utama: Cari berdasarkan ID aset dari tabel
        var endpoint = '/assets/' + assetId;
        print(
            '[DEBUG] PENDEKATAN 1: Mencoba endpoint: $endpoint dengan assetId: $assetId');

        var response = await auth.ApiService.get(endpoint, context: context);
        print('[DEBUG] PENDEKATAN 1: Status response: ${response.statusCode}');

        // Jika gagal dengan pendekatan ID, coba dengan pendekatan asset_code
        if (response.statusCode != 200) {
          print(
              '[DEBUG] PENDEKATAN 1 gagal, mencoba PENDEKATAN 2 dengan asset_code');

          // Pendekatan 2: Cari berdasarkan asset_code di tabel
          endpoint = '/assets/code/' + Uri.encodeComponent(assetCode);
          print(
              '[DEBUG] PENDEKATAN 2: Mencoba endpoint: $endpoint dengan asset_code: $assetCode');

          response = await auth.ApiService.get(endpoint, context: context);
          print(
              '[DEBUG] PENDEKATAN 2: Status response: ${response.statusCode}');

          // Jika gagal lagi, coba dengan parameter query
          if (response.statusCode != 200) {
            print(
                '[DEBUG] PENDEKATAN 2 gagal, mencoba PENDEKATAN 3 dengan parameter query');

            // Pendekatan 3: Gunakan parameter query
            endpoint = '/assets?code=' + Uri.encodeComponent(assetCode);
            print('[DEBUG] PENDEKATAN 3: Mencoba endpoint: $endpoint');

            response = await auth.ApiService.get(endpoint, context: context);
            print(
                '[DEBUG] PENDEKATAN 3: Status response: ${response.statusCode}');

            // Jika pendekatan 3 gagal, coba dengan pendekatan kode aset lengkap
            if (response.statusCode != 200) {
              print(
                  '[DEBUG] PENDEKATAN 3 gagal, mencoba PENDEKATAN 4 dengan kode QR lengkap');

              // Pendekatan 4: Coba gunakan kode QR lengkap untuk pencarian
              var fullQRCode = assetCode;
              endpoint = '/assets/full-code/${Uri.encodeComponent(fullQRCode)}';
              print(
                  '[DEBUG] PENDEKATAN 4: Mencoba endpoint: $endpoint dengan fullQRCode: $fullQRCode');

              response = await auth.ApiService.get(endpoint, context: context);
              print(
                  '[DEBUG] PENDEKATAN 4: Status response: ${response.statusCode}');
            }
          }
        }

        if (response.statusCode == 200) {
          print(
              '[DEBUG] Response berhasil diterima, menggunakan _processSuccessResponse');
          _processSuccessResponse(response, assetCode);
          return;
        } else if (response.statusCode == 403) {
          print(
              '[DEBUG] Error 403: Tidak memiliki izin untuk mengakses aset ini');
          if (mounted) {
            showNotice('Tidak memiliki izin akses', isError: true);
          }
          resetCameraAndState();
          return;
        } else if (response.statusCode == 404) {
          print('[DEBUG] Error 404: Asset tidak ditemukan');
          if (mounted) {
            showNotice('Aset tidak ditemukan', isError: true);
          }
          resetCameraAndState();
          return;
        } else {
          print('[DEBUG] Error tidak dikenal: ${response.statusCode}');

          // Periksa response body jika ada pesan "asset retrieved successfully"
          try {
            final responseData = jsonDecode(response.body);
            final message = responseData['message'] ?? '';

            if (message
                .toLowerCase()
                .contains('asset retrieved successfully')) {
              print(
                  '[DEBUG] Terdeteksi "asset retrieved successfully" pada status code non-200');
              // Panggil metode untuk mendapatkan aset berdasarkan kode setelah menerima pesan sukses
              _getAssetByCode(assetCode);
              return;
            }
          } catch (e) {
            print('[DEBUG] Error saat mencoba parse response body: $e');
          }

          if (mounted) {
            showNotice('QR tidak terdaftar', isError: true);
          }
          resetCameraAndState();
          return;
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
      final bool isSuccess =
          responseData['success'] == true || responseData['status'] == true;

      // Tambahkan pengecekan khusus untuk pesan "asset retrieved successfully"
      final message = responseData['message'] ?? '';
      final bool isSuccessMessage =
          message.toLowerCase().contains('asset retrieved successfully');

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
            'picture_path': assetData['qr_code'] ?? assetData['picture_path']
          };

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
                        "Error navigasi: " +
                            e.toString().substring(
                                0,
                                e.toString().length > 30
                                    ? 30
                                    : e.toString().length),
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
        if (message.toLowerCase().contains('asset retrieved successfully')) {
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
      // Coba pendekatan menggunakan ID dari QR code NMED-ITEQ-250422-0002-03
      String extractedId = "";
      if (assetCode.contains("-")) {
        final parts = assetCode.split('-');
        if (parts.length >= 5) {
          extractedId = parts[parts.length - 1]
              .replaceFirst(RegExp(r'^0+'), ''); // Hapus leading zeros
          if (extractedId.isEmpty)
            extractedId =
                parts[parts.length - 1]; // Jika hanya nol, gunakan aslinya
          print('[DEBUG] Extracted ID from format baru: $extractedId');
        }
      }

      // Jika berhasil ekstrak ID, coba dengan ID tersebut
      if (extractedId.isNotEmpty) {
        final endpoint = '/assets/' + extractedId;
        print('[DEBUG] _getAssetByCode: Mencoba endpoint dengan ID: $endpoint');

        final response = await auth.ApiService.get(endpoint, context: context);
        print(
            '[DEBUG] _getAssetByCode dengan ID: Status response: ${response.statusCode}');

        if (response.statusCode == 200) {
          // Berhasil dengan ID yang diekstrak
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            print(
                '[DEBUG] Berhasil mendapatkan data dengan ID yang diekstrak dari QR code');
            showNotice("Data aset berhasil ditemukan!", isSuccess: true);
            _processSuccessResponse(response, assetCode);
            return;
          }
        }
      }

      // Pendekatan menggunakan kode aset lengkap
      final endpoint = '/assets/code/' + Uri.encodeComponent(assetCode);
      print('[DEBUG] _getAssetByCode: Mencoba endpoint: $endpoint');

      final response = await auth.ApiService.get(endpoint, context: context);
      print('[DEBUG] _getAssetByCode: Status response: ${response.statusCode}');

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
          if (mounted) {
            showNotice('Data aset sukses ditemukan tapi tidak lengkap',
                isWarning: true);
          }
        }
      } else {
        // Coba pendekatan terakhir - pencarian
        final searchEndpoint =
            '/assets/search?q=' + Uri.encodeComponent(assetCode);
        print(
            '[DEBUG] _getAssetByCode: Mencoba endpoint pencarian: $searchEndpoint');

        final searchResponse =
            await auth.ApiService.get(searchEndpoint, context: context);
        if (searchResponse.statusCode == 200) {
          final searchData = jsonDecode(searchResponse.body);
          if (searchData['success'] == true && searchData['data'] != null) {
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
