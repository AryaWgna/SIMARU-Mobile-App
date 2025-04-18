import 'package:flutter/material.dart';
import 'package:flutter_assets_monitoring/views/asset/asset_complaint_screen_new.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_schedule.dart';
import 'asset_mutation.dart';
import 'asset_depreciation.dart';
import 'lost.dart';
import 'dispose.dart';
import 'checkout.dart';
import '../dashboard/dashboard.dart';
import '../../core/config/api_config.dart';
import 'asset_complaint_screen.dart';
import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';

class AssetDetails extends StatefulWidget {
  final String qrData;
  final String previousScreen;
  final Map<String, dynamic>? assetData;

  const AssetDetails(
      {super.key,
      required this.qrData,
      this.previousScreen = 'home',
      this.assetData});

  @override
  State<AssetDetails> createState() => _AssetDetailsState();
}

class _AssetDetailsState extends State<AssetDetails> {
  @override
  Widget build(BuildContext context) {
    // Ambil data aset dari parameter atau gunakan default jika null
    final assetData = widget.assetData ?? {};

    // Debugging: Tampilkan informasi data aset untuk troubleshooting
    print('[DETAIL DEBUG] Data aset yang diterima: $assetData');
    print(
        '[DETAIL DEBUG] Current status dari API: ${assetData['current_status']}');

    final assetCode = assetData['asset_code'] ?? widget.qrData;
    final assetName = assetData['asset_name'] ?? 'Tidak diketahui';

    // Perbaikan untuk current_status - agar sesuai dengan database
    // Gunakan nilai dari database atau 'available' sebagai default yang aman
    final assetStatus =
        assetData['current_status']?.toString().toLowerCase() ?? 'available';
    print('[DETAIL DEBUG] Status yang akan digunakan: $assetStatus');

    // Informasi tambahan dengan format yang diperbaiki hanya untuk Condition dan Asset Type
    final brand = assetData['brand']?['brand_name'] ?? '-';
    final modelNumber = assetData['model_number'] ?? '-';

    // Hanya Condition yang diformat rapi
    final conditionRaw = assetData['condition'] ?? '-';
    final condition = formatText(conditionRaw);

    final warrantyDate = assetData['warranty_end_date'] ?? '-';

    // Kategori dan subcategori
    final category = assetData['subcategory']?['subcategory_name'] ?? '-';

    // Hanya Asset Type yang diformat rapi
    final assetTypeRaw = assetData['subcategory']?['asset_type'] ?? '-';
    final assetType = formatText(assetTypeRaw);

    final locationName = assetData['room']?['room_name'] ?? '-';

    // Mengambil jalur gambar dan membangun URL lengkap
    final imagePath = assetData['picture_path'];
    final imageUrl = imagePath != null
        ? '${ApiConfig.baseUrl}/public/images/${_extractFilename(imagePath)}'
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image and Asset Info Section
                  Container(
                    height: 220,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    // Gambar aset dengan URL yang diperbaiki dan border rounded
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                print('Image URL: $imageUrl');
                                return _buildImagePlaceholder(
                                    'Gambar tidak dapat dimuat',
                                    Icons.broken_image);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    _buildImagePlaceholder('', null),
                                    CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: const Color(0xFF213268),
                                    ),
                                  ],
                                );
                              },
                            )
                          : _buildImagePlaceholder(
                              'Tidak ada gambar', Icons.image_not_supported),
                    ),
                  ),

                  // Asset Code & Name with Available Tag
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assetCode,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF213268),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              assetName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF213268),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(assetStatus),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _getStatusText(assetStatus),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.logout,
                        label: 'Pinjam',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    CheckoutScreen(assetData: assetData)),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.report_problem_outlined,
                        label: 'Komplain',
                        onTap: () {
                          // Ambil asset_id dari data asset
                          final String assetId =
                              assetData['asset_id']?.toString() ?? '';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AssetComplaintScreen(
                                      assetData: assetData,
                                      assetCode: assetCode,
                                    )),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.help_outline,
                        label: 'Hilang',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    LostScreen(assetData: assetData)),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Asset Information Title
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Informasi Aset',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF213268),
                      ),
                    ),
                  ),

                  // Asset Information Table with swapped fields
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(2.5),
                    },
                    border: TableBorder.all(
                      color: const Color(0xFFEEF1F4),
                      width: 1,
                    ),
                    children: [
                      _buildTableRow('Kategori', category),
                      _buildTableRow('Tipe Aset', assetType),
                      _buildTableRow('Lokasi', locationName),
                      _buildTableRow('Merek', brand),
                      _buildTableRow('Tanggal Garansi', warrantyDate),
                      _buildTableRow('Kondisi', condition),
                      _buildTableRow('Nomor Model', modelNumber),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, ''),
    );
  }

  // Ekstrak nama file dari path
  String _extractFilename(String path) {
    // Jika path sudah dalam format yang benar, langsung kembalikan
    if (!path.contains('/')) return path;

    // Jika path lengkap (misalnya: /images/image-1743491338132-d9861d34-4854-46ea-bd8a-4597d1bdf029.png)
    // Ambil bagian terakhir setelah slash terakhir
    return path.split('/').last;
  }

  // Format text hanya untuk Condition dan Asset Type
  String formatText(String text) {
    if (text == '-') return text;

    // Replace underscores and dashes with spaces
    String formatted = text.replaceAll('_', ' ').replaceAll('-', ' ');

    // Capitalize each word
    List<String> words = formatted.split(' ');
    words = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).toList();

    return words.join(' ');
  }

  Color _getStatusColor(String status) {
    // Debug - tampilkan status yang diterima
    print('[DETAIL DEBUG] Mendapatkan warna untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke lowercase
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF659B09); // Hijau
      case 'in_use':
        return const Color(0xFF0086C3); // Biru
      case 'maintenance':
        return const Color(0xFFFF9900); // Oranye
      case 'dispose': // Tambahkan handle untuk 'dispose' (tanpa d di akhir)
      case 'disposed':
        return const Color(0xFF7A7A7A); // Abu-abu
      case 'lost':
        return const Color(0xFFDC3545); // Merah
      default:
        print(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return const Color(0xFF659B09); // Default hijau
    }
  }

  String _getStatusText(String status) {
    // Debug - tampilkan status yang diterima
    print('[DETAIL DEBUG] Mendapatkan teks untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke lowercase
    switch (status.toLowerCase()) {
      case 'available':
        return 'Tersedia';
      case 'in_use':
        return 'Digunakan';
      case 'maintenance':
        return 'Perbaikan';
      case 'dispose': // Tambahkan handle untuk 'dispose' (tanpa d di akhir)
        return 'Dibuang';
      case 'disposed':
        return 'Dibuang';
      case 'lost':
        return 'Hilang';
      default:
        print(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return 'Tersedia';
    }
  }

  // Fungsi untuk navigasi kembali ke layar sebelumnya
  void _navigateBack() {
    // Cek previousScreen untuk menentukan tab dashboard yang akan dibuka
    int dashboardIndex = 0;

    switch (widget.previousScreen) {
      case 'home':
        dashboardIndex = 0;
        break;
      case 'stockopname':
        dashboardIndex = 1;
        break;
      case 'repair':
        dashboardIndex = 3;
        break;
      case 'profile':
        dashboardIndex = 4;
        break;
      default:
        dashboardIndex = 0;
    }

    // Navigasi kembali ke DashboardScreen dengan tab yang sesuai
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(initialIndex: dashboardIndex),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Ukur tinggi status bar
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

          // AppBar Content - hanya logo di tengah tanpa tombol back
          Positioned(
            top: statusBarHeight,
            left: 0,
            right: 0,
            height: 82,
            child: Center(
              child: Image.asset(
                'images/Logo_RS_UMMI_white.png',
                width: 208.14,
                height: 55,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF213268), width: 2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF213268),
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF213268),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF3D3D3D),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF3D3D3D),
            ),
          ),
        ),
      ],
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

  Widget _buildImagePlaceholder(String text, IconData? icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 40,
              color: Colors.white70,
            ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
