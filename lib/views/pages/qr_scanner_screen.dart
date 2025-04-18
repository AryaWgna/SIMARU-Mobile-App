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
import '../../core/config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../controllers/auth_controller.dart' as auth;

// Impor QR code scanner dengan conditional import
import 'qr_mobile_implementation.dart'
    if (dart.library.html) 'qr_web_implementation.dart';

// Widget toast sederhana
class ToastOverlay extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final VoidCallback? onShown; // Callback saat toast ditampilkan

  const ToastOverlay({
    Key? key,
    required this.message,
    this.backgroundColor = Colors.red,
    this.onShown,
  }) : super(key: key);

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Play fadeIn animation and then automatically dismiss after delay
    _controller.forward().then((_) {
      // Callback ketika toast sudah sepenuhnya muncul
      widget.onShown?.call();
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Fungsi helper untuk menampilkan toast
void showToast(BuildContext context, String message,
    {Color backgroundColor = Colors.red, VoidCallback? onShown}) {
  // Tampilkan overlay toast yang menutup sendiri
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => ToastOverlay(
        message: message,
        backgroundColor: backgroundColor,
        onShown: onShown,
      ),
    ),
  );
}

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

  // Mendapatkan token akses dari secure storage
  Future<String?> _getAccessToken() async {
    try {
      return await _storage.read(key: 'accessToken');
    } catch (e) {
      print('Error getting access token: $e');
      return null;
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

      // Kirim ke server melalui WebSocket jika berbeda dari scan terakhir
      if (assetCode != lastScannedCode) {
        socketService.sendMessage(assetCode, context);
        lastScannedCode = assetCode;
      }

      // Helper function untuk mengaktifkan kamera kembali secara langsung
      void resumeCameraImmediately() {
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
      bool isValidFormat =
          assetCode.startsWith('ANMD-') || RegExp(r'^\d+$').hasMatch(assetCode);

      if (!isValidFormat) {
        print('[DEBUG] Format QR tidak valid: $assetCode');
        if (mounted) {
          showToast(context,
              'Format kode QR tidak valid. Gunakan QR code aset yang benar.',
              onShown: resumeCameraImmediately); // Aktifkan kamera segera
        }
        return;
      }

      // Ekstrak ID dari kode QR dengan pendekatan yang lebih fleksibel
      String assetId;

      // Cek apakah QR code sesuai dengan format ANMD-YYMMDD-XXXX
      if (assetCode.startsWith('ANMD-') && assetCode.contains('-')) {
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
        // Pendekatan utama: Cari berdasarkan ID aset dari tabel
        var endpoint = '/assets/${assetId}';
        print(
            '[DEBUG] PENDEKATAN 1: Mencoba endpoint: $endpoint dengan assetId: $assetId');

        var response = await auth.ApiService.get(endpoint, context: context);
        print('[DEBUG] PENDEKATAN 1: Status response: ${response.statusCode}');

        // Jika gagal dengan pendekatan ID, coba dengan pendekatan asset_code
        if (response.statusCode != 200) {
          print(
              '[DEBUG] PENDEKATAN 1 gagal, mencoba PENDEKATAN 2 dengan asset_code');

          // Pendekatan 2: Cari berdasarkan asset_code di tabel
          endpoint = '/assets/by-code/${Uri.encodeComponent(assetCode)}';
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
            endpoint = '/assets?qr_code=${Uri.encodeComponent(assetCode)}';
            print('[DEBUG] PENDEKATAN 3: Mencoba endpoint: $endpoint');

            response = await auth.ApiService.get(endpoint, context: context);
            print(
                '[DEBUG] PENDEKATAN 3: Status response: ${response.statusCode}');
          }
        }

        if (response.statusCode == 200) {
          print('[DEBUG] Response berhasil diterima');
          final responseData = jsonDecode(response.body);
          print('[DEBUG] Response data: $responseData');

          // Cek tipe data respons untuk menghindari error tipe
          if (responseData['status'] == true && responseData['data'] != null) {
            var assetData = responseData['data'];
            print('[DEBUG] Tipe data aset: ${assetData.runtimeType}');

            // Jika data adalah List, periksa apakah list kosong
            if (assetData is List) {
              if (assetData.isEmpty) {
                print('[DEBUG] Data adalah List kosong');
                if (mounted) {
                  showToast(context, 'Tidak ada data aset yang ditemukan',
                      onShown: resumeCameraImmediately);
                }
                return;
              } else {
                print('[DEBUG] Data adalah List, mengambil item pertama');
                assetData = assetData.first;
              }
            }

            // Periksa apakah data valid dan memiliki semua field yang diperlukan
            bool isValidAssetData = assetData is Map<String, dynamic> &&
                assetData.containsKey('asset_id') &&
                assetData.containsKey('asset_code') &&
                assetData.containsKey('asset_name');

            if (isValidAssetData) {
              print(
                  '[DEBUG] Data aset berhasil ditemukan dan valid! Data: $assetData');

              // Navigasi ke halaman detail aset dengan data aset dari API
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssetDetails(
                      qrData: assetCode,
                      previousScreen: widget.previousScreen,
                      assetData: assetData, // Kirim data aset ke halaman detail
                    ),
                  ),
                );
              }
            } else {
              print('[DEBUG] Data aset tidak lengkap: $assetData');
              if (mounted) {
                showToast(context, 'Data aset tidak lengkap atau tidak valid',
                    onShown: resumeCameraImmediately);
              }
              return;
            }
          } else {
            print('[DEBUG] API mengembalikan status false atau data null');
            // Tampilkan pesan dari API dalam bentuk toast
            final message =
                responseData['message'] ?? 'Data aset tidak ditemukan';
            if (mounted) {
              showToast(context, message, onShown: resumeCameraImmediately);
            }
            return;
          }
        } else if (response.statusCode == 403) {
          print(
              '[DEBUG] Error 403: Tidak memiliki izin untuk mengakses aset ini');
          if (mounted) {
            showToast(
                context, 'Anda tidak memiliki izin untuk mengakses aset ini',
                onShown: resumeCameraImmediately);
          }
          return;
        } else if (response.statusCode == 404) {
          print('[DEBUG] Error 404: Asset tidak ditemukan');
          if (mounted) {
            showToast(context,
                'Aset tidak ditemukan. Pastikan QR code yang dipindai valid.',
                onShown: resumeCameraImmediately);
          }
          return;
        } else {
          print('[DEBUG] Error tidak dikenal: ${response.statusCode}');
          if (mounted) {
            showToast(
                context, 'Gagal mendapatkan data aset: ${response.statusCode}',
                onShown: resumeCameraImmediately);
          }
          return;
        }
      } catch (e) {
        print('[DEBUG] Error saat mengambil data aset: $e');
        if (mounted) {
          showToast(context,
              'Error: ${e is ApiException ? e.getUserFriendlyMessage() : "Gagal mendapatkan data aset"}',
              onShown: resumeCameraImmediately);
        }
        return;
      }
    } catch (e) {
      print('[DEBUG] Error keseluruhan: $e');
      if (mounted) {
        showToast(context, 'Error: $e', onShown: () {
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
        });
      }
      return;
    }
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
}
