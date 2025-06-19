import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../controllers/total_asset_controller.dart';
import '../../controllers/asset_under_repair_controller.dart';
import '../../controllers/net_asset_value_controller.dart';
import '../../controllers/recent_activity_controller.dart';
import '../../widgets/today_activities_widget.dart';
import 'package:flutter_assets_monitoring/models/net_asset_model.dart';
import 'package:flutter_assets_monitoring/views/notification/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cek apakah semua controller dalam keadaan loading, jika ya maka biarkan
    // Jika tidak, mungkin kita perlu muat data
    final assetController =
        Provider.of<TotalAssetController>(context, listen: false);
    final repairController =
        Provider.of<AssetUnderRepairController>(context, listen: false);
    final navController =
        Provider.of<NetAssetValueController>(context, listen: false);

    // Jika salah satu loading, berarti kita sedang dalam proses refresh dari halaman lain
    if (assetController.isLoading ||
        repairController.isLoading ||
        navController.isLoading) {
      print("Home screen detected loading state after navigation");
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // Separate method for loading data with error handling
  Future<void> _loadData() async {
    try {
      // Set loading state pada semua controller
      final assetController = context.read<TotalAssetController>();
      final repairController = context.read<AssetUnderRepairController>();
      final navController = context.read<NetAssetValueController>();

      // Reset semua controller ke state loading
      assetController.setLoading(true);
      repairController.setLoading(true);
      navController.setLoading(true);

      // Panggil loadTotalAsset
      assetController.loadTotalAsset();

      // Then set the reference in other controllers
      repairController.setTotalAssetController(assetController);

      // Finally load the asset value
      navController.loadNetAssetValue();

      // Muat ulang data aktivitas hari ini
      final activityController = context.read<RecentActivityController>();
      activityController.resetState();
      activityController.loadRecentActivities();

      // Tunggu sebentar untuk memastikan data sudah dimuat
      await Future.delayed(const Duration(milliseconds: 800));

      // Hentikan loading state pada semua controller
      if (mounted) {
        assetController.setLoading(false);
        repairController.setLoading(false);
        navController.setLoading(false);
      }

      // Complete refresh if controller is active
      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      print("Error loading controllers: $e");

      // Pastikan loading dimatikan meskipun error
      final assetController = context.read<TotalAssetController>();
      final repairController = context.read<AssetUnderRepairController>();
      final navController = context.read<NetAssetValueController>();

      assetController.setLoading(false);
      repairController.setLoading(false);
      navController.setLoading(false);

      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: _refreshController,
        onRefresh: _loadData,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
          completeDuration: const Duration(milliseconds: 500),
        ),
        header: const WaterDropMaterialHeader(
          backgroundColor: Colors.white,
          color: Color(0xFF213268),
          distance: 40.0,
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      kBottomNavigationBarHeight -
                      MediaQuery.of(context).padding.top -
                      82,
                ),
                child: Consumer3<TotalAssetController,
                    AssetUnderRepairController, NetAssetValueController>(
                  builder: (context, assetController, repairController,
                      navController, child) {
                    // Cek apakah ada controller yang masih loading
                    final isLoading = assetController.isLoading ||
                        repairController.isLoading ||
                        navController.isLoading;

                    if (isLoading) {
                      return Skeletonizer(
                        enabled: true,
                        effect: ShimmerEffect(
                          baseColor: Colors.grey.shade300,
                          highlightColor: const Color(0xFFE5EFFF),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSkeletonStatCards(),
                            const SizedBox(height: 16),
                            const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFEEEEEE)),
                            _buildSkeletonTodayActivities(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildAssetCard(assetController),
                              const SizedBox(height: 8),
                              _buildCalibrationCard(repairController),
                              const SizedBox(height: 8),
                              _buildDepreciationCard(
                                  navController.netAssetValue),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(
                            height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                        const TodayActivitiesWidget(),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 200,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonStatCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSkeletonStatCard(
            "Total Aset",
            Icons.grid_4x4,
            const Color(0xFFDCEDC8),
            showSubInfo: true,
            subInfoType: 'asset',
          ),
          const SizedBox(height: 8),
          _buildSkeletonStatCard(
            "Kalibrasi & Perawatan",
            Icons.build,
            const Color(0xFFFFF9C4),
            showSubInfo: true,
            subInfoType: 'calibration',
          ),
          const SizedBox(height: 8),
          _buildSkeletonStatCard(
            "Nilai Aset Bersih",
            Icons.attach_money,
            const Color(0xFFFFCCBC),
            showSubInfo: true,
            subInfoType: 'value',
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonStatCard(
    String title,
    IconData icon,
    Color bgColor, {
    bool showSubInfo = false,
    String subInfoType = '',
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
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
                Container(
                  width: 80,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (showSubInfo) ...[
                  const SizedBox(height: 6),
                  if (subInfoType == 'value') ...[
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ] else if (subInfoType == 'asset') ...[
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ] else if (subInfoType == 'calibration') ...[
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: bgColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonTodayActivities() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF213268),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 120,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            3,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: Color(0xFFCAC4D0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
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

  Widget _buildAssetCard(TotalAssetController controller) {
    // Warna untuk kartu Total Aset
    const Color cardColor = Color(0xFFDCEDC8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
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
            child: Icon(
              Icons.grid_4x4,
              color: cardColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard(AssetUnderRepairController controller) {
    // Ensure we have a valid value to display
    final calibrationCount = controller.totalCalibrationsNeeded;

    // Warna untuk kartu Kalibrasi & Perawatan
    const Color cardColor = Color(0xFFFFF9C4);
    const Color iconColor = Color(0xFFFFB74D); // Warna oranye untuk ikon

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.build,
              color: iconColor,
              size: 20,
            ),
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

    // Warna untuk kartu Nilai Aset Bersih
    const Color cardColor = Color(0xFFFFCCBC);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.attach_money,
              color: cardColor,
              size: 20,
            ),
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
                    if (controller.netAssetValue == null) {
                      return const SizedBox.shrink();
                    }
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: bgColor, size: 20),
          ),
        ],
      ),
    );
  }
}
