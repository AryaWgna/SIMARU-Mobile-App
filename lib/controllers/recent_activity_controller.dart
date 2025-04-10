import 'package:flutter/material.dart';
import '../models/history_model.dart';
import '../core/config/api_config.dart';
import 'dart:convert';
import 'auth_controller.dart';

class RecentActivityController extends ChangeNotifier {
  List<HistoryModel> _activities = [];
  Map<String, List<HistoryModel>> _activitiesByMonth = {};
  HistoryPagination? _pagination;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;

  List<HistoryModel> get activities => _activities;
  Map<String, List<HistoryModel>> get activitiesByMonth => _activitiesByMonth;
  HistoryPagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;

  Future<void> loadRecentActivities({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      _isLoading = true;
      if (refresh) _error = null;
      notifyListeners();

      final response = await ApiService.get(
        '/asset-histories/activities/user/1?page=$_currentPage',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == true) {
          final List<dynamic> historiesJson = jsonResponse['data']['histories'];
          final newActivities =
              historiesJson.map((json) => HistoryModel.fromJson(json)).toList();

          if (refresh) {
            _activities = newActivities;
          } else {
            _activities.addAll(newActivities);
          }

          _pagination =
              HistoryPagination.fromJson(jsonResponse['data']['pagination']);
          _hasMoreData = _pagination!.hasNext;

          if (_hasMoreData) _currentPage++;

          // Group activities by month
          _groupActivitiesByMonth();
        } else {
          _error = jsonResponse['message'] ?? 'Failed to load activities';
        }
      } else {
        _error = 'Failed to load activities. Status: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreActivities() async {
    if (!_isLoading && _hasMoreData) {
      await loadRecentActivities(refresh: false);
    }
  }

  void _groupActivitiesByMonth() {
    _activitiesByMonth = {};

    for (var activity in _activities) {
      final monthYear = activity.monthYearString;

      if (!_activitiesByMonth.containsKey(monthYear)) {
        _activitiesByMonth[monthYear] = [];
      }

      _activitiesByMonth[monthYear]!.add(activity);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
