import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const CustomAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 16),
                  _buildMenuButtons(),
                  const SizedBox(height: 24),
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRecentActivities(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        _buildStatCard(
          "134.4k",
          "Asset",
          Icons.business,
          Color(0xFFC8E6C9),
          Color(0xFF4CAF50),
        ),
        SizedBox(height: 8),
        _buildStatCard(
          "50",
          "Under Repair",
          Icons.build,
          Color(0xFFFFF9C4),
          Color(0xFFFFEB3B),
        ),
        SizedBox(height: 8),
        _buildStatCard(
          "500",
          "Net Asset Value",
          Icons.monetization_on,
          Color(0xFFFFCDD2),
          Color(0xFFF44336),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String title, IconData icon,
      Color bgColor, Color iconColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _menuButton("Maintenance", Icons.build),
          _menuButton("Inspection", Icons.search),
          _menuButton("Stock\nopname", Icons.inventory),
          _menuButton("Complain\nand Repair", Icons.report_problem),
          _menuButton("Calibration", Icons.tune),
        ],
      ),
    );
  }

  Widget _menuButton(String title, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      children: [
        _buildRecentActivity(
          "04 Mar 25",
          "16:00",
          "Asset ID: 123456",
          "Checked Out",
          "Available",
        ),
        _buildRecentActivity(
          "04 Mar 25",
          "08:00",
          "Asset ID: 123456",
          "Available",
          "Checked Out",
        ),
        _buildRecentActivity(
          "03 Mar 25",
          "16:00",
          "Asset ID: 123456",
          "Checked Out",
          "Available",
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    String date,
    String time,
    String assetId,
    String fromStatus,
    String toStatus,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              Text(
                time,
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetId,
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(text: 'You change status from '),
                      TextSpan(
                        text: fromStatus,
                        style: TextStyle(
                          color: fromStatus == 'Available'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' to '),
                      TextSpan(
                        text: toStatus,
                        style: TextStyle(
                          color: toStatus == 'Available'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
