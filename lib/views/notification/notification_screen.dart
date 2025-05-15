import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/notification_model.dart';
import '../../models/notification_types.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'notification_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isLoading = true;
  List<NotificationModel> notifications = [];
  String? errorMessage;
  bool hasMoreData = false;
  int currentPage = 1;
  final int limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // Menambahkan listener untuk scroll pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          hasMoreData) {
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
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentPage = 1;
    });

    try {
      final result = await NotificationService.getNotifications(
        context: context,
        page: 1,
        limit: limit,
      );

      final notifs = result['notifications'] as List<NotificationModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      setState(() {
        notifications = notifs;
        isLoading = false;
        hasMoreData = pagination['has_next'] == true;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat notifikasi: $e';
        isLoading = false;
      });
    }
  }

  // Fungsi untuk memuat notifikasi tambahan (pagination)
  Future<void> _loadMoreNotifications() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final nextPage = currentPage + 1;
      final result = await NotificationService.getNotifications(
        context: context,
        page: nextPage,
        limit: limit,
      );

      final moreNotifs = result['notifications'] as List<NotificationModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      if (moreNotifs.isNotEmpty) {
        setState(() {
          notifications.addAll(moreNotifs);
          currentPage = nextPage;
          hasMoreData = pagination['has_next'] == true;
        });
      } else {
        setState(() {
          hasMoreData = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat notifikasi tambahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk memformat tanggal
  String _formatDate(DateTime date) {
    // Konversi UTC ke waktu lokal Indonesia (GMT+7)
    final localDate = date.add(const Duration(hours: 7));

    // Jika hari ini
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDay = DateTime(localDate.year, localDate.month, localDate.day);

    if (localDay.isAtSameMomentAs(today)) {
      return 'Hari ini, ${DateFormat('HH:mm').format(localDate)}';
    }

    // Jika kemarin
    final yesterday = today.subtract(const Duration(days: 1));
    if (localDay.isAtSameMomentAs(yesterday)) {
      return 'Kemarin, ${DateFormat('HH:mm').format(localDate)}';
    }

    // Format lainnya (dalam minggu ini)
    final weekAgo = today.subtract(const Duration(days: 7));
    if (localDay.isAfter(weekAgo)) {
      return DateFormat('EEEE, HH:mm', 'id_ID').format(localDate);
    }

    // Format default untuk tanggal lebih lama
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(localDate);
  }

  // Tandai semua notifikasi sebagai telah dibaca
  Future<void> _markAllAsRead() async {
    try {
      final success = await NotificationService.markAllAsRead(context: context);

      if (success) {
        setState(() {
          // Perbarui status notifikasi dalam daftar
          for (var i = 0; i < notifications.length; i++) {
            final notification = notifications[i];
            if (!notification.isRead) {
              final updated = NotificationModel(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                createdAt: notification.createdAt,
                isRead: true,
                readAt: DateTime.now(),
                type: notification.type,
                assetCode: notification.assetCode,
                assetId: notification.assetId,
                imageUrl: notification.imageUrl,
              );
              notifications[i] = updated;
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sebagai telah dibaca'),
            backgroundColor: Color(0xFF213268),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Gagal menandai semua notifikasi sebagai telah dibaca'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: const Color(0xFF213268),
        child: isLoading && notifications.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF213268),
                ),
              )
            : errorMessage != null && notifications.isEmpty
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
                          errorMessage!,
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
                : notifications.isEmpty
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
                        itemCount: notifications.length + (hasMoreData ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == notifications.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF213268),
                                ),
                              ),
                            );
                          }

                          final notification = notifications[index];
                          final notificationType =
                              NotificationTypeExtension.fromString(
                                  notification.type);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildNotificationCard(
                                notification, notificationType),
                          );
                        },
                      ),
      ),
    );
  }

  // Widget untuk kartu notifikasi
  Widget _buildNotificationCard(
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
            final result = await NotificationService.markAsRead(notification.id,
                context: context);

            if (result != null && result['success'] == true) {
              // Perbarui status notifikasi di UI dengan data dari API
              setState(() {
                final index =
                    notifications.indexWhere((n) => n.id == notification.id);
                if (index != -1) {
                  // Gunakan waktu dari API jika tersedia
                  DateTime readAt;
                  if (result['read_at'] != null) {
                    try {
                      readAt = DateTime.parse(result['read_at'].toString());
                    } catch (e) {
                      readAt = DateTime.now();
                      debugPrint('Error parsing read_at time: $e');
                    }
                  } else {
                    readAt = DateTime.now();
                  }

                  final updated = NotificationModel(
                    id: notification.id,
                    title: notification.title,
                    message: notification.message,
                    createdAt: notification.createdAt,
                    isRead: true,
                    readAt: readAt,
                    type: notification.type,
                    assetCode: notification.assetCode,
                    assetId: notification.assetId,
                    imageUrl: notification.imageUrl,
                  );
                  notifications[index] = updated;

                  // Perbarui jumlah notifikasi yang belum dibaca
                  final unreadCount =
                      notifications.where((n) => !n.isRead).length;
                  notificationCountController.add(unreadCount);
                }
              });
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
                          _formatDate(notification.createdAt),
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
