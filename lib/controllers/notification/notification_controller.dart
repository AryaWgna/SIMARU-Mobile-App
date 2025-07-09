import 'package:flutter/material.dart';
import '../../models/notification/notification_model.dart';
import '../../services/notification/notification_service.dart';
import '../auth/auth_controller.dart';
import 'package:intl/intl.dart';
import '../../utils/logger_util.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  Map<String, dynamic>? _pagination;
  bool _isLoading = false;
  String? _error;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;
  String _sort = 'date_desc'; // Default sort
  bool? _isRead; // Filter for read/unread notifications
  String? _search; // Search term

  // Getters
  List<NotificationModel> get notifications => _notifications;
  Map<String, dynamic>? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  String get sort => _sort;
  bool? get isRead => _isRead;
  String? get search => _search;

  // Setters for filters
  set sort(String value) {
    if (_sort != value) {
      _sort = value;
      loadNotifications(refresh: true);
    }
  }

  set isRead(bool? value) {
    if (_isRead != value) {
      _isRead = value;
      loadNotifications(refresh: true);
    }
  }

  set search(String? value) {
    if (_search != value) {
      _search = value;
      loadNotifications(refresh: true);
    }
  }

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('NotificationController loading state set to: $_isLoading');
    }
  }

  // Format tanggal lengkap
  String formatDateTime(DateTime dateTime) {
    // Konversi UTC ke waktu lokal perangkat
    final localDateTime = dateTime.toLocal();
    return DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID')
        .format(localDateTime);
  }

  // Format tanggal untuk waktu dibaca
  String formatReadDateTime(DateTime dateTime) {
    // Konversi UTC ke waktu lokal perangkat
    final localDateTime = dateTime.toLocal();

    // Format lengkap dalam bahasa Indonesia tanpa "WIB"
    return '${DateFormat('EEEE', 'id_ID').format(localDateTime)}, ${localDateTime.day} ${_getIndonesianMonth(localDateTime.month)} ${localDateTime.year} pukul ${DateFormat('HH:mm', 'id_ID').format(localDateTime)}';
  }

  // Helper untuk mendapatkan nama bulan dalam bahasa Indonesia
  String _getIndonesianMonth(int month) {
    const months = [
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
    return months[month - 1];
  }

  // Format tanggal untuk daftar notifikasi
  String formatDate(DateTime date) {
    // Konversi UTC ke waktu lokal perangkat
    final localDate = date.toLocal();

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

  // Load notifications
  Future<void> loadNotifications({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get employee number for filtering notifications
      final employeeNumber = await ApiService.getEmployeeNumber();
      LoggerUtil.d('Loading notifications for employee: $employeeNumber');
      LoggerUtil.d(
          'Loading with page: $_currentPage, isRead: $_isRead, search: $_search');

      final result = await NotificationService.getNotifications(
        page: _currentPage,
        limit: _limit,
        sort: _sort,
        isRead: _isRead,
        search: _search,
      );

      LoggerUtil.d(
          'Received notifications response with status: ${result['message']}');

      if (refresh) {
        _notifications = result['notifications'];
        LoggerUtil.d(
            'Refreshed notifications, count: ${_notifications.length}');
      } else {
        _notifications.addAll(result['notifications']);
        LoggerUtil.d(
            'Added more notifications, total count: ${_notifications.length}');
      }

      _pagination = result['pagination'];
      LoggerUtil.d('Pagination info: $_pagination');

      // Update hasMoreData berdasarkan pagination
      if (_pagination != null) {
        if (_pagination!.containsKey('has_next')) {
          _hasMoreData = _pagination!['has_next'];
        } else if (_pagination!.containsKey('last_page') &&
            _pagination!.containsKey('current_page')) {
          _hasMoreData =
              _pagination!['current_page'] < _pagination!['last_page'];
        } else {
          _hasMoreData = false;
        }

        LoggerUtil.d('Has more data: $_hasMoreData');
        if (_hasMoreData) {
          _currentPage++;
          LoggerUtil.d('Next page will be: $_currentPage');
        }
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error loading notifications', e, StackTrace.current);
    } finally {
      _isLoading = false;
      notifyListeners();
      LoggerUtil.d(
          'NotificationController: Finished loading notifications, _isLoading set to false');
    }
  }

  // Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (_isLoading || !_hasMoreData) {
      LoggerUtil.d(
          'loadMoreNotifications: Skipping - already loading or no more data');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Get employee number for filtering notifications
      final employeeNumber = await ApiService.getEmployeeNumber();
      LoggerUtil.d('Loading more notifications for employee: $employeeNumber');
      LoggerUtil.d(
          'Loading more with page: $_currentPage, isRead: $_isRead, search: $_search');

      final result = await NotificationService.getNotifications(
        page: _currentPage,
        limit: _limit,
        sort: _sort,
        isRead: _isRead,
        search: _search,
      );

      final newNotifications =
          result['notifications'] as List<NotificationModel>;

      LoggerUtil.d('Received ${newNotifications.length} more notifications');

      if (newNotifications.isNotEmpty) {
        _notifications.addAll(newNotifications);

        _pagination = result['pagination'];
        if (_pagination != null) {
          LoggerUtil.d('Pagination info: $_pagination');

          if (_pagination!.containsKey('has_next')) {
            _hasMoreData = _pagination!['has_next'];
          } else if (_pagination!.containsKey('last_page') &&
              _pagination!.containsKey('current_page')) {
            _hasMoreData =
                _pagination!['current_page'] < _pagination!['last_page'];
          } else {
            _hasMoreData = false;
          }

          if (_hasMoreData) {
            _currentPage++;
            LoggerUtil.d('Next page will be: $_currentPage');
          } else {
            LoggerUtil.d('No more pages available');
          }
        } else {
          _hasMoreData = false;
          LoggerUtil.d('No pagination info, setting hasMoreData to false');
        }
      } else {
        _hasMoreData = false;
        LoggerUtil.d(
            'No new notifications received, setting hasMoreData to false');
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error loading more notifications', e, StackTrace.current);
    } finally {
      _isLoading = false;
      notifyListeners();
      LoggerUtil.d(
          'NotificationController: Finished loading more notifications, _isLoading set to false');
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>?> markAsRead(int notificationId) async {
    try {
      LoggerUtil.d('Marking notification $notificationId as read');
      final result = await NotificationService.markAsRead(notificationId);
      LoggerUtil.d('Mark as read result: $result');

      if (result != null && result['success'] == true) {
        // Find the notification in the list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          // Create a new instance with updated read status
          DateTime readAt;
          if (result['read_at'] != null) {
            try {
              readAt = DateTime.parse(result['read_at'].toString());
            } catch (e) {
              readAt = DateTime.now();
              LoggerUtil.w('Error parsing read_at time', e);
            }
          } else {
            readAt = DateTime.now();
          }

          final updatedNotification = NotificationModel(
            id: _notifications[index].id,
            title: _notifications[index].title,
            message: _notifications[index].message,
            createdAt: _notifications[index].createdAt,
            isRead: true,
            readAt: readAt,
            type: _notifications[index].type,
            assetCode: _notifications[index].assetCode,
            assetId: _notifications[index].assetId,
            imageUrl: _notifications[index].imageUrl,
            employeeNumber: _notifications[index].employeeNumber,
          );

          // Handle the notification based on current filter
          if (_isRead == false) {
            // We're in the unread filter, remove this notification
            _notifications.removeAt(index);
            LoggerUtil.d(
                'Removed notification from unread list after marking as read');
          } else if (_isRead == null) {
            // We're in the "All" filter, update the notification
            _notifications[index] = updatedNotification;
            LoggerUtil.d('Updated notification in all notifications list');
          } else if (_isRead == true) {
            // We're in the read filter, this notification should be here now
            // Do nothing as it will appear when the user switches tabs
            LoggerUtil.d(
                'Notification will appear in read tab when user switches');
          }

          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error marking notification as read', e, StackTrace.current);
      return null;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead(BuildContext? context) async {
    try {
      final result = await NotificationService.markAllAsRead(context: context);

      if (result['success'] == true) {
        // Update all notifications in the list as read
        for (var i = 0; i < _notifications.length; i++) {
          if (!_notifications[i].isRead) {
            final updatedNotification = NotificationModel(
              id: _notifications[i].id,
              title: _notifications[i].title,
              message: _notifications[i].message,
              createdAt: _notifications[i].createdAt,
              isRead: true,
              readAt: DateTime.now(),
              type: _notifications[i].type,
              assetCode: _notifications[i].assetCode,
              assetId: _notifications[i].assetId,
              imageUrl: _notifications[i].imageUrl,
            );

            _notifications[i] = updatedNotification;
          }
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e(
          'Error marking all notifications as read', e, StackTrace.current);
      return false;
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      return await NotificationService.getUnreadCount();
    } catch (e) {
      LoggerUtil.e('Error getting unread count', e, StackTrace.current);
      return 0;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset controller state
  void reset() {
    _notifications = [];
    _pagination = null;
    _error = null;
    _currentPage = 1;
    _hasMoreData = true;
    _sort = 'date_desc';
    _isRead = null;
    _search = null;
    notifyListeners();
  }

  // Filter notifications by read status
  void filterByReadStatus(bool? isRead) {
    LoggerUtil.d('Filtering notifications by read status: $isRead');

    // If we're already on this filter, do nothing
    if (_isRead == isRead) {
      LoggerUtil.d('Already on this filter, doing nothing');
      return;
    }

    // Set the filter value
    _isRead = isRead;

    // Reset pagination
    _currentPage = 1;
    _hasMoreData = true;

    // Clear current notifications
    _notifications = [];
    _pagination = null;

    // Notify listeners to update UI immediately
    notifyListeners();

    // No need to set loading here as loadNotifications will handle it
    // Load notifications with the new filter will be called from the UI
    LoggerUtil.d(
        'Filter updated to isRead=$isRead, UI should refresh data now');
  }

  // Set sorting
  void setSorting(String sort) {
    this.sort = sort;
  }

  // Get pagination info as formatted string
  String getPaginationInfo() {
    if (_pagination == null) return '';

    final currentPage = _pagination!['current_page'] ?? 1;
    final lastPage = _pagination!['last_page'] ?? 1;
    final total = _pagination!['total'] ?? 0;

    return 'Halaman $currentPage dari $lastPage ($total item)';
  }
}
