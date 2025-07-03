import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../controllers/recent_activity_controller.dart';
import '../../controllers/total_asset_controller.dart';
import '../../controllers/asset_under_repair_controller.dart';
import '../../controllers/net_asset_value_controller.dart';
import '../../models/history_model.dart';
import '../../utils/logger_util.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Load activities when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final loadThreshold = maxScroll * 0.8;

      LoggerUtil.d(
          "Scroll position: $currentScroll / $maxScroll (threshold: $loadThreshold)");

      if (currentScroll >= loadThreshold) {
        _loadMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {
      if (!_scrollController.hasClients) return;

      // Debug print scroll position
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final loadThreshold = maxScroll * 0.8;

      LoggerUtil.d(
          "Scroll position: $currentScroll / $maxScroll (threshold: $loadThreshold)");
    });
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final controller = context.read<RecentActivityController>();
      controller.setLoading(true);
      controller.resetState();
      await controller.loadRecentActivities();

      controller.setLoading(false);
    } catch (e) {
      LoggerUtil.e("Error loading data", e, StackTrace.current);
      context.read<RecentActivityController>().setLoading(false);
    }
  }

  Future<void> _loadMoreData() async {
    final controller = context.read<RecentActivityController>();

    LoggerUtil.d(
        "_loadMoreData called - isLoadingMore: $_isLoadingMore, hasMoreData: ${controller.hasMoreData}");

    if (_isLoadingMore || !controller.hasMoreData) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      await controller.loadMoreActivities();
      LoggerUtil.i(
          "Loaded more data - total activities: ${controller.activities.length}");
    } catch (e) {
      LoggerUtil.e("Error loading more data", e, StackTrace.current);
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Widget _buildHistoryItem(HistoryModel activity) {
    final formattedDate =
        DateFormat('dd/MM/yyyy').format(activity.actionDate.toLocal());
    final formattedTime =
        DateFormat('HH:mm').format(activity.actionDate.toLocal());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue line on the left
          Container(
            width: 8,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFF25B1FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          // Date and time
          Padding(
            padding: const EdgeInsets.only(left: 11, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 90,
            color: const Color(0xFFCAC4D0),
          ),
          // Asset info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ID Aset: ${activity.assetInfo.assetCode}',
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF757575),
                    ),
                  ),
                  Text(
                    activity.assetInfo.assetName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF213268),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusMessage(activity),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(HistoryModel activity) {
    final badgeText = _getStatusText(activity.newStatus);
    final badgeColor = _getStatusColor(badgeText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        badgeText,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusMessage(HistoryModel activity) {
    // Get the current user's employee number from controller
    final controller =
        Provider.of<RecentActivityController>(context, listen: false);
    final currentEmployeeNumber = controller.employeeNumber;

    // Cek apakah pesan berisi perubahan status
    if (activity.message.contains('mengubah status dari')) {
      // Ekstrak status lama dan baru dari pesan
      final parts = activity.message.split(' ');
      String employeeId = parts[0];

      // If this activity matches the current user, change to "Anda"
      final isCurrentUser =
          currentEmployeeNumber != null && employeeId == currentEmployeeNumber;

      if (isCurrentUser) {
        employeeId = "Anda";
      }

      // Cari posisi kata "dari" dan "menjadi"
      final dariIndex = parts.indexOf('dari');
      final menjadiIndex = parts.indexOf('menjadi');

      if (dariIndex != -1 && menjadiIndex != -1 && dariIndex < menjadiIndex) {
        // Dapatkan status lama dan baru
        String oldStatus = "";
        if (dariIndex + 1 < parts.length) {
          oldStatus = parts[dariIndex + 1];
          // Jika status adalah "dalam perbaikan", gabungkan kedua kata
          if (oldStatus.toLowerCase() == "dalam" &&
              dariIndex + 2 < parts.length &&
              parts[dariIndex + 2].toLowerCase() == "perbaikan") {
            oldStatus = "dalam perbaikan";
          }
        }

        String newStatus = "";
        if (menjadiIndex + 1 < parts.length) {
          newStatus = parts[menjadiIndex + 1];
          // Jika status adalah "dalam perbaikan", gabungkan kedua kata
          if (newStatus.toLowerCase() == "dalam" &&
              menjadiIndex + 2 < parts.length &&
              parts[menjadiIndex + 2].toLowerCase() == "perbaikan") {
            newStatus = "dalam perbaikan";
          }
        }

        // Jika status mengandung kata "lost" atau "damaged", ubah ke bahasa Indonesia
        if (oldStatus.toLowerCase() == "lost") oldStatus = "hilang";
        if (newStatus.toLowerCase() == "lost") newStatus = "hilang";
        if (oldStatus.toLowerCase() == "damaged") oldStatus = "rusak";
        if (newStatus.toLowerCase() == "damaged") newStatus = "rusak";

        return RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
            children: [
              TextSpan(
                text: '$employeeId mengubah status dari ',
                style: TextStyle(
                  color: isCurrentUser ? const Color(0xFF213268) : Colors.black,
                ),
              ),
              _buildInlineStatusBadge(oldStatus),
              TextSpan(text: ' ke '),
              _buildInlineStatusBadge(newStatus),
            ],
          ),
        );
      }
    }

    // Jika tidak berisi perubahan status, tampilkan pesan biasa
    return Text(
      activity.message,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  InlineSpan _buildInlineStatusBadge(String status) {
    final badgeText = _getStatusText(status);
    final badgeColor = _getStatusColor(badgeText);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          badgeText,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    // Standarisasi status dalam bahasa Indonesia
    switch (status.toLowerCase()) {
      case 'tersedia':
      case 'available':
      case 'dikembalikan':
      case 'returned':
        return "TERSEDIA";
      case 'dipinjam':
      case 'borrowed':
      case 'checked out':
      case 'checked':
        return "DIPINJAM";
      case 'dalam perbaikan':
      case 'perbaikan':
      case 'dalam':
      case 'in repair':
      case 'rusak':
      case 'damaged':
        return "PERBAIKAN";
      case 'dihapuskan':
      case 'disposed':
        return "DIHAPUSKAN";
      case 'hilang':
      case 'lost':
        return "HILANG";
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'TERSEDIA':
        return const Color(0xFF7CB60C); // Hijau
      case 'PERBAIKAN':
        return const Color(0xFF25B1FF); // Biru
      case 'DIPINJAM':
        return const Color(0xFFDAAE0F); // Kuning
      case 'DIHAPUSKAN':
        return const Color(0xFFACC3EF); // Abu-abu
      case 'HILANG':
        return const Color(0xFFFF4A2B); // Merah
      default:
        return Colors.grey;
    }
  }

  Widget _buildMonthSection(String monthYear, List<HistoryModel> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 16),
          child: Text(
            monthYear,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF213268),
              height: 0.75,
            ),
          ),
        ),
        ...activities.map((activity) => _buildHistoryItem(activity)),
      ],
    );
  }

  Widget _buildSkeletonHistoryItem() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garis biru di kiri
          Container(
            width: 8,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFF25B1FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          // Tanggal dan waktu
          Padding(
            padding: const EdgeInsets.only(left: 11, top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
          // Divider vertikal
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 1,
            height: 90,
            color: const Color(0xFFCAC4D0),
          ),
          // Informasi aktivitas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 200,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildSkeletonMonthSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 24,
            margin: const EdgeInsets.only(bottom: 10, top: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          ...List.generate(3, (index) => _buildSkeletonHistoryItem()),
        ],
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    try {
      // Setel loading di home screen sebelum kembali
      final assetController =
          Provider.of<TotalAssetController>(context, listen: false);
      final repairController =
          Provider.of<AssetUnderRepairController>(context, listen: false);
      final navController =
          Provider.of<NetAssetValueController>(context, listen: false);
      final activityController =
          Provider.of<RecentActivityController>(context, listen: false);

      // Trigger loading state di home screen
      assetController.setLoading(true);
      repairController.setLoading(true);
      navController.setLoading(true);

      // Reset activity controller juga
      activityController.resetState();
      activityController.setLoading(true);

      // Kembalikan ke home screen
      Navigator.pop(context);

      // Delay sedikit agar animasi navigasi selesai dulu
      Future.delayed(const Duration(milliseconds: 300), () {
        // Trigger loading ulang data
        assetController.loadTotalAsset();
        repairController.setTotalAssetController(assetController);
        navController.loadNetAssetValue();
        activityController.loadRecentActivities();

        // Beri delay lagi sebelum hide skeleton
        Future.delayed(const Duration(milliseconds: 1200), () {
          assetController.setLoading(false);
          repairController.setLoading(false);
          navController.setLoading(false);
          activityController.setLoading(false);
        });
      });
    } catch (e) {
      LoggerUtil.e("Error saat navigasi kembali", e, StackTrace.current);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        Provider.of<RecentActivityController>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF213268),
        elevation: 0,
        title: Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _navigateBack(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Consumer<RecentActivityController>(
              builder: (context, controller, child) {
                return Text(
                  controller.employeeNumber != null
                      ? 'Menampilkan aktivitas untuk Pegawai ${controller.employeeNumber}'
                      : 'Menampilkan semua aktivitas Anda',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF757575),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF213268),
                  child: Consumer<RecentActivityController>(
                    builder: (context, controller, child) {
                      // Show loading skeleton
                      if (controller.isLoading &&
                          controller.activities.isEmpty) {
                        return Skeletonizer(
                          enabled: true,
                          effect: ShimmerEffect(
                            baseColor: Colors.grey.shade300,
                            highlightColor: const Color(0xFFE5EFFF),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 9, 24, 0),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: List.generate(
                                  3, (index) => _buildSkeletonMonthSection()),
                            ),
                          ),
                        );
                      }

                      // Show error message
                      if (controller.error != null &&
                          controller.activities.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 3,
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    controller.error!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      controller.clearError();
                                      _loadData();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF213268),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      // Show empty state
                      if (controller.activities.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 3,
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.history_outlined,
                                    size: 64,
                                    color: Color(0xFFCACFD8),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada aktivitas ditemukan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: const Color(0xFF757575),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tarik ke bawah untuk refresh data',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFFA4A4A4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      // Build the list of activities
                      final List<String> sortedMonths = controller
                          .activitiesByMonth.keys
                          .toList()
                        ..sort((a, b) {
                          // Sort months in descending order (newest first)
                          final List<String> monthsId = [
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

                          final aParts = a.split(' ');
                          final bParts = b.split(' ');

                          // Compare years first
                          final int aYear = int.parse(aParts[1]);
                          final int bYear = int.parse(bParts[1]);
                          if (aYear != bYear) return bYear.compareTo(aYear);

                          // If years are the same, compare months
                          final int aMonthIndex = monthsId.indexOf(aParts[0]);
                          final int bMonthIndex = monthsId.indexOf(bParts[0]);
                          return bMonthIndex.compareTo(aMonthIndex);
                        });

                      return ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 9, 24,
                            70), // Added bottom padding for the pagination indicator
                        itemCount: sortedMonths.length +
                            1, // +1 for the loading indicator
                        itemBuilder: (context, index) {
                          // Show activity groups
                          if (index < sortedMonths.length) {
                            final month = sortedMonths[index];
                            return _buildMonthSection(
                                month, controller.activitiesByMonth[month]!);
                          }

                          // Show loading indicator or pagination info at the bottom
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                if (_isLoadingMore)
                                  const CircularProgressIndicator(
                                      color: Color(0xFF213268))
                                else if (controller.hasMoreData)
                                  Text(
                                    'Scroll untuk memuat lebih banyak',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  )
                                else
                                  const SizedBox(),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Persistent pagination indicator at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Consumer<RecentActivityController>(
                    builder: (context, controller, _) {
                      final currentPage =
                          controller.pagination?.currentPage ?? 1;
                      final totalPages = controller.pagination?.totalPages ?? 1;
                      final totalItems = controller.pagination?.totalItems ?? 0;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFCAC4D0)),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Halaman $currentPage dari $totalPages ($totalItems item)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF213268),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
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
