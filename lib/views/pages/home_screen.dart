import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/total_asset_controller.dart';
import '../../controllers/asset_under_repair_controller.dart';
import '../../controllers/net_asset_value_controller.dart';
import '../pages/history_screen.dart';
import '../../widgets/today_activities_widget.dart';

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
      // First load the dashboard summary
      final assetController = context.read<TotalAssetController>();
      assetController.loadTotalAsset();

      // Then set the reference in other controllers
      final repairController = context.read<AssetUnderRepairController>();
      repairController.setTotalAssetController(assetController);

      // Finally load the asset value
      context.read<NetAssetValueController>().loadNetAssetValue();
    } catch (e) {
      print("Error loading controllers: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCards(),
            const SizedBox(height: 16),
            TodayActivitiesWidget(),
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
                  "Memuat...",
                  "Total Aset",
                  Icons.grid_4x4,
                  const Color(0xFFDCEDC8),
                );
              }

              if (controller.error != null) {
                return _buildStatCard(
                  "Kesalahan",
                  "Total Aset",
                  Icons.grid_4x4,
                  const Color(0xFFDCEDC8),
                );
              }

              return _buildAssetCard(controller);
            },
          ),
          const SizedBox(height: 8),
          Consumer<AssetUnderRepairController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return _buildStatCard(
                  "Memuat...",
                  "Kalibrasi & Perawatan",
                  Icons.build,
                  const Color(0xFFFFF9C4),
                );
              }

              if (controller.error != null) {
                return _buildStatCard(
                  "Kesalahan",
                  "Kalibrasi & Perawatan",
                  Icons.build,
                  const Color(0xFFFFF9C4),
                );
              }

              return _buildCalibrationCard(controller);
            },
          ),
          const SizedBox(height: 8),
          Consumer<NetAssetValueController>(
            builder: (context, controller, child) {
              if (controller.isLoading) {
                return _buildStatCard(
                  "Memuat...",
                  "Nilai Aset Bersih",
                  Icons.attach_money,
                  const Color(0xFFFFCCBC),
                );
              }

              if (controller.error != null) {
                return _buildStatCard(
                  "Kesalahan",
                  "Nilai Aset Bersih",
                  Icons.attach_money,
                  const Color(0xFFFFCCBC),
                );
              }

              return _buildDepreciationCard(controller.netAssetValue);
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: title == "Nilai Aset Bersih" ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (title == "Nilai Aset Bersih")
                  Consumer<NetAssetValueController>(
                      builder: (context, controller, _) {
                    if (controller.netAssetValue == null)
                      return const SizedBox.shrink();
                    return Text(
                      "Per ${controller.netAssetValue?.asOfDate ?? '-'}",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    );
                  }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF213268).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF213268), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDepreciationCard(NetAssetModel? data) {
    if (data == null) {
      return _buildStatCard(
        "0",
        "Nilai Aset Bersih",
        Icons.attach_money,
        const Color(0xFFFFCCBC),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFCCBC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Rp ",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        data.formattedTotalBookValue,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Nilai Aset Bersih",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Depresiasi: Rp ${data.formattedTotalDepreciation}",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  "Per ${data.asOfDate}",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF213268).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.attach_money,
                color: const Color(0xFF213268), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard(AssetUnderRepairController controller) {
    // Ensure we have a valid value to display
    final calibrationCount = controller.totalCalibrationsNeeded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  calibrationCount,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Kalibrasi & Perawatan",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  calibrationCount == "0"
                      ? "Tidak ada kalibrasi mendatang"
                      : "Perlu perhatian segera",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.build, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(TotalAssetController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEDC8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.totalAssets,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Total Aset",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (controller.dashboardSummary != null)
                  Row(
                    children: [
                      Text(
                        "Medical: ${controller.dashboardSummary!.assetsByType['medical'] ?? 0}",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Non-Medical: ${controller.dashboardSummary!.assetsByType['non_medical'] ?? 0}",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.grid_4x4, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }
}
