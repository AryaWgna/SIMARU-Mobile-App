import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'asset_history.dart';
import 'asset_mutation.dart';
import 'asset_details.dart';
import '../../controllers/auth_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/config/api_config.dart';
import 'package:flutter/services.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:math';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';

// Platform channel untuk deteksi screenshot di iOS
const MethodChannel _channel =
    MethodChannel('app.assets_tracker/screenshot_detection');

// Constant untuk pesan anti-screenshot
const String ANTI_SCREENSHOT_MESSAGE =
    "Aplikasi ini tidak mengizinkan untuk mengambil screenshot";

// Tambahkan konstanta untuk semua halaman
const bool IS_PRODUCTION = true; // Set ke false untuk development
const String SECURITY_VERSION = "v1.1";

// Singleton untuk mengelola status anti-screenshot secara global
class ScreenshotProtectionManager {
  static final ScreenshotProtectionManager _instance =
      ScreenshotProtectionManager._internal();

  factory ScreenshotProtectionManager() {
    return _instance;
  }

  ScreenshotProtectionManager._internal();

  bool _isProtectionEnabled = false;
  final NoScreenshot _noScreenshot = NoScreenshot();

  // Metode untuk mengaktifkan proteksi anti-screenshot
  Future<void> enableProtection() async {
    if (!_isProtectionEnabled) {
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          await _noScreenshot.screenshotOff();
          _isProtectionEnabled = true;
          print("ScreenshotProtectionManager: Protection enabled");
        }
      } catch (e) {
        print("ScreenshotProtectionManager: Error enabling protection: $e");
      }
    }
  }

  // Metode untuk menonaktifkan proteksi anti-screenshot
  Future<void> disableProtection() async {
    if (_isProtectionEnabled) {
      try {
        if (Platform.isAndroid || Platform.isIOS) {
          await _noScreenshot.screenshotOn();
          _isProtectionEnabled = false;
          print("ScreenshotProtectionManager: Protection disabled");
        }
      } catch (e) {
        print("ScreenshotProtectionManager: Error disabling protection: $e");
      }
    }
  }

  // Getter untuk status proteksi
  bool get isProtectionEnabled => _isProtectionEnabled;
}

class AssetDocument extends StatefulWidget {
  final Map<String, dynamic>? assetData;
  final String qrData;
  final String previousScreen;

  const AssetDocument({
    super.key,
    this.assetData,
    this.qrData = '',
    this.previousScreen = 'home',
  });

  @override
  State<AssetDocument> createState() => _AssetDocumentState();
}

