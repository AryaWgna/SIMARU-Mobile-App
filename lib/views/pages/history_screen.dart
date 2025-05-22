import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../controllers/recent_activity_controller.dart';
import '../../controllers/total_asset_controller.dart';
import '../../controllers/asset_under_repair_controller.dart';
import '../../controllers/net_asset_value_controller.dart';
import '../../models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final controller = context.read<RecentActivityController>();

      // Set flag loading dan clear dahulu agar terlihat efek visual refresh
      controller.setLoading(true);

      // Reset state dan muat ulang data
      controller.resetState();
      await controller.loadRecentActivities();

      if (_refreshController.isRefresh) {
        _refreshController.refreshCompleted();

        // Berikan jeda kecil sebelum set loading false agar UX pull-to-refresh terasa
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            controller.setLoading(false);
          }
        });
      } else {
        controller.setLoading(false);
      }
    } catch (e) {
      print("Error loading data: $e");
      final controller = context.read<RecentActivityController>();
      controller.setLoading(false);
      if (_refreshController.isRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await context.read<RecentActivityController>().loadMoreActivities();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Widget _buildHistoryItem(HistoryModel activity) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(activity.actionDate);
    final formattedTime = DateFormat('HH:mm').format(activity.actionDate);

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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF757575),
                    ),
                  ),
                  Text(
                    activity.assetInfo.assetName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusMessage(HistoryModel activity) {
    // Cek apakah pesan berisi perubahan status
    if (activity.message.contains('mengubah status dari')) {
      // Ekstrak status lama dan baru dari pesan
      final parts = activity.message.split(' ');
      final employeeId = parts[0];

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
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black,
            ),
            children: [
              TextSpan(text: '$employeeId mengubah status dari '),
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
      style: GoogleFonts.inter(
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          badgeText,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
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
        return "DIPINJAM";
      case 'dalam perbaikan':
      case 'perbaikan':
      case 'dalam':
      case 'in repair':
      case 'rusak':
      case 'damaged':
        return "PERBAIKAN";
      case 'dimusnahkan':
      case 'disposed':
      case 'hilang':
      case 'lost':
        return "HILANG";
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'HILANG':
        return const Color(0xFFFF5252); // Merah
      case 'PERBAIKAN':
        return const Color(0xFF29B6F6); // Biru
      case 'TERSEDIA':
        return const Color(0xFF8BC34A); // Hijau
      case 'DIPINJAM':
        return const Color(0xFFFFB74D); // Oranye
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
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF213268),
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
      print("Error saat navigasi kembali: $e");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF213268),
        elevation: 0,
        title: Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _navigateBack(context),
        ),
      ),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: false,
        controller: _refreshController,
        onRefresh: _loadData,
        scrollController: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        footer: ClassicFooter(
          loadStyle: LoadStyle.ShowWhenLoading,
          completeDuration: const Duration(milliseconds: 500),
        ),
        header: const WaterDropMaterialHeader(
          backgroundColor: Color(0xFF213268),
          color: Colors.white,
          distance: 40.0,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Menampilkan semua aktivitas Anda',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF757575),
                ),
              ),
            ),
            Consumer<RecentActivityController>(
              builder: (context, controller, child) {
                // Tampilkan skeleton saat loading pertama kali
                if (controller.isLoading && controller.activities.isEmpty) {
                  return Expanded(
                    child: Skeletonizer(
                      enabled: true,
                      effect: ShimmerEffect(
                        baseColor: Colors.grey.shade300,
                        highlightColor: const Color(0xFFE5EFFF),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 9, 24, 0),
                        child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            ...List.generate(
                                3, (index) => _buildSkeletonMonthSection()),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Tampilkan pesan error jika ada
                if (controller.error != null && controller.activities.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.error!,
                            style: GoogleFonts.inter(
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
                  );
                }

                // Tampilkan daftar aktivitas
                if (controller.activities.isEmpty) {
                  return Expanded(
                    child: Center(
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
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tarik ke bawah untuk refresh data',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFFA4A4A4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 9, 24, 0),
                    child: Stack(
                      children: [
                        ListView.builder(
                          // Jangan gunakan controller yang sama dengan SmartRefresher
                          // agar tidak konflik
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: controller.activitiesByMonth.length + 1,
                          itemBuilder: (context, index) {
                            if (index < controller.activitiesByMonth.length) {
                              final List<String> sortedMonths =
                                  controller.activitiesByMonth.keys.toList()
                                    ..sort((a, b) {
                                      // Sort bulan secara descending (terbaru dulu)
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

                                      // Bandingkan tahun terlebih dahulu
                                      final int aYear = int.parse(aParts[1]);
                                      final int bYear = int.parse(bParts[1]);
                                      if (aYear != bYear)
                                        return bYear.compareTo(aYear);

                                      // Jika tahun sama, bandingkan bulan
                                      final int aMonthIndex =
                                          monthsId.indexOf(aParts[0]);
                                      final int bMonthIndex =
                                          monthsId.indexOf(bParts[0]);
                                      return bMonthIndex.compareTo(aMonthIndex);
                                    });

                              final month = sortedMonths[index];
                              return _buildMonthSection(
                                  month, controller.activitiesByMonth[month]!);
                            } else {
                              if (controller.hasMoreData) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Center(
                                    child: controller.isLoading
                                        ? const CircularProgressIndicator(
                                            color: Color(0xFF213268),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              }
                              return const SizedBox(height: 20);
                            }
                          },
                        ),
                        if (_isLoadingMore && !controller.isLoading)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.white.withOpacity(0.7),
                              padding: const EdgeInsets.all(8.0),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF213268),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Consumer<RecentActivityController>(
              builder: (context, controller, _) {
                final pagination = controller.pagination;
                if (pagination != null) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    color: Colors.grey[100],
                    child: Text(
                      'Halaman ${pagination.currentPage} dari ${pagination.totalPages} (${pagination.totalItems} item)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
