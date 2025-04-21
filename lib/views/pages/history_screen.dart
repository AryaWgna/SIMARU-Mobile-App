import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/recent_activity_controller.dart';
import '../../models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Load activities when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecentActivityController>().loadRecentActivities();
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    final controller = context.read<RecentActivityController>();

    // Cek apakah sedang loading atau tidak ada data lagi
    if (_isLoadingMore || !controller.hasMoreData || controller.isLoading) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    await controller.loadMoreActivities();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
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
        boxShadow: [
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontFamily: 'Inter',
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
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF757575),
                    ),
                  ),
                  Text(
                    activity.assetInfo.assetName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF213268),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(activity.newStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity.newStatus,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'tersedia':
        return Colors.green;
      case 'dipinjam':
        return Colors.orange;
      case 'dikembalikan':
        return Colors.blue;
      case 'dalam perbaikan':
        return Colors.red;
      case 'dimusnahkan':
        return Colors.grey[800]!;
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
            style: const TextStyle(
              fontFamily: 'Inter',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF213268),
        elevation: 0,
        title: Text('Riwayat Aktivitas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Title and subtitle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menampilkan semua aktivitas Anda',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
          // History items
          Expanded(
            child: Consumer<RecentActivityController>(
              builder: (context, controller, child) {
                // Menampilkan indikator loading saat pertama kali memuat data
                if (controller.isLoading && controller.activities.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF213268),
                    ),
                  );
                }

                // Menampilkan pesan error jika gagal memuat data
                if (controller.error != null && controller.activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            controller.clearError();
                            controller.loadRecentActivities();
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
                  );
                }

                // Menampilkan pesan jika tidak ada aktivitas
                if (controller.activities.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => controller.loadRecentActivities(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: const Center(
                            child: Text(
                              'Tidak ada aktivitas ditemukan',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Kelompokkan aktivitas berdasarkan bulan
                final byMonth = controller.activitiesByMonth;
                final months = byMonth.keys.toList()
                  ..sort((a, b) {
                    // Sort from newest to oldest
                    final partsA = a.split(' ');
                    final partsB = b.split(' ');
                    final yearA = int.parse(partsA[1]);
                    final yearB = int.parse(partsB[1]);
                    if (yearA != yearB) return yearB.compareTo(yearA);

                    final indonesianMonths = [
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
                    final monthA = indonesianMonths.indexOf(partsA[0]);
                    final monthB = indonesianMonths.indexOf(partsB[0]);
                    return monthB.compareTo(monthA);
                  });

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 9, 24, 0),
                  child: RefreshIndicator(
                    onRefresh: () => controller.loadRecentActivities(),
                    child: Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount:
                              months.length + 1, // +1 for loading indicator
                          itemBuilder: (context, index) {
                            if (index < months.length) {
                              final month = months[index];
                              return _buildMonthSection(month, byMonth[month]!);
                            } else {
                              // Loading indicator at the bottom
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
                              return const SizedBox(
                                  height:
                                      20); // Bottom padding when no more data
                            }
                          },
                        ),

                        // Overlay loading indicator saat memuat lebih banyak data
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
          ),
          // Tampilkan pagination info jika ada
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
                    style: const TextStyle(
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
    );
  }
}
