import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../models/notification_types.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/notification_badge_controller.dart';
import '../../widgets/custom_app_bar.dart';
import 'notification_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  late NotificationController _notificationController;

  @override
  void initState() {
    super.initState();
    _notificationController =
        Provider.of<NotificationController>(context, listen: false);
    _loadNotifications();

    // Menambahkan listener untuk scroll pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _notificationController.hasMoreData) {
        _loadMoreNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat notifikasi pertama kali
  Future<void> _loadNotifications() async {
    await _notificationController.loadNotifications(refresh: true);

    // Perbarui jumlah notifikasi yang belum dibaca
    final badgeController =
        Provider.of<NotificationBadgeController>(context, listen: false);
    badgeController.loadUnreadNotificationCount(context: context);
  }

  // Fungsi untuk memuat notifikasi tambahan (pagination)
  Future<void> _loadMoreNotifications() async {
    await _notificationController.loadMoreNotifications();
  }

  // Tandai semua notifikasi sebagai telah dibaca
  Future<void> _markAllAsRead() async {
    final success = await _notificationController.markAllAsRead(context);

    if (success) {
      // Perbarui jumlah notifikasi yang belum dibaca
      final badgeController =
          Provider.of<NotificationBadgeController>(context, listen: false);
      badgeController.loadUnreadNotificationCount(context: context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi ditandai sebagai telah dibaca'),
          backgroundColor: Color(0xFF213268),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menandai semua notifikasi sebagai telah dibaca'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(builder: (context, controller, _) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: AppBar(
            backgroundColor: const Color(0xFF213268),
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            title: const Text(
              'Notifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              if (controller.notifications.isNotEmpty &&
                  controller.notifications.any((n) => !n.isRead))
                IconButton(
                  icon: const Icon(Icons.done_all, color: Colors.white),
                  tooltip: 'Tandai semua telah dibaca',
                  onPressed: _markAllAsRead,
                ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadNotifications,
          color: const Color(0xFF213268),
          child: controller.isLoading && controller.notifications.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF213268),
                  ),
                )
              : controller.error != null && controller.notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            controller.error!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF213268),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : controller.notifications.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Tidak ada notifikasi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Anda belum memiliki notifikasi apapun',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          itemCount: controller.notifications.length +
                              (controller.hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == controller.notifications.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF213268),
                                  ),
                                ),
                              );
                            }

                            final notification =
                                controller.notifications[index];
                            final notificationType =
                                NotificationTypeExtension.fromString(
                                    notification.type);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _buildNotificationCard(
                                  controller, notification, notificationType),
                            );
                          },
                        ),
        ),
      );
    });
  }

  // Widget untuk kartu notifikasi
  Widget _buildNotificationCard(NotificationController controller,
      NotificationModel notification, NotificationType notificationType) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: notification.isRead
              ? Colors.transparent
              : notificationType.color.withOpacity(0.5),
          width: notification.isRead ? 0 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          // Langsung tandai sebagai dibaca saat diklik
          if (!notification.isRead) {
            final result = await controller.markAsRead(notification.id);

            if (result != null && result['success'] == true) {
              // Perbarui jumlah notifikasi yang belum dibaca
              final badgeController = Provider.of<NotificationBadgeController>(
                  context,
                  listen: false);
              badgeController.loadUnreadNotificationCount(context: context);
            }
          }

          // Navigasi ke halaman detail notifikasi
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NotificationDetailScreen(notification: notification),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: notification.isRead
                ? Colors.white
                : notificationType.color.withOpacity(0.05),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: notificationType.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notificationType.icon,
                  color: notificationType.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul dan waktu
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: const Color(0xFF213268),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          controller.formatDate(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Pesan
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Kode aset jika ada
                    if (notification.assetCode != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Aset: ${notification.assetCode}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Indikator belum dibaca
              if (!notification.isRead)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: BoxDecoration(
                    color: notificationType.color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
