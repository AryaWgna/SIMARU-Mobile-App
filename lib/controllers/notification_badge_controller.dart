import 'package:flutter/material.dart';
import 'dart:async';
import '../services/notification_service.dart';
import '../utils/logger_util.dart';

class NotificationBadgeController extends ChangeNotifier {
  int _notificationCount = 0;
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Getters
  int get notificationCount => _notificationCount;
  bool get isLoading => _isLoading;

  NotificationBadgeController() {
    // Muat jumlah notifikasi saat controller dibuat
    loadUnreadNotificationCount();

    // Refresh jumlah notifikasi setiap 30 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadUnreadNotificationCount();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadUnreadNotificationCount({BuildContext? context}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final count = await NotificationService.getUnreadCount(context: context);

      _notificationCount = count;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LoggerUtil.e('Error loading notification count', e, StackTrace.current);
      _isLoading = false;
      notifyListeners();
    }
  }
}
