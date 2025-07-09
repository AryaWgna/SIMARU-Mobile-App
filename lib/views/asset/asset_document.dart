import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../controllers/asset/asset_document_controller.dart';
import 'asset_history.dart';
import 'asset_mutation.dart';
import 'asset_details.dart';
import '../../controllers/auth/auth_controller.dart';
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
import 'package:provider/provider.dart';
import '../../utils/logger_util.dart';

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
          LoggerUtil.i("ScreenshotProtectionManager: Protection enabled");
        }
      } catch (e) {
        LoggerUtil.e("ScreenshotProtectionManager: Error enabling protection",
            e, StackTrace.current);
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
          LoggerUtil.i("ScreenshotProtectionManager: Protection disabled");
        }
      } catch (e) {
        LoggerUtil.e("ScreenshotProtectionManager: Error disabling protection",
            e, StackTrace.current);
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
  late AssetDocumentController _documentController;
  Timer? _securityTimer;
  StreamSubscription? _iosScreenshotSubscription;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final ScreenshotProtectionManager _protectionManager =
      ScreenshotProtectionManager();
  int? _assetId;

  // Getters untuk memudahkan akses ke data controller
  bool get isLoading => _documentController.isLoading;
  String? get errorMessage => _documentController.error;
  List get documents => _documentController.documents;

  @override
  void initState() {
    super.initState();
    // Deteksi screensaver dan app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Inisialisasi controller
    _documentController =
        Provider.of<AssetDocumentController>(context, listen: false);

    // Generate security ID
    _documentController.generateRandomId();

    // Nonaktifkan anti-screenshot di halaman utama
    // Hanya aktifkan pada preview dokumen saja
    _protectionManager
        .disableProtection(); // Pastikan fitur off di halaman utama

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeAssetId();
    });
  }

  // Ambil asset_id dari widget.assetData
  void _initializeAssetId() {
    if (widget.assetData == null) {
      _showError('Data aset tidak tersedia');
      return;
    }

    LoggerUtil.d('Asset data: ${widget.assetData}');

    // Coba ambil asset_id dari berbagai properti yang mungkin
    var assetId = widget.assetData!['asset_id'];
    if (assetId == null) {
      assetId = widget.assetData!['id'];
    }

    if (assetId == null) {
      _showError('ID aset tidak ditemukan dalam data: ${widget.assetData}');
      return;
    }

    // Convert ke int jika diperlukan
    _assetId = assetId is int ? assetId : int.tryParse(assetId.toString());
    if (_assetId == null) {
      _showError('ID aset tidak valid: $assetId');
      return;
    }

    LoggerUtil.d('Menggunakan asset_id: $_assetId untuk mengambil dokumen');
    // Fetch documents
    _fetchAssetDocuments(showLoading: true);
  }

  // Tampilkan pesan error
  void _showError(String message) {
    _documentController.clearError();
    _documentController.setError(message);
  }

  // Setup deteksi screenshot untuk iOS
  void _setupIOSScreenshotDetection() async {
    // Fungsi dipertahankan untuk digunakan di viewer page
    // tapi tidak dipanggil di halaman utama
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onScreenshotTaken') {
          LoggerUtil.w("iOS screenshot terdeteksi");
          _showAntiScreenshotNotification();
        }
        return null;
      });

      await _channel.invokeMethod('startScreenshotDetection');
      LoggerUtil.i("iOS screenshot detection setup berhasil");
    } catch (e) {
      LoggerUtil.e(
          "Error saat setup iOS screenshot detection", e, StackTrace.current);
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
      LoggerUtil.w("Aplikasi dibuka kembali, mungkin setelah screenshot");
      _showAntiScreenshotNotification();
    } else if (state == AppLifecycleState.paused) {
      // Ketika aplikasi di-pause, secara proaktif tampilkan pesan anti-screenshot
      _showAntiScreenshotNotification();
    }
  }

  // Untuk menampilkan notifikasi anti-screenshot
  void _showAntiScreenshotNotification() {
    _documentController.showAntiScreenshotNotification();
  }

  // Metode untuk mengambil dokumen aset
  Future<void> _fetchAssetDocuments({bool showLoading = true}) async {
    if (_assetId == null) return;

    if (showLoading) {
      _documentController.setLoading(true);
    }

    await _documentController.fetchAssetDocuments(_assetId!, context);
  }

  // Start timer untuk cek keamanan secara berkala
  void _startSecurityTimer() {
    // Cek keamanan setiap 2 detik
    _securityTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Regenerate security ID secara berkala
      if (mounted) {
        _documentController.generateRandomId();
      }

      // Re-enable anti-screenshot secara berkala
      _protectionManager.enableProtection();

      // Debug log
      LoggerUtil.d("Security check: ${_documentController.randomSecurityId}");
    });
  }

  // Fungsi refresh untuk pull-to-refresh
  void _onRefresh() async {
    LoggerUtil.d("AssetDocument: onRefresh called");

    // Immediately set loading state to show skeletonizer
    await _fetchAssetDocuments(showLoading: true);

    LoggerUtil.d("AssetDocument: fetchAssetDocuments completed");

    _refreshController.refreshCompleted();
    LoggerUtil.d("AssetDocument: refreshController.refreshCompleted called");

    // Increment refresh counter
    _documentController.incrementRefreshCount();
    LoggerUtil.d(
        "AssetDocument: Refresh count: ${_documentController.refreshCount}");

    // Jika refresh counter mencapai 3, reset tampilan untuk mencegah zoom
    if (_documentController.refreshCount % 3 == 0 && mounted) {
      LoggerUtil.d(
          "AssetDocument: Resetting view after ${_documentController.refreshCount} refreshes");

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

  // Metode untuk menampilkan PDF viewer langsung dari URL
  void _openPdfViewerDirectly(Map<String, dynamic> document) {
    final filePath = document['file_path'];
    LoggerUtil.d('File path dari database (PDF): $filePath');
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

    LoggerUtil.d('Membuka PDF dari URL: $fullUrl');

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
      LoggerUtil.e('Error saat membuka PDF', e, StackTrace.current);
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
    LoggerUtil.d('File path dari database (Image): $filePath');
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

    LoggerUtil.d('Membuka gambar dari URL: $fullUrl');

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
      LoggerUtil.e('Error saat membuka gambar', e, StackTrace.current);
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
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Header Section
          _buildHeaderSection(context),

          // Content Section
          Positioned(
            top: 90 + statusBarHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Sub-tabs
                _buildTabSection(),

                // Document List Section
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFF5F5F5),
                    child: Consumer<AssetDocumentController>(
                        builder: (context, controller, child) {
                      if (controller.isLoading) {
                        return _buildLoadingView();
                      } else if (controller.error != null) {
                        return _buildErrorView(controller.error!);
                      } else if (controller.documents.isEmpty) {
                        return _buildEmptyView();
                      } else {
                        return SmartRefresher(
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
                          child: _buildDocumentListView(controller.documents),
                        );
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Anti-screenshot overlay if active
          Consumer<AssetDocumentController>(
            builder: (context, controller, child) {
              return controller.showAntiScreenshotMessage
                  ? _buildAntiScreenshotOverlay()
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(90),
      child: Stack(
        children: [
          // Warna biru tua untuk AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 90 + statusBarHeight,
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
            height: 90,
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

  Widget _buildTabSection() {
    // Implementasi tab section
    return Container(); // Placeholder, actual implementation needed
  }

  Widget _buildLoadingView() {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: Colors.grey.shade300,
        highlightColor: const Color(0xFFE5EFFF),
      ),
      child: _buildSkeletonLayout(),
    );
  }

  // Fungsi untuk membuat skeleton layout
  Widget _buildSkeletonLayout() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: 3, // Tampilkan 3 skeleton item
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        return _buildSkeletonDocumentCard();
      },
    );
  }

  // Fungsi untuk membuat skeleton document card
  Widget _buildSkeletonDocumentCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF213268).withOpacity(0.08),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(left: 15, top: 14, bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 11),
                  decoration: const BoxDecoration(
                    color: Color(0xFF213268),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade200,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSkeletonDetailRow(),
                const SizedBox(height: 12),
                _buildSkeletonDetailRow(),
                const SizedBox(height: 12),
                _buildSkeletonDetailRow(),
                const SizedBox(height: 12),
                _buildSkeletonDetailRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membuat skeleton detail row
  Widget _buildSkeletonDetailRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
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
              errorMessage,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchAssetDocuments(showLoading: true),
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
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, color: Colors.grey[400], size: 64),
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
            'Aset ini belum memiliki dokumen terkait\n(reguler, kalibrasi, atau pemeliharaan)',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentListView(List<dynamic> documents) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      physics: const ClampingScrollPhysics(),
      itemCount: documents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final document = documents[index];
        LoggerUtil.d('Rendering document at index $index: $document');
        return _buildDocumentCard(document);
      },
    );
  }

  Widget _buildDocumentCard(dynamic document) {
    // Ekstrak data dokumen
    final int documentId = document.documentId;
    final String documentTitle = document.title;
    final String fileName = document.fileName;
    final String fileType = document.fileType;
    final String uploadDate = _formatDate(document.uploadDate.toString());
    final String notes = document.notes ?? '-';
    final String docType = document.docType; // Kategori dokumen

    return GestureDetector(
      onTap: () {
        // Tentukan tipe file dan buka preview yang sesuai
        if (fileType == 'pdf') {
          _openPdfViewerDirectly({
            'document_id': documentId,
            'document_title': documentTitle,
            'file_path': document.filePath
          });
        } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileType)) {
          _openImageViewerDirectly({
            'document_id': documentId,
            'document_title': documentTitle,
            'file_path': document.filePath
          });
        } else {
          // Tampilkan dialog untuk file yang tidak didukung
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('File Tidak Didukung'),
              content: Text(
                  'Tipe file $fileType tidak dapat ditampilkan secara langsung.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 14, bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 11),
                    child: Icon(
                      _getFileIcon(fileType),
                      color: const Color(0xFF203268),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          documentTitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF213268),
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Hanya tampilkan badge untuk kategori Kalibrasi dan Pemeliharaan
                        if (docType == 'Kalibrasi' || docType == 'Pemeliharaan')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildDocTypeBadge(docType),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 1,
              color: const Color(0xFFAAAAAA),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDocumentDetail('Nama File', fileName),
                  const SizedBox(height: 12),
                  _buildDocumentDetail('Tipe File', fileType.toUpperCase()),
                  const SizedBox(height: 12),
                  _buildDocumentDetail('Catatan', notes),
                  const SizedBox(height: 12),
                  _buildDocumentDetail('Tanggal Upload', uploadDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF757575),
              letterSpacing: 0.1,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
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

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return Icons.video_library;
      case 'mp3':
      case 'wav':
      case 'ogg':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Widget untuk menampilkan badge kategori dokumen
  Widget _buildDocTypeBadge(String docType) {
    Color badgeColor;
    IconData badgeIcon;

    // Tentukan warna dan ikon berdasarkan tipe dokumen
    switch (docType) {
      case 'Kalibrasi':
        badgeColor = const Color(0xFF25B1FF); // Biru
        badgeIcon = Icons.hardware;
        break;
      case 'Pemeliharaan':
        badgeColor = const Color(0xFFDAAE0F); // Kuning
        badgeIcon = Icons.handyman;
        break;
      case 'Dokumen':
      default:
        badgeColor = const Color(0xFF7CB60C); // Hijau
        badgeIcon = Icons.description;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: badgeColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            docType,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAntiScreenshotOverlay() {
    return Positioned.fill(
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
    );
  }

  Widget _buildBottomNavigationBar() {
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
            true,
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
                fontFamily: 'Poppins',
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
          LoggerUtil.w("iOS PDF Viewer: screenshot terdeteksi");
          _showAntiScreenshotNotification();
        }
        return null;
      });

      await _channel.invokeMethod('startScreenshotDetection');
      LoggerUtil.i("iOS PDF Viewer: screenshot detection setup berhasil");
    } catch (e) {
      LoggerUtil.e("Error saat setup iOS screenshot detection di PDF Viewer", e,
          StackTrace.current);
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
      LoggerUtil.w(
          "PDF Viewer: Aplikasi dibuka kembali, mungkin setelah screenshot");
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
        _randomSecurityId = _generateRandomId();
      }

      // Re-enable anti-screenshot secara berkala
      _protectionManager.enableProtection();

      // Debug log
      LoggerUtil.d("Security check: $_randomSecurityId");
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
          LoggerUtil.w("iOS Image Viewer: screenshot terdeteksi");
          _showAntiScreenshotNotification();
        }
        return null;
      });

      await _channel.invokeMethod('startScreenshotDetection');
      LoggerUtil.i("iOS Image Viewer: screenshot detection setup berhasil");
    } catch (e) {
      LoggerUtil.e("Error saat setup iOS screenshot detection di Image Viewer",
          e, StackTrace.current);
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
      LoggerUtil.w(
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
        _randomSecurityId = _generateRandomId();
      }

      // Re-enable anti-screenshot secara berkala
      _protectionManager.enableProtection();

      // Debug log
      LoggerUtil.d("Security check: $_randomSecurityId");
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
