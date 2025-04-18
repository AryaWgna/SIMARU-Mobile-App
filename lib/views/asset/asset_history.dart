import 'package:flutter/material.dart';
import 'asset_document.dart';
import 'asset_schedule.dart';
import 'asset_mutation.dart';
import 'asset_depreciation.dart';
import 'asset_details.dart';

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
    }
  }

  // Fungsi untuk navigasi hari
  void _changeDay(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
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
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.only(top: 30, bottom: 30),
                        child: Stack(
                          children: [
                            // Vertical Timeline Line - Berhenti di lingkaran terakhir
                            Builder(builder: (context) {
                              // Data timeline items
                              final List<String> timelineItems = [
                                'Item 1',
                                'Item 2',
                                'Item 3',
                              ];

                              // Hitung tinggi total item
                              final double totalHeight =
                                  (timelineItems.length - 1) * (69 + 20);

                              return Positioned(
                                left: 35,
                                top: 0,
                                height: totalHeight,
                                width: 3,
                                child: Container(
                                  color: const Color(0xFFAAAAAA),
                                ),
                              );
                            }),

                            // Timeline Items
                            Column(
                              children: [
                                _buildTimelineItem(
                                  'Jhon Doe mengubah status dari ',
                                  'Tersedia',
                                  ' ke ',
                                  'Dipinjam',
                                ),
                                const SizedBox(height: 20),
                                _buildTimelineItem(
                                  'Jane Doe mengubah status dari ',
                                  'Dipinjam',
                                  ' ke ',
                                  'Tersedia',
                                ),
                                const SizedBox(height: 20),
                                _buildTimelineItem(
                                  'Jane Doe mengubah status dari ',
                                  'Tersedia',
                                  ' ke ',
                                  'Dipinjam',
                                ),
                              ],
                            ),
                          ],
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

  Widget _buildTimelineItem(
      String text1, String status1, String text2, String status2) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFF213268),
              shape: BoxShape.circle,
            ),
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
                    TextSpan(text: text1),
                    TextSpan(
                      text: status1,
                      style: TextStyle(
                        color: status1 == 'Tersedia'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: text2),
                    TextSpan(
                      text: status2,
                      style: TextStyle(
                        color: status2 == 'Tersedia'
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