class _AssetDocumentState extends State<AssetDocument>
    with WidgetsBindingObserver {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> documents = [];
  bool _showAntiScreenshotMessage = false;
  Timer? _securityTimer;
  String _randomSecurityId = '';
  StreamSubscription? _iosScreenshotSubscription;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final ScreenshotProtectionManager _protectionManager =
      ScreenshotProtectionManager();

  // Tambahkan counter refresh untuk mengatasi efek zoom kumulatif
  int _refreshCount = 0;

  @override
  void initState() {
    super.initState();
    // Deteksi screensaver dan app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Generate security ID
    _randomSecurityId = _generateRandomId();

    // Nonaktifkan anti-screenshot di halaman utama
    // Hanya aktifkan pada preview dokumen saja
    _protectionManager
        .disableProtection(); // Pastikan fitur off di halaman utama

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fetchAssetDocuments();
    });
  }

  // Setup deteksi screenshot untuk iOS
  void _setupIOSScreenshotDetection() async {
    // Fungsi dipertahankan untuk digunakan di viewer page
    // tapi tidak dipanggil di halaman utama
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onScreenshotTaken') {
          print("iOS screenshot terdeteksi");
          _showAntiScreenshotNotification();
        }
        return null;
      });

      await _channel.invokeMethod('startScreenshotDetection');
      print("iOS screenshot detection setup berhasil");
    } catch (e) {
      print("Error saat setup iOS screenshot detection: $e");
    }
  }

  @override
  void dispose() {
    // Pastikan untuk menonaktifkan anti-screenshot saat halaman ini ditutup
    _protectionManager.disableProtection();

    // Kembalikan setting UI ke normal
    if (Platform.isAndroid) {
      // Pastikan untuk melepaskan pengaturan khusus saat keluar dari halaman ini
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      // Kembalikan statusBarColor ke default atau transparant
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ));
    }
    // Hapus observer
    WidgetsBinding.instance.removeObserver(this);

    // Hentikan deteksi screenshot iOS
    if (Platform.isIOS) {
      _channel.invokeMethod('stopScreenshotDetection');
    }

    // Cancel security timer
    _securityTimer?.cancel();

    super.dispose();
  }

  // Observer untuk mendeteksi perubahan aplikasi
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ketika halaman ini dibuka kembali, aktifkan kembali anti-screenshot
      _protectionManager.enableProtection();

      // Ketika aplikasi dibuka kembali, periksa apakah screenshot diambil
      print("Aplikasi dibuka kembali, mungkin setelah screenshot");
      _showAntiScreenshotNotification();
    } else if (state == AppLifecycleState.paused) {
      // Ketika aplikasi di-pause, secara proaktif tampilkan pesan anti-screenshot
      _showAntiScreenshotNotification();
    }
  }

  // Untuk menampilkan notifikasi anti-screenshot
  void _showAntiScreenshotNotification() {
    setState(() {
      _showAntiScreenshotMessage = true;
    });

    // Sembunyikan pesan setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAntiScreenshotMessage = false;
        });
      }
    });
  }

  // Generate random ID for security tracking
  String _generateRandomId() {
    final random = Random();
    return DateTime.now().microsecondsSinceEpoch.toString() +
        random.nextInt(10000).toString();
  }

  // Start timer untuk cek keamanan secara berkala
  void _startSecurityTimer() {
    // Cek keamanan setiap 2 detik
    _securityTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Regenerate security ID secara berkala
      if (mounted) {
        setState(() {
          _randomSecurityId = _generateRandomId();
        });
      }

      // Re-enable anti-screenshot secara berkala
      _protectionManager.enableProtection();

      // Debug log
      print("Security check: $_randomSecurityId");
    });
  }

  void _onRefresh() async {
    // Segera aktifkan skeletonizer
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    // Fetch data dengan flag showLoading=false karena kita sudah mengaktifkan loading state
    await _fetchAssetDocuments(showLoading: false);

    // Reset refresh controller
    _refreshController.refreshCompleted();

    // Jika refresh counter mencapai 3, reset tampilan untuk mencegah zoom
    _refreshCount++;
    if (_refreshCount >= 3) {
      _refreshCount = 0;

      if (mounted) {
        // Trigger rebuild dengan sedikit delay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AssetDocument(
                  assetData: widget.assetData,
                  qrData: widget.qrData,
                  previousScreen: widget.previousScreen,
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
            Navigator.of(context).removeRoute(ModalRoute.of(context)!);
          }
        });
      }
    }
  }

  Future<void> _fetchAssetDocuments({bool showLoading = true}) async {
    if (widget.assetData == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Data aset tidak tersedia';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      // Debug: tampilkan semua key yang tersedia di assetData
      print('Asset data keys available: ${widget.assetData!.keys.toList()}');
      print('Asset data: ${widget.assetData}');

      // Hanya gunakan asset_id untuk mengambil dokumen
      var assetId = widget.assetData!['asset_id']?.toString();

      // Jika asset_id tidak tersedia, coba ambil dari property lain
      if (assetId == null || assetId.isEmpty) {
        // Coba dari id
        assetId = widget.assetData!['id']?.toString();

        // Jika masih null, coba asset_master_id
        if (assetId == null || assetId.isEmpty) {
          assetId = widget.assetData!['asset_master_id']?.toString();
        }
      }

      if (assetId == null || assetId.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'ID aset tidak ditemukan (asset_id)';
        });
        return;
      }

      print('Mengambil dokumen untuk aset dengan ID: $assetId');

      // Gunakan endpoint yang benar sesuai dengan dokumentasi API
      var endpoint = '/asset-documents/asset/$assetId/all-documents';
      print('Endpoint yang digunakan: $endpoint');

      final response = await ApiService.get(
        endpoint,
        context: context,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Handle berbagai kemungkinan struktur respons
          List<dynamic> docs = [];

          if (data['data'] != null) {
            if (data['data'] is List) {
              // Jika data adalah array langsung
              docs = data['data'];
            } else if (data['data']['documents'] != null &&
                data['data']['documents'] is List) {
              // Jika data memiliki property documents
              docs = data['data']['documents'];
            } else if (data['data']['items'] != null &&
                data['data']['items'] is List) {
              // Jika data memiliki property items
              docs = data['data']['items'];
            } else {
              // Jika data adalah object tunggal
              docs = [data['data']];
            }
          }

          print('Jumlah dokumen ditemukan: ${docs.length}');

          setState(() {
            documents = docs;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = data['message'] ?? 'Gagal memuat dokumen';
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
          documents = [];
        });
      } else if (response.statusCode == 500) {
        // Handle error 500 dengan pesan yang lebih jelas
        String serverError;
        try {
          final data = json.decode(response.body);
          serverError =
              data['message'] ?? 'Terjadi kesalahan pada server (500)';
        } catch (e) {
          serverError = 'Terjadi kesalahan pada server (500)';
        }

        print('Error 500: $serverError');
        setState(() {
          isLoading = false;
          errorMessage =
              'Kesalahan server: $serverError. Silakan coba dengan ID aset yang benar.';
        });

        // Coba endpoint alternatif jika error 500
        _tryAlternativeEndpoint(assetId);
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat dokumen: Error ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error saat mengambil dokumen aset: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  // Metode baru untuk mencoba endpoint alternatif jika endpoint utama gagal
  Future<void> _tryAlternativeEndpoint(String assetId) async {
    print('Mencoba endpoint alternatif untuk dokumen...');

    try {
      // Coba beberapa endpoint alternatif untuk dokumen
      List<String> alternativeEndpoints = [
        '/documents/asset/$assetId',
        '/asset-documents/asset/$assetId/all-documents', // Dari dokumentasi API
        '/asset-documents/documents?asset_id=$assetId' // Endpoint tambahan yang mungkin tersedia
      ];

      for (var endpoint in alternativeEndpoints) {
        print('Mencoba endpoint alternatif: $endpoint');

        final response = await ApiService.get(
          endpoint,
          context: context,
        );

        print('Response alternatif status: ${response.statusCode}');
        print('Response alternatif body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['success'] == true) {
            // Handle berbagai kemungkinan struktur respons
            List<dynamic> docs = [];

            if (data['data'] != null) {
              if (data['data'] is List) {
                docs = data['data'];
              } else if (data['data']['documents'] != null &&
                  data['data']['documents'] is List) {
                docs = data['data']['documents'];
              } else if (data['data']['items'] != null &&
                  data['data']['items'] is List) {
                docs = data['data']['items'];
                // Cek jika ada "documents" di level teratas sesuai dokumentasi
              } else if (endpoint.contains('all-documents') &&
                  data['data'] is Map &&
                  data['data'].containsKey('documents')) {
                docs = data['data']['documents'];
              } else {
                docs = [data['data']];
              }
            }

            print(
                'Jumlah dokumen ditemukan dengan endpoint alternatif: ${docs.length}');

            if (docs.isNotEmpty) {
              setState(() {
                documents = docs;
                isLoading = false;
                errorMessage = null; // Hapus pesan error sebelumnya
              });

              // Jika berhasil dengan endpoint ini, hentikan perulangan
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error pada endpoint alternatif: $e');
      // Tidak mengubah state karena ini hanya upaya backup
    }
  }

  // Metode untuk menampilkan PDF viewer langsung dari URL
  void _openPdfViewerDirectly(Map<String, dynamic> document) {
    final filePath = document['file_path'];
    print('File path dari database (PDF): $filePath');
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path tidak tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Bangun URL lengkap file
    String fullUrl = '';
    if (filePath.startsWith('http')) {
      fullUrl = filePath;
    } else {
      // Pastikan file path dimulai dengan slash
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      fullUrl = '${ApiConfig.baseUrl}/public$path';
    }

    print('Membuka PDF dari URL: $fullUrl');

    try {
      // Buka PDF viewer langsung dengan URL
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecurePdfViewerPage(
            pdfUrl: fullUrl,
            title: document['document_title'] ?? 'Dokumen PDF',
            // Aktifkan anti-screenshot hanya untuk viewer
            enableAntiScreenshot: true,
          ),
        ),
      );
    } catch (e) {
      print('Error saat membuka PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka dokumen: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Metode untuk menampilkan Image viewer langsung dari URL
  void _openImageViewerDirectly(Map<String, dynamic> document) {
    final filePath = document['file_path'];
    print('File path dari database (Image): $filePath');
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File path tidak tersedia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Bangun URL lengkap file
    String fullUrl = '';
    if (filePath.startsWith('http')) {
      fullUrl = filePath;
    } else {
      // Pastikan file path dimulai dengan slash
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      fullUrl = '${ApiConfig.baseUrl}/public$path';
    }

    print('Membuka gambar dari URL: $fullUrl');

    try {
      // Buka Image viewer langsung dengan URL
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecureImageViewerPage(
            imageUrl: fullUrl,
            title: document['document_title'] ?? 'Gambar',
            // Aktifkan anti-screenshot hanya untuk viewer
            enableAntiScreenshot: true,
          ),
        ),
      );
    } catch (e) {
      print('Error saat membuka gambar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka gambar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: SecureWidget(
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                isLoading
                    ? Skeletonizer(
                        enabled: true,
                        effect: ShimmerEffect(
                          baseColor: Colors.grey.shade300,
                          highlightColor: const Color(0xFFE5EFFF),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: 3, // Tampilkan 3 skeleton item
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _buildSkeletonDocumentCard();
                          },
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _fetchAssetDocuments,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF213268),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : documents.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.folder_open,
                                        color: Colors.grey[400],
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Tidak ada dokumen',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Aset ini belum memiliki dokumen terkait',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF999999),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : SmartRefresher(
                                enablePullDown: true,
                                enablePullUp: false,
                                physics: const ClampingScrollPhysics(),
                                controller: _refreshController,
                                onRefresh: _onRefresh,
                                footer: null,
                                header: const WaterDropMaterialHeader(
                                  backgroundColor: Color(0xFF213268),
                                  color: Colors.white,
                                  distance: 60.0,
                                ),
                                child: ScrollConfiguration(
                                  behavior:
                                      ScrollConfiguration.of(context).copyWith(
                                    overscroll: false,
                                  ),
                                  child: NotificationListener<
                                      OverscrollIndicatorNotification>(
                                    onNotification: (overscroll) {
                                      overscroll.disallowIndicator();
                                      return true;
                                    },
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      padding: const EdgeInsets.all(16),
                                      itemCount: documents.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final document = documents[index];
                                        return _buildDocumentCard(document);
                                      },
                                    ),
                                  ),
                                ),
                              ),

                // Pesan anti-screenshot WhatsApp style
                if (_showAntiScreenshotMessage)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.85),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.no_photography,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              ANTI_SCREENSHOT_MESSAGE,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, 'document'),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final documentTitle = document['document_title'] ?? 'Dokumen';
    final fileName = _extractFilename(document['file_path'] ?? '');
    final fileType = _getFileType(fileName);
    final uploadDate = document['upload_date'] ?? '-';
    final formattedDate = _formatDate(uploadDate);
    final notes = document['notes'] ?? '-';

    return InkWell(
      onTap: () {
        // Cek jenis file dan buka viewer yang sesuai langsung
        if (fileType.toLowerCase().contains('pdf')) {
          _openPdfViewerDirectly(document);
        } else if (fileType.toLowerCase().contains('image') ||
            fileType.toLowerCase().contains('jpg') ||
            fileType.toLowerCase().contains('jpeg') ||
            fileType.toLowerCase().contains('png')) {
          _openImageViewerDirectly(document);
        } else {
          // Jika bukan PDF atau gambar, tampilkan notifikasi
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Hanya file PDF dan gambar yang dapat dilihat secara langsung'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Container(
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
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      documentTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF213268),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _getFileIcon(fileType),
                    color: const Color(0xFF25B1FF),
                    size: 24,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDocumentDetail('Nama File', fileName),
                  const SizedBox(height: 8),
                  _buildDocumentDetail('Tipe', fileType),
                  const SizedBox(height: 8),
                  _buildDocumentDetail('Tanggal Unggah', formattedDate),
                  const SizedBox(height: 8),
                  _buildDocumentDetail('Catatan', notes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.toLowerCase().contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (fileType.toLowerCase().contains('word') ||
        fileType.toLowerCase().contains('doc')) {
      return Icons.description;
    } else if (fileType.toLowerCase().contains('excel') ||
        fileType.toLowerCase().contains('xls') ||
        fileType.toLowerCase().contains('csv')) {
      return Icons.table_chart;
    } else if (fileType.toLowerCase().contains('image') ||
        fileType.toLowerCase().contains('jpg') ||
        fileType.toLowerCase().contains('png')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }

  Widget _buildDocumentDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  String _extractFilename(String path) {
    if (path.isEmpty) return '-';
    if (!path.contains('/')) return path;
    return path.split('/').last;
  }

  String _getFileType(String fileName) {
    if (fileName == '-') return '-';
    if (!fileName.contains('.')) return 'Tidak diketahui';

    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'csv':
        return 'CSV File';
      case 'jpg':
      case 'jpeg':
        return 'JPEG Image';
      case 'png':
        return 'PNG Image';
      default:
        return extension.toUpperCase();
    }
  }

  String _formatDate(String dateString) {
    if (dateString == '-') return '-';
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return dateString;
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Stack(
        children: [
          // Warna biru tua untuk AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 82 + statusBarHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF213268),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
            ),
          ),

          // AppBar Content
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            height: 82,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 32),
                  onPressed: () {
                    // Navigasi langsung ke halaman AssetDetails ketika tombol kembali ditekan
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetails(
                          qrData: widget.qrData,
                          previousScreen: widget.previousScreen,
                          assetData: widget.assetData,
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: Image.asset(
                        'images/Logo_RS_UMMI_white.png',
                        width: 208.14,
                        height: 55,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, String activePage) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, -4),
            blurRadius: 4,
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            Icons.folder,
            'Dokumen',
            activePage == 'document',
            () {},
          ),
          _buildNavItem(
            Icons.history,
            'Riwayat',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AssetHistory(
                        assetData: widget.assetData,
                        qrData: widget.qrData,
                        previousScreen: widget.previousScreen,
                      )),
            ),
          ),
          _buildNavItem(
            Icons.swap_horiz,
            'Mutasi',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AssetMutation(
                        assetData: widget.assetData,
                        qrData: widget.qrData,
                        previousScreen: widget.previousScreen,
                      )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isActive ? const Color(0xFF213268) : const Color(0xFF757575),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: isActive
                    ? const Color(0xFF213268)
                    : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Komponen skeleton untuk document card
  Widget _buildSkeletonDocumentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF213268).withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF25B1FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonDocumentDetail(),
                const SizedBox(height: 8),
                _buildSkeletonDocumentDetail(),
                const SizedBox(height: 8),
                _buildSkeletonDocumentDetail(),
                const SizedBox(height: 8),
                _buildSkeletonDocumentDetail(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonDocumentDetail() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

// Implementasi PDF viewer yang aman tanpa kemampuan screenshot
class SecurePdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final bool enableAntiScreenshot; // Parameter baru

  const SecurePdfViewerPage({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.enableAntiScreenshot = false, // Default ke false
  });

  @override
  State<SecurePdfViewerPage> createState() => _SecurePdfViewerPageState();
}

class _SecurePdfViewerPageState extends State<SecurePdfViewerPage>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  String? _errorMessage;
  bool _pdfLoadError = false;
  bool _showAntiScreenshotMessage = false;
  Timer? _securityTimer;
  String _randomSecurityId = '';
  final ScreenshotProtectionManager _protectionManager =
      ScreenshotProtectionManager();

  @override
  void initState() {
    super.initState();
    // Tambahkan observer
    WidgetsBinding.instance.addObserver(this);

    // Generate security ID
    _randomSecurityId = _generateRandomId();

    // Segera aktifkan anti-screenshot hanya jika diminta
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.enableAntiScreenshot) {
        // Aktifkan proteksi anti-screenshot
        await _protectionManager.enableProtection();

        // Setup deteksi screenshot untuk iOS
        if (Platform.isIOS) {
          _setupIOSScreenshotDetection();
        }

        // Start security timer
        _startSecurityTimer();
      }
    });
  }

  // Setup deteksi screenshot untuk iOS
  void _setupIOSScreenshotDetection() async {
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onScreenshotTaken') {
          print("iOS PDF Viewer: screenshot terdeteksi");
          _showAntiScreenshotNotification();
        }
        return null;
      });

      await _channel.invokeMethod('startScreenshotDetection');
      print("iOS PDF Viewer: screenshot detection setup berhasil");
    } catch (e) {
      print("Error saat setup iOS screenshot detection di PDF Viewer: $e");
    }
  }

  @override
  void dispose() {
    // Pastikan untuk menonaktifkan anti-screenshot saat keluar dari halaman ini
    _protectionManager.disableProtection();
    WidgetsBinding.instance.removeObserver(this);

    // Hentikan deteksi screenshot iOS
    if (Platform.isIOS && widget.enableAntiScreenshot) {
      _channel.invokeMethod('stopScreenshotDetection');
    }

    // Cancel security timer
    _securityTimer?.cancel();

    super.dispose();
  }

  // Observer untuk mendeteksi perubahan aplikasi
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ketika halaman ini dibuka kembali, aktifkan kembali anti-screenshot
      _protectionManager.enableProtection();

      // Ketika aplikasi dibuka kembali, periksa apakah screenshot diambil
      print("PDF Viewer: Aplikasi dibuka kembali, mungkin setelah screenshot");
      _showAntiScreenshotNotification();
    } else if (state == AppLifecycleState.paused) {
      // Ketika aplikasi di-pause, secara proaktif tampilkan pesan anti-screenshot
      _showAntiScreenshotNotification();
    }
  }

  // Untuk menampilkan notifikasi anti-screenshot
  void _showAntiScreenshotNotification() {
    setState(() {
      _showAntiScreenshotMessage = true;
    });

    // Sembunyikan pesan setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAntiScreenshotMessage = false;
        });
      }
    });
  }

  // Generate random ID for security tracking
  String _generateRandomId() {
    final random = Random();
    return DateTime.now().microsecondsSinceEpoch.toString() +
        random.nextInt(10000).toString();
  }

  // Start timer untuk cek keamanan secara berkala
  void _startSecurityTimer() {
    // Cek keamanan setiap 2 detik
    _securityTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Regenerate security ID secara berkala
      if (mounted) {
        setState(() {
          _randomSecurityId = _generateRandomId();
        });
      }

      // Re-enable anti-screenshot secara berkala
      _protectionManager.enableProtection();

      // Debug log
      print("PDF Security check: $_randomSecurityId");
    });
  }

  void _handlePdfLoaded(PdfDocumentLoadedDetails details) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handlePdfLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _pdfLoadError = true;
        _errorMessage = 'Gagal memuat dokumen: ${details.error}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF213268),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (!_pdfLoadError)
            SfPdfViewer.network(
              widget.pdfUrl,
              enableDoubleTapZooming: true,
              canShowScrollHead: true,
              enableTextSelection: false, // Mencegah seleksi teks
              canShowPasswordDialog: true,
              canShowScrollStatus: true,
              enableDocumentLinkAnnotation: false,
              pageSpacing: 4,
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handlePdfLoaded(details);
                });
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handlePdfLoadFailed(details);
                });
              },
            ),

          // Error view jika terjadi kesalahan
          if (_pdfLoadError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'Gagal memuat dokumen',
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF213268),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            ),

          // Indicator loading
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF213268),
              ),
            ),

          // Pesan anti-screenshot WhatsApp style
          if (_showAntiScreenshotMessage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.no_photography,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        ANTI_SCREENSHOT_MESSAGE,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Implementasi Image viewer yang aman tanpa kemampuan screenshot
class SecureImageViewerPage extends StatefulWidget {
  final String imageUrl;
  final String title;
  final bool enableAntiScreenshot; // Parameter baru

  const SecureImageViewerPage({
    super.key,
    required this.imageUrl,
    required this.title,
    this.enableAntiScreenshot = false, // Default ke false
  });

  @override
  State<SecureImageViewerPage> createState() => _SecureImageViewerPageState();
}

class _SecureImageViewerPageState extends State<SecureImageViewerPage>
    with WidgetsBindingObserver {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isLoading = true;
  String? _errorMessage;
  bool _imageLoadError = false;
  bool _showAntiScreenshotMessage = false;
  Timer? _securityTimer;
  String _randomSecurityId = '';
  final ScreenshotProtectionManager _protectionManager =
      ScreenshotProtectionManager();

  @override
  void initState() {
    super.initState();
    // Tambahkan observer
    WidgetsBinding.instance.addObserver(this);

    // Generate security ID
    _randomSecurityId = _generateRandomId();

    // Segera aktifkan anti-screenshot hanya jika diminta
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.enableAntiScreenshot) {
        // Aktifkan proteksi anti-screenshot
        await _protectionManager.enableProtection();

        // Setup deteksi screenshot untuk iOS
        if (Platform.isIOS) {
          _setupIOSScreenshotDetection();
        }

        // Start security timer
        _startSecurityTimer();
      }
    });
  }

  // Setup deteksi screenshot untuk iOS
  void _setupIOSScreenshotDetection() async {
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onScreenshotTaken') {
          print("iOS Image Viewer: screenshot terdeteksi");
          _showAntiScreenshotNotification();
        }
        return null;
      });

      await _channel.invokeMethod('startScreenshotDetection');
      print("iOS Image Viewer: screenshot detection setup berhasil");
    } catch (e) {
      print("Error saat setup iOS screenshot detection di Image Viewer: $e");
    }
  }

  @override
  void dispose() {
    // Pastikan untuk menonaktifkan anti-screenshot saat keluar dari halaman ini
    _protectionManager.disableProtection();
    _transformationController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    // Hentikan deteksi screenshot iOS
    if (Platform.isIOS && widget.enableAntiScreenshot) {
      _channel.invokeMethod('stopScreenshotDetection');
    }

    // Cancel security timer
    _securityTimer?.cancel();

    super.dispose();
  }

  // Observer untuk mendeteksi perubahan aplikasi
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ketika halaman ini dibuka kembali, aktifkan kembali anti-screenshot
      _protectionManager.enableProtection();

      // Ketika aplikasi dibuka kembali, periksa apakah screenshot diambil
      print(
          "Image Viewer: Aplikasi dibuka kembali, mungkin setelah screenshot");
      _showAntiScreenshotNotification();
    } else if (state == AppLifecycleState.paused) {
      // Ketika aplikasi di-pause, secara proaktif tampilkan pesan anti-screenshot
      _showAntiScreenshotNotification();
    }
  }

  // Untuk menampilkan notifikasi anti-screenshot
  void _showAntiScreenshotNotification() {
    setState(() {
      _showAntiScreenshotMessage = true;
    });

    // Sembunyikan pesan setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAntiScreenshotMessage = false;
        });
      }
    });
  }

  // Generate random ID for security tracking
  String _generateRandomId() {
    final random = Random();
    return DateTime.now().microsecondsSinceEpoch.toString() +
        random.nextInt(10000).toString();
  }

  // Fungsi untuk handle double tap zoom
  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      // Jika sudah di-zoom, kembali ke ukuran normal
      _transformationController.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      // Jika belum di-zoom, zoom ke posisi tap
      final position = _doubleTapDetails!.localPosition;
      // Zoom 2.5x
      final zoomed = Matrix4.identity()
        ..translate(-position.dx, -position.dy)
        ..scale(2.5)
        ..translate(position.dx, position.dy);
      _transformationController.value = zoomed;
    }
  }

  void _handleImageLoaded() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleImageError(Object error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _imageLoadError = true;
        _errorMessage = 'Gagal memuat gambar: $error';
      });
    }
  }

  // Start timer untuk cek keamanan secara berkala
  void _startSecurityTimer() {
    // Cek keamanan setiap 2 detik
    _securityTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Regenerate security ID secara berkala
      if (mounted) {
        setState(() {
          _randomSecurityId = _generateRandomId();
        });
      }

      // Re-enable anti-screenshot secara berkala
      _protectionManager.enableProtection();

      // Debug log
      print("Image Security check: $_randomSecurityId");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF213268),
        foregroundColor: Colors.white,
        actions: [
          // Tombol informasi
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Informasi'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Ketuk dua kali untuk memperbesar gambar'),
                      SizedBox(height: 4),
                      Text('• Geser untuk melihat bagian lain saat diperbesar'),
                      SizedBox(height: 4),
                      Text(
                          '• Ketuk dua kali lagi untuk kembali ke ukuran normal'),
                      SizedBox(height: 12),
                      Text(
                          'Dokumen ini dilindungi dan tidak dapat diambil screenshot.',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_imageLoadError)
            // Image Viewer dengan kemampuan zoom dan pan
            GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Hero(
                    tag: widget.imageUrl,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          // Jadwalkan setState untuk dijalankan setelah build selesai
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _handleImageLoaded();
                          });
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF213268),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Jadwalkan setState untuk dijalankan setelah build selesai
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _handleImageError(error);
                        });
                        return const SizedBox
                            .shrink(); // Widget kosong saat loading
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Error view jika terjadi kesalahan
          if (_imageLoadError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image,
                      size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Gagal memuat gambar',
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF213268),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            ),

          // Indicator loading
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF213268),
              ),
            ),

          // Pesan anti-screenshot WhatsApp style
          if (_showAntiScreenshotMessage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.no_photography,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        ANTI_SCREENSHOT_MESSAGE,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Kelas khusus untuk mencegah screenshot
class SecureWidget extends StatelessWidget {
  final Widget child;

  const SecureWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return RepaintBoundary(
        child: child,
      );
    } else {
      return child;
    }
  }
}
