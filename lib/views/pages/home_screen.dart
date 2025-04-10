import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/total_asset_controller.dart';
import '../../controllers/asset_under_repair_controller.dart';
import '../../controllers/net_asset_value_controller.dart';
import '../../views/complain/complain_list_screen.dart';
import '../../views/stockopname/stockopname_task_list.dart';
import '../pages/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes with error handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        print("Loading data for HomeScreen...");
        if (mounted) {
          _loadData();
        }
      } catch (e, s) {
        print("Error loading HomeScreen data: $e");
        print("Stack trace: $s");
      }
    });
  }

  // Separate method for loading data with error handling
  void _loadData() {
    try {
      context.read<TotalAssetController>().loadTotalAsset();
    } catch (e) {
      print("Error loading TotalAssetController: $e");
    }

    try {
      context.read<AssetUnderRepairController>().loadAssetUnderRepair();
    } catch (e) {
      print("Error loading AssetUnderRepairController: $e");
    }

    try {
      context.read<NetAssetValueController>().loadNetAssetValue();
    } catch (e) {
      print("Error loading NetAssetValueController: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Activity",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF213268),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "All My History",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF25B1FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildRecentActivities(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Consumer<TotalAssetController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return _buildStatCard(
                  "Loading...",
                  "Asset",
                  Icons.grid_4x4,
                  const Color(0xFFDCEDC8),
                );
              }

              if (controller.error != null) {
                return _buildStatCard(
                  "Error",
                  "Asset",
                  Icons.grid_4x4,
                  const Color(0xFFDCEDC8),
                );
              }

              return _buildStatCard(
                controller.totalAsset?.totalAssets ?? "134.4k",
                "Asset",
                Icons.grid_4x4,
                const Color(0xFFDCEDC8),
              );
            },
          ),
          const SizedBox(height: 8),
          Consumer<AssetUnderRepairController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return _buildStatCard(
                  "Loading...",
                  "Under Repair",
                  Icons.build,
                  const Color(0xFFFFF9C4),
                );
              }

              if (controller.error != null) {
                return _buildStatCard(
                  "Error",
                  "Under Repair",
                  Icons.build,
                  const Color(0xFFFFF9C4),
                );
              }

              return _buildStatCard(
                controller.assetUnderRepair?.totalUnderRepair ?? "50",
                "Under Repair",
                Icons.build,
                const Color(0xFFFFF9C4),
              );
            },
          ),
          const SizedBox(height: 8),
          Consumer<NetAssetValueController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return _buildStatCard(
                  "Loading...",
                  "Net Asset Value",
                  Icons.attach_money,
                  const Color(0xFFFFCCBC),
                );
              }

              if (controller.error != null) {
                return _buildStatCard(
                  "Error",
                  "Net Asset Value",
                  Icons.attach_money,
                  const Color(0xFFFFCCBC),
                );
              }

              return _buildStatCard(
                controller.netAssetValue?.totalNetValue ?? "500",
                "Net Asset Value",
                Icons.attach_money,
                const Color(0xFFFFCCBC),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String title,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
      ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: GoogleFonts.inter(
                  color: Colors.grey[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetId,
                  style: GoogleFonts.inter(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                    children: [
                      const TextSpan(text: 'You change status from '),
                      TextSpan(
                        text: fromStatus,
                        style: TextStyle(
                          color: fromStatus == 'Available'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' to '),
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
