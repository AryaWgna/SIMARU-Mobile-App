import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/recent_activity_controller.dart';
import '../models/history_model.dart';
import '../views/pages/history_screen.dart';

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
      context.read<RecentActivityController>().loadRecentActivities();
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
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aktivitas Hari Ini',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213268),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Konten aktivitas
              if (controller.isLoading && todayActivities.isEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
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
                          style: GoogleFonts.inter(
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
                      const SizedBox(height: 8),
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
    final formattedTime = DateFormat('HH:mm').format(activity.actionDate);

    // Tentukan status badge berdasarkan status
    String badgeText = activity.newStatus;
    Color badgeColor = _getStatusColor(activity.newStatus);

    // Cek apakah ada status khusus seperti "lost" atau lainnya
    if (activity.message.toLowerCase().contains("hilang")) {
      badgeText = "Lost";
      badgeColor = Colors.red[700]!;
    } else if (activity.message.toLowerCase().contains("rusak")) {
      badgeText = "Damaged";
      badgeColor = Colors.orange[700]!;
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activity.assetInfo.assetName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF213268),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.qr_code,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                activity.assetInfo.assetCode,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                formattedTime,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activity.message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
}
