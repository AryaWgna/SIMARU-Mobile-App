import 'package:flutter/material.dart';
import '../models/recent_activity.dart';
import '../services/recent_activity_service.dart';

class RecentActivityController extends ChangeNotifier {
  final RecentActivityService _service = RecentActivityService();
  List<RecentActivity> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<RecentActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecentActivities() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _activities = await _service.getRecentActivities();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
