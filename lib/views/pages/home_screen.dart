import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../controllers/total_asset_controller.dart';
import '../../controllers/asset_under_repair_controller.dart';
import '../../controllers/net_asset_value_controller.dart';
import '../../views/inspection/inspection_screen.dart';
import '../../views/calibration/calibration_screen.dart';
import '../../views/maintenance/maintenance_screen.dart';
import '../../views/complain/complain_list_screen.dart';
import '../../views/stockopname/stockopname_task_list.dart';

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
            _buildMenuBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "Recent Activity",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213268),
                ),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.black54, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
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
        ],
      ),
    );
  }

  Widget _buildMenuBar() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF213268),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _menuBarItem(
            "Maintenance",
            Icons.build_circle_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MaintenanceScreen()),
              );
            },
          ),
          _menuBarItem(
            "Inspection",
            Icons.search,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InspectionScreen()),
              );
            },
          ),
          _menuBarItem(
            "Stock\nopname",
            Icons.inventory_2_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const StockopnameTaskList()),
              );
            },
          ),
          _menuBarItem(
            "Complain\nand Repair",
            Icons.warning_amber_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ComplainListScreen()),
              );
            },
          ),
          _menuBarItem(
            "Calibration",
            Icons.tune,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CalibrationScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menuBarItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 8,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetId,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 11,
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
