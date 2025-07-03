import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../controllers/asset_history_controller.dart';
import '../../controllers/auth_controller.dart' as auth;
import '../../models/asset_history_item_model.dart';
import 'asset_document.dart';
import 'asset_mutation.dart';
import 'asset_details.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AssetHistory extends StatefulWidget {
  final Map<String, dynamic>? assetData;
  final String qrData;
  final String previousScreen;

  const AssetHistory({
    super.key,
    this.assetData,
    this.qrData = '',
    this.previousScreen = 'home',
  });

  @override
  State<AssetHistory> createState() => _AssetHistoryState();
}

class _AssetHistoryState extends State<AssetHistory> {
  late AssetHistoryController _historyController;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  int? _assetId;

  @override
  void initState() {
    super.initState();
    _historyController =
        Provider.of<AssetHistoryController>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAssetId();
    });
  }

  @override
  void dispose() {
    // Bersihkan controller saat widget dihapus
    _refreshController.dispose();
    // Reset controller untuk memastikan data segar saat halaman dibuka kembali
    _historyController.reset();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Perbarui data setiap kali halaman muncul kembali
    if (_assetId != null) {
      _fetchAssetHistory();
    }
  }

  // Ambil asset_id dari widget.assetData
  void _initializeAssetId() {
    if (widget.assetData == null) {
      _showError('Data aset tidak tersedia');
      return;
    }

    // Debug: tampilkan semua key yang tersedia di assetData
    print('Asset data keys available: ${widget.assetData!.keys.toList()}');
    print('Asset data: ${widget.assetData}');

    // Coba ambil asset_id dari berbagai properti yang mungkin
    var assetId = widget.assetData!['asset_id'];
    if (assetId == null) {
      assetId = widget.assetData!['id'];
      if (assetId == null) {
        assetId = widget.assetData!['asset_master_id'];
      }
    }

    if (assetId == null) {
      _showError('ID aset tidak ditemukan');
      return;
    }

    // Convert ke int jika diperlukan
    _assetId = assetId is int ? assetId : int.tryParse(assetId.toString());
    if (_assetId == null) {
      _showError('ID aset tidak valid');
      return;
    }

    // Fetch history
    _fetchAssetHistory();
  }

  // Mengambil riwayat aset berdasarkan asset_id
  Future<void> _fetchAssetHistory() async {
    if (_assetId == null) return;

    // Perbarui UI terlebih dahulu
    _historyController.refreshUI();

    // Ambil data baru
    await _historyController.fetchAssetHistory(_assetId!, context);
  }

  // Fungsi untuk refresh
  void _onRefresh() async {
    if (_assetId == null) return;
    await _historyController.fetchAssetHistory(_assetId!, context);
    _refreshController.refreshCompleted();
  }

  // Tampilkan pesan error
  void _showError(String message) {
    _historyController.clearError();
    _historyController.setError(message);
  }

  // Format tanggal API
  String formatAPIDateParam(DateTime date) {
    // Format tanggal yang diharapkan API: YYYY-MM-DD
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> histories = [];

  // Format tanggal
  String formatDate(DateTime date) {
    final List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Format hari
  String formatDay(DateTime date) {
    // Nama hari dalam bahasa Indonesia
    List<String> days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    return days[date.weekday % 7];
  }

  // Format tanggal dari API
  String formatAPIDate(String dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    return _historyController.formatAPIDate(dateString);
  }

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    // Buat tema khusus untuk kalender
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF213268), // Warna header kalender
        onPrimary: Colors.white, // Warna teks pada header
        onSurface: Color(0xFF666666), // Warna teks tanggal
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF213268), // Warna tombol
        ),
      ),
    );

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _historyController.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        // Menggunakan MediaQuery untuk mengatur skala teks dan mencegah overflow
        return Theme(
          data: theme,
          child: MediaQuery(
            // Tetapkan skala teks ke 1.0 untuk mencegah text overflow
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          ),
        );
      },
      // Gunakan root navigator untuk menghindari masalah layout
      useRootNavigator: true,
      // Lokalisasi kalender dalam bahasa Indonesia
      locale: const Locale('id', 'ID'),
      // Label teks dalam bahasa Indonesia
      confirmText: 'PILIH',
      cancelText: 'BATAL',
      helpText: 'PILIH TANGGAL',
      fieldLabelText: 'Masukkan Tanggal',
      errorFormatText: 'Format tanggal tidak valid',
      errorInvalidText: 'Tanggal tidak valid',
    );

    if (picked != null && picked != _historyController.selectedDate) {
      // Gunakan fungsi baru yang langsung mengambil data
      if (_assetId != null) {
        await _historyController.updateSelectedDateAndFetch(
            picked, _assetId!, context);
      }
    }
  }

  // Fungsi untuk navigasi hari
  void _changeDay(int days) async {
    // Gunakan fungsi baru yang langsung mengambil data
    if (_assetId != null) {
      await _historyController.changeDayAndFetch(days, _assetId!, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ukur tinggi status bar
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      // Hapus padding default
      body: Stack(
        children: [
          // Warna biru untuk seluruh area atas termasuk gap
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 82 +
                statusBarHeight +
                175, // Tinggi appbar + statusbar + header
            child: Container(
              color: const Color(0xFF25B1FF),
            ),
          ),

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
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF56C5F1),
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
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
                    // Navigasi ke halaman AssetDetails ketika tombol kembali ditekan
                    Navigator.push(
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

          // Content below AppBar
          Positioned(
            top: 82 + statusBarHeight, // Mulai tepat di bawah AppBar
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Blue Header Section untuk tanggal
                Container(
                  width: double.infinity,
                  height: 167,
                  color: const Color(0xFF25B1FF),
                  child: Stack(
                    children: [
                      // Border bawah putih untuk bagian "Change Date"
                      Positioned(
                        top: 18,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Color(0xFF25B1FF),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Change Date Button dengan fungsi
                      Positioned(
                        top: 30,
                        left: 30,
                        child: GestureDetector(
                          onTap: () => _selectDate(context),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Ubah Tanggal',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Date display
                      Positioned(
                        top: 82,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Consumer<AssetHistoryController>(
                            builder: (context, controller, child) {
                              return Text(
                                formatDate(controller.selectedDate),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF213268),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Day navigation
                      Positioned(
                        top: 124,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF213268),
                                size: 40,
                              ),
                              onPressed: () => _changeDay(-1),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 120),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Consumer<AssetHistoryController>(
                                builder: (context, controller, child) {
                                  return Text(
                                    formatDay(controller.selectedDate),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF213268),
                                    ),
                                    overflow: TextOverflow.visible,
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF213268),
                                size: 40,
                              ),
                              onPressed: () => _changeDay(1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Timeline Section - putih sampai tab bar
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Consumer<AssetHistoryController>(
                      builder: (context, controller, child) {
                        if (controller.isLoading && controller.error == null) {
                          return Skeletonizer(
                            enabled: true,
                            effect: ShimmerEffect(
                              baseColor: Colors.grey.shade300,
                              highlightColor: const Color(0xFFE5EFFF),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Stack(
                                children: [
                                  // Vertical Timeline Line
                                  Positioned(
                                    left: 35,
                                    top: 0,
                                    height: 3 * (80 + 20) - 20,
                                    width: 3,
                                    child: Container(
                                      color: const Color(0xFFAAAAAA),
                                    ),
                                  ),

                                  // Timeline Items
                                  Column(
                                    children: [
                                      _buildSkeletonTimelineItem(),
                                      const SizedBox(height: 20),
                                      _buildSkeletonTimelineItem(),
                                      const SizedBox(height: 20),
                                      _buildSkeletonTimelineItem(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (controller.error != null) {
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
                                    controller.error!,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _fetchAssetHistory,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Coba Lagi'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF213268),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (controller.histories.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: Colors.grey[400],
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tidak ada riwayat',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tidak ada aktivitas pada tanggal ini',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF999999),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _fetchAssetHistory,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Muat Ulang'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF25B1FF),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return SmartRefresher(
                            enablePullDown: true,
                            controller: _refreshController,
                            onRefresh: _onRefresh,
                            header: const WaterDropMaterialHeader(
                              backgroundColor: Color(0xFF25B1FF),
                              color: Colors.white,
                              distance: 60.0,
                            ),
                            child: SingleChildScrollView(
                              child: Container(
                                padding:
                                    const EdgeInsets.only(top: 30, bottom: 30),
                                child: Stack(
                                  children: [
                                    // Vertical Timeline Line - Berhenti di lingkaran terakhir
                                    Builder(builder: (context) {
                                      // Hitung tinggi total item
                                      final double totalHeight =
                                          (controller.histories.length - 1) *
                                              (69 + 20);

                                      return Positioned(
                                        left: 35,
                                        top: 0,
                                        height:
                                            totalHeight > 0 ? totalHeight : 0,
                                        width: 3,
                                        child: Container(
                                          color: const Color(0xFFAAAAAA),
                                        ),
                                      );
                                    }),

                                    // Timeline Items
                                    Column(
                                      children: controller.histories
                                          .map<Widget>((history) {
                                        final actionType = history.actionType;
                                        final message = history.message;
                                        final time = formatAPIDate(
                                            history.actionDate.toString());

                                        if (actionType.toUpperCase() ==
                                            'ASSET_STATUS_CHANGE') {
                                          final oldStatus = history.oldStatus;
                                          final newStatus = history.newStatus;
                                          final employeeId = history.employeeId;

                                          return Column(
                                            children: [
                                              _buildTimelineItem(
                                                actionType: actionType,
                                                message:
                                                    'Pegawai $employeeId mengubah status dari ',
                                                oldStatus: history
                                                    .translateStatus(oldStatus),
                                                connecting: ' ke ',
                                                newStatus: history
                                                    .translateStatus(newStatus),
                                                time: time,
                                              ),
                                              const SizedBox(height: 20),
                                            ],
                                          );
                                        } else {
                                          return Column(
                                            children: [
                                              _buildSimpleTimelineItem(
                                                message: message,
                                                time: time,
                                              ),
                                              const SizedBox(height: 20),
                                            ],
                                          );
                                        }
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTimelineItem({
    required String actionType,
    required String message,
    required String oldStatus,
    required String connecting,
    required String newStatus,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF213268),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              if (time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: message),
                    TextSpan(
                      text: oldStatus,
                      style: TextStyle(
                        color: _historyController.getStatusColor(oldStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: connecting),
                    TextSpan(
                      text: newStatus,
                      style: TextStyle(
                        color: _historyController.getStatusColor(newStatus),
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildDocumentTimelineItem({
    required String message,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF213268),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              if (time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTimelineItem({
    required String message,
    required String time,
  }) {
    IconData iconData = Icons.info_outline;
    AssetHistoryItem? historyItem;

    // Find the history item that matches this message
    for (var item in _historyController.histories) {
      if (item.message == message || message.contains(item.employeeId)) {
        historyItem = item;
        break;
      }
    }

    // Get action type from history item if available
    String actionType = historyItem?.actionType.toUpperCase() ?? '';

    // Select appropriate icon based on the action type or message content
    if (actionType == 'DOCUMENT_UPLOAD') {
      iconData = Icons.description;
    } else if (actionType == 'CALIBRATION') {
      iconData = Icons.settings;
    } else if (actionType == 'MAINTENANCE_SCHEDULE') {
      iconData = Icons.build;
    } else if (message.toLowerCase().contains('create')) {
      iconData = Icons.add_circle_outline;
    } else if (message.toLowerCase().contains('update')) {
      iconData = Icons.edit;
    } else if (message.toLowerCase().contains('delete')) {
      iconData = Icons.delete_outline;
    } else if (message.toLowerCase().contains('assign')) {
      iconData = Icons.person_add;
    } else if (message.toLowerCase().contains('check') ||
        message.toLowerCase().contains('inspect')) {
      iconData = Icons.check_circle_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF213268),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              if (time.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildHistoryMessageContent(historyItem, message),
            ),
          ),
        ],
      ),
    );
  }

  // New method to build message content based on action type
  Widget _buildHistoryMessageContent(
      AssetHistoryItem? historyItem, String message) {
    if (historyItem == null) {
      return Text(
        message,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Colors.black,
        ),
      );
    }

    String actionType = historyItem.actionType.toUpperCase();
    String employeeId = historyItem.employeeId;

    switch (actionType) {
      case 'CALIBRATION':
        String notes = '';
        if (historyItem.calibration != null &&
            historyItem.calibration!['notes'] != null) {
          notes = historyItem.calibration!['notes'].toString();
        } else {
          notes = historyItem.message;
        }

        return RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: 'Pegawai $employeeId ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: 'melakukan kalibrasi: '),
              TextSpan(
                text: notes,
                style: const TextStyle(
                  color: Color(0xFF25B1FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case 'MAINTENANCE_SCHEDULE':
        String description = '';
        if (historyItem.maintenance != null &&
            historyItem.maintenance!['description'] != null) {
          description = historyItem.maintenance!['description'].toString();
        } else {
          description = historyItem.message;
        }

        return RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: 'Pegawai $employeeId ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: 'menjadwalkan pemeliharaan: '),
              TextSpan(
                text: description,
                style: const TextStyle(
                  color: Color(0xFF25B1FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case 'DOCUMENT_UPLOAD':
        String title = '';
        if (historyItem.document != null &&
            historyItem.document!['title'] != null) {
          title = historyItem.document!['title'].toString();
        } else {
          title = historyItem.message;
        }

        return RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: 'Pegawai $employeeId ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: 'mengunggah dokumen: '),
              TextSpan(
                text: title,
                style: const TextStyle(
                  color: Color(0xFF213268),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      default:
        // For other types, just show the message with employee ID in bold
        if (message.startsWith('Pegawai $employeeId')) {
          return Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black,
            ),
          );
        } else {
          return RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: 'Pegawai $employeeId ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: message),
              ],
            ),
          );
        }
    }
  }

  Widget _buildSkeletonTimelineItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF213268),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 30,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
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
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AssetDocument(
                        assetData: widget.assetData,
                        qrData: widget.qrData,
                        previousScreen: widget.previousScreen,
                      )),
            ),
          ),
          _buildNavItem(
            Icons.history,
            'Riwayat',
            true,
            () {},
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

  String _addPegawaiPrefix(String message) {
    // Skip adding prefix if message already starts with "Pegawai"
    if (message.startsWith('Pegawai ')) {
      return message;
    }

    // Identify common patterns where employee ID/name appears at the start of the message
    final RegExp employeePattern = RegExp(r'^([a-zA-Z0-9_-]+)(\s+\w+)');
    final match = employeePattern.firstMatch(message);

    if (match != null) {
      // Replace the first word (likely an employee ID) with "Pegawai [ID]"
      return 'Pegawai ${match.group(1)}${match.group(2)}';
    }

    // If no pattern matches, return the original message
    return message;
  }
}
