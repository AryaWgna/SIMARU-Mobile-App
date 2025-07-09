import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../controllers/dashboard/recent_activity_controller.dart';
import '../models/dashboard/history_model.dart';
import '../views/pages/history_screen.dart';
import '../utils/logger_util.dart';

class TodayActivitiesWidget extends StatefulWidget {
  const TodayActivitiesWidget({super.key});

  @override
  State<TodayActivitiesWidget> createState() => _TodayActivitiesWidgetState();
}

class _TodayActivitiesWidgetState extends State<TodayActivitiesWidget> {
  @override
  void initState() {
    super.initState();
    // Load activities when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
    });
  }

  // Method to load activities for the current user
  Future<void> _loadActivities() async {
    try {
      final controller = context.read<RecentActivityController>();
      await controller.loadRecentActivities();
    } catch (e) {
      LoggerUtil.e('Error loading activities in TodayActivitiesWidget', e,
          StackTrace.current);
    }
  }

  void _navigateToHistoryScreen(BuildContext context) {
    // Reset controller state sebelum navigasi
    final controller = context.read<RecentActivityController>();
    controller.resetState();
    controller.setLoading(true);

    // Navigasi ke history screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistoryScreen(),
      ),
    ).then((_) {
      // Load ulang data saat kembali ke home screen
      if (mounted) {
        LoggerUtil.d("Returned to home screen, reloading activities");
        controller.resetState();
        _loadActivities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecentActivityController>(
      builder: (context, controller, child) {
        final todayActivities = controller.getTodayActivities();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan ikon
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF213268),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aktivitas Hari Ini',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213268),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _navigateToHistoryScreen(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Konten aktivitas
              if (controller.isLoading)
                Skeletonizer(
                  enabled: true,
                  effect: ShimmerEffect(
                    baseColor: Colors.grey.shade300,
                    highlightColor: const Color(0xFFE5EFFF),
                  ),
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 60,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 140,
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
                  ),
                )
              else if (todayActivities.isEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada aktivitas hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      todayActivities.length > 3 ? 3 : todayActivities.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(todayActivities[index]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryItem(HistoryModel activity) {
    // Format the time in local timezone with 24-hour clock
    final formattedTime =
        DateFormat('HH:mm').format(activity.actionDate.toLocal());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activity.assetInfo.assetName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF213268),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.qr_code,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                activity.assetInfo.assetCode,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                formattedTime,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatusMessage(activity),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(HistoryModel activity) {
    // Get the current user's employee number from controller if available
    final controller =
        Provider.of<RecentActivityController>(context, listen: false);
    final currentEmployeeNumber = controller.employeeNumber;

    // Cek apakah pesan berisi perubahan status
    if (activity.message.contains('mengubah status dari')) {
      // Ekstrak status lama dan baru dari pesan
      final parts = activity.message.split(' ');
      String employeeId = parts[0];

      // If this activity matches the current user, highlight it differently
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
              fontSize: 14,
              color: Colors.black87,
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
            children: [
              TextSpan(
                text: '$employeeId mengubah status dari ',
                style: TextStyle(
                  color:
                      isCurrentUser ? const Color(0xFF213268) : Colors.black87,
                ),
              ),
              _buildStatusBadge(oldStatus),
              TextSpan(text: ' ke '),
              _buildStatusBadge(newStatus),
            ],
          ),
        );
      }
    }

    // Jika tidak berisi perubahan status, tampilkan pesan biasa
    return Text(
      activity.message,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  InlineSpan _buildStatusBadge(String status) {
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
            fontSize: 12,
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
      case 'checked':
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
        return "DIMUSNAHKAN";
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
        return const Color(0xFF5EA004);
      case 'PERBAIKAN':
        return const Color(0xFF0277BD);
      case 'DIPINJAM':
        return const Color(0xFFEF6C00);
      case 'DIMUSNAHKAN':
        return const Color(0xFF546E7A);
      case 'HILANG':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF616161);
    }
  }
}
