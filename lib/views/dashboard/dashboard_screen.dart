import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF0D47A1),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logo.svg', // Sesuaikan path logo Anda
              height: 30,
            ),
            SizedBox(width: 8),
            Text(
              "RS UMMI",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
                "134.4k", "Asset", Icons.inventory, Color(0xFFC8E6C9)),
            _buildStatCard(
                "50", "Under Repair", Icons.build, Color(0xFFFFF9C4)),
            _buildStatCard("500", "Net Asset Value", Icons.monetization_on,
                Color(0xFFFFCDD2)),
            SizedBox(height: 16),
            _buildMenuButtons(),
            SizedBox(height: 16),
            Text("Recent Activity",
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildRecentActivity("04 Mar 25", "16:00", "Asset ID: 123456",
                "Checked Out", "Available"),
            _buildRecentActivity("04 Mar 25", "08:00", "Asset ID: 123456",
                "Available", "Checked Out"),
            _buildRecentActivity("03 Mar 25", "16:00", "Asset ID: 123456",
                "Checked Out", "Available"),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Widget untuk Card Statistik
  Widget _buildStatCard(
      String value, String title, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: color,
      margin: EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black54),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk Menu Buttons
  Widget _buildMenuButtons() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _menuButton("Maintenance", Icons.build),
          _menuButton("Inspection", Icons.search),
          _menuButton("Stockopname", Icons.inventory),
          _menuButton("Calibration", Icons.tune),
        ],
      ),
    );
  }

  Widget _menuButton(String title, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 4),
        Text(title,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  /// Widget untuk Recent Activity
  Widget _buildRecentActivity(String date, String time, String assetId,
      String fromStatus, String toStatus) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              color: Color(0xFF0D47A1),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$date $time",
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                Text(assetId,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text.rich(
                  TextSpan(
                    text: "You change status from ",
                    style: GoogleFonts.poppins(fontSize: 12),
                    children: [
                      TextSpan(
                          text: fromStatus,
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                      TextSpan(text: " to "),
                      TextSpan(
                          text: toStatus,
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
            ],
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: BottomNavigationBar(
            selectedItemColor: Color(0xFF0D47A1),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart), label: "Procurement"),
              BottomNavigationBarItem(icon: SizedBox.shrink(), label: ""),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: "History"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ),
        Positioned(
          bottom: 25,
          child: FloatingActionButton(
            backgroundColor: Color(0xFF0D47A1),
            onPressed: () {
              // Tambahkan fungsi scan QR
            },
            child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 36),
            elevation: 5,
          ),
        ),
      ],
    );
  }
}
