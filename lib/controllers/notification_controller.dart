import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  Map<String, dynamic>? _pagination;
  bool _isLoading = false;
  String? _error;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _limit = 10;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  Map<String, dynamic>? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      print('NotificationController loading state set to: $_isLoading');
    }
  }

  // Format tanggal lengkap
  String formatDateTime(DateTime dateTime) {
    // Konversi UTC ke waktu lokal Indonesia (GMT+7)
    final localDateTime = dateTime.add(const Duration(hours: 7));
    return DateFormat('EEEE, d MMMM yyyy - HH:mm', 'id_ID')
        .format(localDateTime);
  }

  // Format tanggal untuk waktu dibaca
  String formatReadDateTime(DateTime dateTime) {
    // Konversi UTC ke waktu lokal Indonesia (GMT+7)
    final localDateTime = dateTime.add(const Duration(hours: 7));

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

      final result = await NotificationService.getNotifications(
        page: _currentPage,
        limit: _limit,
      );

      if (refresh) {
        _notifications = result['notifications'];
      } else {
        _notifications.addAll(result['notifications']);
      }

      _pagination = result['pagination'];

      // Update hasMoreData berdasarkan pagination
      if (_pagination != null && _pagination!.containsKey('has_next')) {
        _hasMoreData = _pagination!['has_next'];
        if (_hasMoreData) _currentPage++;
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (_isLoading || !_hasMoreData) return;

    try {
      _isLoading = true;
      notifyListeners();

      final nextPage = _currentPage;
      final result = await NotificationService.getNotifications(
        page: nextPage,
        limit: _limit,
      );

      final newNotifications =
          result['notifications'] as List<NotificationModel>;

      if (newNotifications.isNotEmpty) {
        _notifications.addAll(newNotifications);

        _pagination = result['pagination'];
        if (_pagination != null && _pagination!.containsKey('has_next')) {
          _hasMoreData = _pagination!['has_next'];
          if (_hasMoreData) _currentPage++;
        } else {
          _hasMoreData = false;
        }
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading more notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>?> markAsRead(int notificationId) async {
    try {
      final result = await NotificationService.markAsRead(notificationId);

      if (result != null && result['success'] == true) {
        // Update the notification in the list
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          // Create a new instance with updated read status
          DateTime readAt;
          if (result['read_at'] != null) {
            try {
              readAt = DateTime.parse(result['read_at'].toString());
            } catch (e) {
              readAt = DateTime.now();
              print('Error parsing read_at time: $e');
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
          );

          _notifications[index] = updatedNotification;
          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      _error = e.toString();
      print('Error marking notification as read: $e');
      return null;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead(BuildContext? context) async {
    try {
      final success = await NotificationService.markAllAsRead(context: context);

      if (success) {
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
      }

      return success;
    } catch (e) {
      _error = e.toString();
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      return await NotificationService.getUnreadCount();
    } catch (e) {
      print('Error getting unread count: $e');
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
    notifyListeners();
  }
}
