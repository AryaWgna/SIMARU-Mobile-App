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
            style: GoogleFonts.inter(
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
          _buildStatusMessage(activity),
        ],
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
              fontSize: 14,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: '$employeeId mengubah status dari '),
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
      style: GoogleFonts.inter(
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          badgeText,
          style: GoogleFonts.inter(
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
}
