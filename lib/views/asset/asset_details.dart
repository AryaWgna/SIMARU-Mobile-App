import 'package:flutter/material.dart';
import 'asset_document.dart';
import 'asset_history.dart';
import 'asset_schedule.dart';
import 'asset_mutation.dart';
import 'asset_depreciation.dart';
import 'lost.dart';
import 'dispose.dart';
import 'checkout.dart';
import '../dashboard/dashboard.dart';

class AssetDetails extends StatefulWidget {
  final String qrData;
  final String previousScreen;

  const AssetDetails(
      {super.key, required this.qrData, this.previousScreen = 'home'});

  @override
  State<AssetDetails> createState() => _AssetDetailsState();
}

class _AssetDetailsState extends State<AssetDetails> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateBack();
        return false;
      },
      child: Scaffold(
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
                    ),

                    // Asset Code & Name with Available Tag
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Asset Code',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF213268),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Asset Name',
                                style: TextStyle(
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
                              color: const Color(0xFF659B09),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
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
                          label: 'Check Out',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen()),
                            );
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Dispose',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const DisposeScreen()),
                            );
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.help_outline,
                          label: 'Lost',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LostScreen()),
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
                        'Asset Information',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF213268),
                        ),
                      ),
                    ),

                    // Asset Information Table
                    _buildAssetInformationTable(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context, ''),
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

  // Fungsi untuk navigasi kembali ke layar sebelumnya
  void _navigateBack() {
    // Tutup semua layar sebelumnya dan navigasi ke dashboard dengan tab yang sesuai
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Tentukan index tab berdasarkan previousScreen
    int tabIndex = 0;
    switch (widget.previousScreen) {
      case 'home':
        tabIndex = 0;
        break;
      case 'procurement':
        tabIndex = 1;
        break;
      case 'history':
        tabIndex = 3;
        break;
      case 'profile':
        tabIndex = 4;
        break;
      default:
        tabIndex = 0;
    }

    // Navigasi ke Dashboard dengan tab yang sesuai
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(initialIndex: tabIndex),
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

  Widget _buildAssetInformationTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2.5),
      },
      border: TableBorder.all(
        color: const Color(0xFFEEF1F4),
        width: 1,
      ),
      children: [
        _buildTableRow('Categories', '-'),
        _buildTableRow('Sub Categories', '-'),
        _buildTableRow('Location', '-'),
        _buildTableRow('Brand', '-'),
        _buildTableRow('Warranty Date', '-'),
        _buildTableRow('Condition', '-'),
        _buildTableRow('Model Number', '-'),
      ],
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
            'Document',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetDocument()),
            ),
          ),
          _buildNavItem(
            Icons.history,
            'History',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetHistory()),
            ),
          ),
          _buildNavItem(
            Icons.calendar_today,
            'Schedule',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetSchedule()),
            ),
          ),
          _buildNavItem(
            Icons.swap_horiz,
            'Mutasi',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssetMutation()),
            ),
          ),
          _buildNavItem(
            Icons.trending_down,
            'Depreciation',
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AssetDepreciation()),
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
