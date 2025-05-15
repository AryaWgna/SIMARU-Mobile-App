import 'package:flutter/material.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
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
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> histories = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _fetchAssetHistory();
  }

  // Format tanggal API
  String formatAPIDateParam(DateTime date) {
    // Format tanggal yang diharapkan API: YYYY-MM-DD
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onRefresh() async {
    // Monitor network fetching
    await _fetchAssetHistory(showLoading: false);

    // If failed, you can use refreshFailed()
    _refreshController.refreshCompleted();
  }

  Future<void> _fetchAssetHistory({bool showLoading = true}) async {
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

      // Gunakan asset_id untuk konsistensi dengan dokumen
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

      final formattedDate = formatAPIDateParam(selectedDate);
      print(
          'Mengambil riwayat untuk aset dengan ID: $assetId pada tanggal: $formattedDate');

      // Gunakan endpoint tanpa parameter tanggal
      // API mungkin tidak mendukung parameter tanggal atau mengharapkan format yang berbeda
      String url = '/asset-histories/$assetId';

      // Debug endpoint yang digunakan
      print('URL request yang digunakan: $url');

      final response = await ApiService.get(
        url,
        context: context,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> allHistories = [];

          // Cek format respons - biasanya dalam 'data' dan kemungkinan 'histories'
          if (data['data'] != null) {
            if (data['data'] is List) {
              // Jika data adalah array langsung
              allHistories = data['data'];
            } else if (data['data']['histories'] != null &&
                data['data']['histories'] is List) {
              // Jika data memiliki property histories
              allHistories = data['data']['histories'];
            } else if (data['data']['items'] != null &&
                data['data']['items'] is List) {
              // Jika data memiliki property items
              allHistories = data['data']['items'];
            } else {
              // Jika data adalah object tunggal
              allHistories = [data['data']];
            }
          }

          print('Jumlah riwayat sebelum filter: ${allHistories.length}');

          // Filter hasil berdasarkan tanggal yang dipilih dalam aplikasi
          // Ini diproses pada sisi client, bukan server
          final filteredHistories =
              _filterHistoriesByDate(allHistories, selectedDate);
          print('Jumlah riwayat setelah filter: ${filteredHistories.length}');

          setState(() {
            histories = filteredHistories;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = data['message'] ?? 'Gagal memuat riwayat aset';
          });
        }
      } else if (response.statusCode == 400) {
        // Penanganan khusus untuk error 400
        String errorMsg =
            'Permintaan tidak valid. Format parameter mungkin tidak sesuai.';
        try {
          final data = json.decode(response.body);
          if (data['message'] != null) {
            errorMsg = data['message'];
          } else if (data['error'] != null) {
            errorMsg = data['error'];
          }
          print('Error 400 detail: $data');
        } catch (e) {
          print('Failed to parse error response: $e');
        }

        setState(() {
          isLoading = false;
          errorMessage = errorMsg;
          histories = [];
        });

        // Jika mendapat error 400, coba endpoint alternatif
        _tryAlternativeEndpoint(assetId);
      } else if (response.statusCode == 404) {
        setState(() {
          isLoading = false;
          histories = [];
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
          errorMessage = 'Gagal memuat riwayat: Error ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error saat mengambil riwayat aset: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  // Metode baru untuk mencoba endpoint alternatif
  Future<void> _tryAlternativeEndpoint(String assetId) async {
    print('Mencoba endpoint alternatif untuk riwayat...');

    try {
      // Coba endpoint alternatif untuk riwayat
      var alternativeEndpoint = '/histories/asset/$assetId';
      print('Endpoint alternatif: $alternativeEndpoint');

      final response = await ApiService.get(
        alternativeEndpoint,
        context: context,
      );

      print('Response alternatif status: ${response.statusCode}');
      print('Response alternatif body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<dynamic> allHistories = [];

          if (data['data'] != null) {
            if (data['data'] is List) {
              allHistories = data['data'];
            } else if (data['data']['histories'] != null &&
                data['data']['histories'] is List) {
              allHistories = data['data']['histories'];
            } else if (data['data']['items'] != null &&
                data['data']['items'] is List) {
              allHistories = data['data']['items'];
            } else {
              allHistories = [data['data']];
            }
          }

          print(
              'Jumlah riwayat sebelum filter (endpoint alternatif): ${allHistories.length}');

          final filteredHistories =
              _filterHistoriesByDate(allHistories, selectedDate);
          print(
              'Jumlah riwayat setelah filter (endpoint alternatif): ${filteredHistories.length}');

          setState(() {
            histories = filteredHistories;
            isLoading = false;
            errorMessage = null; // Hapus pesan error sebelumnya
          });
        }
      }
    } catch (e) {
      print('Error pada endpoint alternatif: $e');
      // Tidak mengubah state karena ini hanya upaya backup
    }
  }

  // Fungsi untuk memfilter riwayat berdasarkan tanggal
  List<dynamic> _filterHistoriesByDate(List<dynamic> histories, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    print('Filtering untuk tanggal: $targetDate');

    return histories.where((history) {
      if (history['action_date'] != null) {
        try {
          final DateTime historyDate = DateTime.parse(history['action_date']);
          final bool match = historyDate.year == targetDate.year &&
              historyDate.month == targetDate.month &&
              historyDate.day == targetDate.day;

          // Debug output
          if (match) {
            print('Tanggal cocok: ${history['action_date']}');
          }

          return match;
        } catch (e) {
          print('Error parsing date: ${history['action_date']} - $e');
          return false;
        }
      }
      return false;
    }).toList();
  }

  // Format tanggal
  String formatDate(DateTime date) {
    // Format untuk Indonesia: DD Bulan YYYY
    List<String> months = [
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
    try {
      final date = DateTime.parse(dateString);
      // Format hanya waktu (jam:menit)
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$hour:$minute';
    } catch (e) {
      return '';
    }
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
      initialDate: selectedDate,
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

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      // Ambil riwayat untuk tanggal baru
      _fetchAssetHistory();
    }
  }

  // Fungsi untuk navigasi hari
  void _changeDay(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
    // Ambil riwayat untuk tanggal baru
    _fetchAssetHistory();
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

          // Content below AppBar
          Positioned(
            top: 82 + statusBarHeight, // Mulai tepat di bawah AppBar
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Blue Header Section
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
                                  fontFamily: 'Inter',
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
                          child: Text(
                            formatDate(selectedDate),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF213268),
                            ),
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
                              child: Text(
                                formatDay(selectedDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF213268),
                                ),
                                overflow: TextOverflow.visible,
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
                    child: isLoading
                        ? Skeletonizer(
                            enabled: true,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                children: [
                                  _buildSkeletonTimelineItem(),
                                  const SizedBox(height: 20),
                                  _buildSkeletonTimelineItem(),
                                  const SizedBox(height: 20),
                                  _buildSkeletonTimelineItem(),
                                ],
                              ),
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
                                        onPressed: _fetchAssetHistory,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF213268),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Coba Lagi'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : histories.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                        ],
                                      ),
                                    ),
                                  )
                                : SmartRefresher(
                                    enablePullDown: true,
                                    controller: _refreshController,
                                    onRefresh: _onRefresh,
                                    header: const WaterDropHeader(
                                      complete: Text(
                                        'Berhasil diperbarui',
                                        style:
                                            TextStyle(color: Color(0xFF213268)),
                                      ),
                                      failed: Text(
                                        'Gagal memperbarui',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            top: 30, bottom: 30),
                                        child: Stack(
                                          children: [
                                            // Vertical Timeline Line - Berhenti di lingkaran terakhir
                                            Builder(builder: (context) {
                                              // Hitung tinggi total item
                                              final double totalHeight =
                                                  (histories.length - 1) *
                                                      (69 + 20);

                                              return Positioned(
                                                left: 35,
                                                top: 0,
                                                height: totalHeight > 0
                                                    ? totalHeight
                                                    : 0,
                                                width: 3,
                                                child: Container(
                                                  color:
                                                      const Color(0xFFAAAAAA),
                                                ),
                                              );
                                            }),

                                            // Timeline Items
                                            Column(
                                              children: histories
                                                  .map<Widget>((history) {
                                                final actionType =
                                                    history['action_type'] ??
                                                        '';
                                                final message =
                                                    history['message'] ?? '';
                                                final time = formatAPIDate(
                                                    history['action_date'] ??
                                                        '');

                                                if (actionType ==
                                                    'ASSET_STATUS_CHANGE') {
                                                  final oldStatus =
                                                      history['old_status'] ??
                                                          '';
                                                  final newStatus =
                                                      history['new_status'] ??
                                                          '';
                                                  final employeeNumber = history[
                                                              'user']?[
                                                          'employee_number'] ??
                                                      '';

                                                  return Column(
                                                    children: [
                                                      _buildTimelineItem(
                                                        actionType: actionType,
                                                        message:
                                                            '$employeeNumber mengubah status dari ',
                                                        oldStatus:
                                                            _translateStatus(
                                                                oldStatus),
                                                        connecting: ' ke ',
                                                        newStatus:
                                                            _translateStatus(
                                                                newStatus),
                                                        time: time,
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                    ],
                                                  );
                                                } else if (actionType ==
                                                    'DOCUMENT_UPLOAD') {
                                                  final documentTitle =
                                                      history['document']
                                                              ?['title'] ??
                                                          '';
                                                  final employeeNumber = history[
                                                              'user']?[
                                                          'employee_number'] ??
                                                      '';

                                                  return Column(
                                                    children: [
                                                      _buildDocumentTimelineItem(
                                                        message: message
                                                                .contains(
                                                                    'uploaded')
                                                            ? '$employeeNumber mengunggah dokumen $documentTitle'
                                                            : message.contains(
                                                                    'updated')
                                                                ? '$employeeNumber memperbarui dokumen'
                                                                : message,
                                                        time: time,
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                    ],
                                                  );
                                                } else {
                                                  return Column(
                                                    children: [
                                                      _buildSimpleTimelineItem(
                                                        message: message,
                                                        time: time,
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                    ],
                                                  );
                                                }
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'returned':
        return 'Tersedia';
      case 'checked out':
        return 'Dipinjam';
      case 'under repair':
        return 'Perbaikan';
      case 'lost':
        return 'Hilang';
      case 'dispose':
        return 'Dibuang';
      default:
        return status;
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 21),
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
                        fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(text: message),
                    TextSpan(
                      text: oldStatus,
                      style: TextStyle(
                        color: oldStatus == 'Tersedia'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: connecting),
                    TextSpan(
                      text: newStatus,
                      style: TextStyle(
                        color: newStatus == 'Tersedia'
                            ? Colors.green
                            : Colors.orange,
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
      padding: const EdgeInsets.symmetric(horizontal: 21),
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
                        fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
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
                        fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
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

  Widget _buildSkeletonTimelineItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
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
}
