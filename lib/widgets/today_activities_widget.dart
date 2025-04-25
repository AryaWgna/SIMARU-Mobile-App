import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/recent_activity_controller.dart';
import '../models/history_model.dart';
import '../views/pages/history_screen.dart';

class TodayActivitiesWidget extends StatefulWidget {
  const TodayActivitiesWidget({Key? key}) : super(key: key);

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
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aktivitas Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF213268),
                      ),
                    ),
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
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isLoading && todayActivities.isEmpty)
                Container(
                  color: Colors.white,
                  height: 200,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (todayActivities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                  height: 200,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      'Tidak ada aktivitas hari ini',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount:
                        todayActivities.length > 3 ? 3 : todayActivities.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(todayActivities[index]);
                    },
                  ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF25B1FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.assetInfo.assetName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF213268),
                  ),
                ),
                const SizedBox(height: 4),
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
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
}
