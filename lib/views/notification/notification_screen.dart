import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/notification/notification_model.dart';
import '../../models/notification/notification_types.dart';
import '../../controllers/notification/notification_controller.dart';
import '../../controllers/notification/notification_badge_controller.dart';
import '../../controllers/auth/auth_controller.dart';
import 'notification_detail_screen.dart';
import '../../utils/logger_util.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  late NotificationController _notificationController;
  String? _employeeNumber;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _notificationController =
        Provider.of<NotificationController>(context, listen: false);

    // Reset state when entering notification screen
    _notificationController.reset();
    _loadNotifications();
    _loadEmployeeNumber();

    // Menambahkan listener untuk scroll pagination
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final loadThreshold = maxScroll * 0.8;

      LoggerUtil.d(
          "Scroll position: $currentScroll / $maxScroll (threshold: $loadThreshold)");

      if (currentScroll >= loadThreshold &&
          _notificationController.hasMoreData &&
          !_notificationController.isLoading &&
          !_isLoadingMore) {
        LoggerUtil.d(
            'Scroll reached 80% of maxScrollExtent, loading more notifications');
        _loadMoreNotifications();
      }
    });

    // Add listener for search
    _searchController.addListener(_onSearchChanged);
  }

  // Search debounce handler
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Pass search term to controller
      _notificationController.search =
          _searchController.text.isNotEmpty ? _searchController.text : null;

      // Reload notifications when search term changes
      _loadNotifications();
    });
  }

  // Load employee number for display
  Future<void> _loadEmployeeNumber() async {
    final employeeNumber = await ApiService.getEmployeeNumber();
    if (mounted) {
      setState(() {
        _employeeNumber = employeeNumber;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat notifikasi pertama kali
  Future<void> _loadNotifications() async {
    try {
      // Set loading state explicitly from the UI
      setState(() {
        _notificationController.setLoading(true);
      });

      await _notificationController.loadNotifications(refresh: true);

      // Perbarui jumlah notifikasi yang belum dibaca
      final badgeController =
          Provider.of<NotificationBadgeController>(context, listen: false);
      badgeController.loadUnreadNotificationCount(context: context);

      // Ensure loading state is explicitly set to false
      if (mounted) {
        setState(() {
          _notificationController.setLoading(false);
        });
      }
    } catch (e) {
      // Handle any exceptions
      LoggerUtil.e('Error loading notifications in UI', e, StackTrace.current);

      // Ensure loading state is reset even on error
      if (mounted) {
        setState(() {
          _notificationController.setLoading(false);
        });
      }
    }
  }

  // Fungsi untuk memuat notifikasi tambahan (pagination)
  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore ||
        _notificationController.isLoading ||
        !_notificationController.hasMoreData) {
      LoggerUtil.d(
          'Skipping loadMoreNotifications - already loading or no more data');
      return;
    }

    try {
      LoggerUtil.d('UI calling loadMoreNotifications');
      // Set loading state for pagination
      setState(() {
        _isLoadingMore = true;
      });

      await _notificationController.loadMoreNotifications();

      // Ensure loading is set to false
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      LoggerUtil.e(
          'Error loading more notifications in UI', e, StackTrace.current);

      // Reset loading state on error
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // Widget for empty notification message
  Widget _buildEmptyNotificationMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.notifications_off,
          size: 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Text(
          'Tidak ada notifikasi',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _employeeNumber != null
              ? 'Tidak ada notifikasi untuk karyawan $_employeeNumber'
              : 'Anda belum memiliki notifikasi apapun',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Widget untuk skeleton loading
  Widget _buildSkeletonNotificationItem() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon placeholder
            Container(
              width: 50,
              height: 50,
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
                  // Title and time row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Message placeholder
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Asset code placeholder
                  Container(
                    height: 12,
                    width: 120,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(builder: (context, controller, _) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF213268),
          elevation: 0,
          title: const Text(
            'Notifikasi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
        body: Column(
          children: [
            // Add header section similar to history screen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                _employeeNumber != null
                    ? 'Menampilkan notifikasi untuk Pegawai $_employeeNumber'
                    : 'Menampilkan semua notifikasi Anda',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF757575),
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari notifikasi...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                ),
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Semua', controller.isRead == null),
                  const SizedBox(width: 12),
                  _buildFilterChip('Belum Dibaca', controller.isRead == false),
                  const SizedBox(width: 12),
                  _buildFilterChip('Sudah Dibaca', controller.isRead == true),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotifications,
                color: const Color(0xFF213268),
                child: controller.isLoading && controller.notifications.isEmpty
                    ? Skeletonizer(
                        enabled: true,
                        effect: ShimmerEffect(
                          baseColor: Colors.grey.shade300,
                          highlightColor: const Color(0xFFE5EFFF),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return _buildSkeletonNotificationItem();
                            },
                          ),
                        ),
                      )
                    : controller.error != null &&
                            controller.notifications.isEmpty
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
                                    fontFamily: 'Poppins',
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
                            ? Center(
                                child: _buildEmptyNotificationMessage(),
                              )
                            : Stack(
                                children: [
                                  ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    itemCount: controller.notifications.length +
                                        1, // Always add 1 for the bottom indicator
                                    itemBuilder: (context, index) {
                                      // Show loading indicator or end message at the bottom
                                      if (index ==
                                          controller.notifications.length) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          alignment: Alignment.center,
                                          child: Column(
                                            children: [
                                              if (_isLoadingMore)
                                                const CircularProgressIndicator(
                                                  color: Color(0xFF213268),
                                                )
                                              else if (controller.hasMoreData)
                                                const Text(
                                                  'Scroll untuk memuat lebih banyak',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                )
                                              else
                                                const SizedBox(),
                                            ],
                                          ),
                                        );
                                      }

                                      final notification =
                                          controller.notifications[index];
                                      final notificationType =
                                          NotificationTypeExtension.fromString(
                                              notification.type);

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: _buildNotificationCard(
                                            controller,
                                            notification,
                                            notificationType),
                                      );
                                    },
                                  ),

                                  // Persistent pagination indicator at the bottom
                                  if (controller.pagination != null)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        margin: const EdgeInsets.only(
                                            top:
                                                40), // Add margin to avoid covering the "Tidak ada data lagi" text
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                              color: const Color(0xFFCAC4D0)),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          controller.getPaginationInfo(),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF213268),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Widget untuk filter chip
  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: isSelected ? const Color(0xFF213268) : Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          LoggerUtil.d('Filter chip tapped: $label');
          if (label == 'Semua') {
            _notificationController.filterByReadStatus(null);
          } else if (label == 'Belum Dibaca') {
            _notificationController.filterByReadStatus(false);
          } else if (label == 'Sudah Dibaca') {
            _notificationController.filterByReadStatus(true);
          }

          // Force reload of notifications immediately after filter change
          _loadNotifications();
        },
        borderRadius: BorderRadius.circular(25),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Widget untuk kartu notifikasi
  Widget _buildNotificationCard(NotificationController controller,
      NotificationModel notification, NotificationType notificationType) {
    return Card(
      elevation: notification.isRead ? 1 : 2,
      margin: const EdgeInsets.only(bottom: 8),
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

              // Force refresh the notifications list instead of trying to update the model directly
              _loadNotifications();
            }
          }

          // Navigasi ke halaman detail notifikasi
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NotificationDetailScreen(notification: notification),
            ),
          ).then((_) {
            // Refresh after returning from details
            if (mounted) {
              _loadNotifications();
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: notification.isRead
                ? Colors.white
                : notificationType.color.withOpacity(0.05),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  color: notification.isRead
                                      ? Colors.black87
                                      : const Color(0xFF213268),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              controller.formatDate(notification.createdAt),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
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
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.black
                                .withOpacity(notification.isRead ? 0.7 : 0.8),
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
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
                                fontFamily: 'Poppins',
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

              // Status read indicator - always show for read notifications
              if (notification.isRead && notification.readAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 62),
                  child: Text(
                    'Dibaca: ${controller.formatDate(notification.readAt!)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
