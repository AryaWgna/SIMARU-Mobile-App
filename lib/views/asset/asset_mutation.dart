import 'package:flutter/material.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_details.dart';

class AssetMutation extends StatefulWidget {
  final Map<String, dynamic>? assetData;
  final String qrData;
  final String previousScreen;

  const AssetMutation({
    super.key,
    this.assetData,
    this.qrData = '',
    this.previousScreen = 'home',
  });

  @override
  State<AssetMutation> createState() => _AssetMutationState();
}

class _AssetMutationState extends State<AssetMutation> {
  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk responsivitas
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          width: screenSize.width,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Jarak dari AppBar
              const SizedBox(height: 24),

              // Box CHECK OUT dengan design responsif
              Container(
                width: double.infinity,
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
                    // Header dengan Icon dan Text
                    Container(
                      padding:
                          const EdgeInsets.only(left: 15, top: 14, bottom: 14),
                      child: Row(
                        children: [
                          // Ikon Logout
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 11),
                            child: const Icon(
                              Icons.logout,
                              color: Color(0xFF203268),
                              size: 24,
                            ),
                          ),
                          // Teks CHECK OUT
                          const Text(
                            'PEMINJAMAN',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF56C5F1),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider horizontal
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: const Color(0xFFAAAAAA),
                    ),

                    // Info section dengan layout yang lebih responsif
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow('Tanggal Dipinjam:', '04/03/2025'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Dipinjam oleh:', 'Jhon Doe'),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                              'Lokasi:', 'Gedung A, Ruang Thalasemia 1'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Batas Waktu:', 'Tidak Ada'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tambahkan padding di bagian bawah untuk memastikan tidak ada overflow
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context, 'mutation'),
    );
  }

  // Widget untuk membuat baris informasi yang lebih rapi dan responsif
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label dengan lebar tetap
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF757575),
              letterSpacing: 0.1,
            ),
          ),
        ),
        // Value dengan lebar yang menyesuaikan
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF757575),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return PreferredSize(
      preferredSize: const Size.fromHeight(82),
      child: Stack(
        children: [
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
            activePage == 'mutation',
            () {},
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
