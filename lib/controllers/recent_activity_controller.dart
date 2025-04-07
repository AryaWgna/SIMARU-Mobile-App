import 'package:flutter/material.dart';
import '../models/history_model.dart';
import '../core/config/api_config.dart';
import 'dart:convert';
import 'auth_controller.dart';

class RecentActivityController extends ChangeNotifier {
  List<HistoryModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  List<HistoryModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecentActivities() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current date in required format (dd-MM-yyyy)
      final now = DateTime.now();
      final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      
      final response = await ApiService.get(
        '/asset-histories/activities/user/1?date=$formattedDate',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == true) {
          final List<dynamic> historiesJson = jsonResponse['data']['histories'];
          _activities = historiesJson
              .map((json) => HistoryModel.fromJson(json))
              .toList();
        } else {
          _error = jsonResponse['message'] ?? 'Failed to load activities';
        }
      } else {
        _error = 'Failed to load activities';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
