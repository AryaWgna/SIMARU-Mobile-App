import 'package:flutter/material.dart';
import '../models/history_model.dart';
import 'dart:convert';
import 'auth_controller.dart';

class RecentActivityController extends ChangeNotifier {
  List<HistoryModel> _activities = [];
  Map<String, List<HistoryModel>> _activitiesByMonth = {};
  HistoryPagination? _pagination;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _limit = 10;
  bool _isSuccess = false;
  ScrollController _scrollController = ScrollController();

  List<HistoryModel> get activities => _activities;
  Map<String, List<HistoryModel>> get activitiesByMonth => _activitiesByMonth;
  HistoryPagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  bool get isSuccess => _isSuccess;
  ScrollController get scrollController => _scrollController;

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      print('RecentActivityController loading state set to: $_isLoading');
    }
  }

  // Method untuk mengatur status loading more secara manual
  void setLoadingMore(bool loading) {
    if (_isLoadingMore != loading) {
      _isLoadingMore = loading;
      notifyListeners();
    }
  }

  // Method untuk initialize scroll controller
  void initScrollController() {
    if (_scrollController.hasClients) {
      _scrollController.dispose();
    }
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadRecentActivities({bool refresh = true}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      _isLoading = true;
      _error = null;
      _isSuccess = false;
      notifyListeners();

      final response = await ApiService.get(
        '/asset-histories/activities/user/1?limit=$_limit&page=$_currentPage',
      );

      print('Activity API response status code: ${response.statusCode}');
      print('Activity API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final dataSection = jsonResponse['data'];

          if (dataSection == null) {
            _error = 'Data section missing in response';
            _isLoading = false;
            notifyListeners();
            return;
          }

          final List<dynamic>? historiesJson = dataSection['histories'];
          if (historiesJson == null || historiesJson.isEmpty) {
            if (refresh) {
              _activities = [];
              _activitiesByMonth = {};
            }
            _hasMoreData = false;
            _isSuccess = true;
            _isLoading = false;
            notifyListeners();
            return;
          }

          final newActivities = historiesJson
              .where((json) => json != null)
              .map((json) => HistoryModel.fromJson(json))
              .toList();

          if (refresh) {
            _activities = newActivities;
          } else {
            _activities.addAll(newActivities);
          }

          if (dataSection['pagination'] != null) {
            final paginationData = dataSection['pagination'];
            _pagination = HistoryPagination.fromJson(paginationData);
            _hasMoreData = _pagination!.hasNext;

            if (_hasMoreData) _currentPage++;
          } else {
            _hasMoreData = false;
          }

          // Group activities by month
          _groupActivitiesByMonth();
          _isSuccess = true;
        } else {
          _error = jsonResponse['message'] ?? 'Failed to load activities';
        }
      } else {
        _error = 'Failed to load activities. Status: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      print('Exception in loadRecentActivities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreActivities() async {
    if (_isLoading || !_hasMoreData) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nextPage = _currentPage;
      final response = await ApiService.get(
        '/asset-histories/activities/user/1?limit=$_limit&page=$nextPage',
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final dataSection = jsonResponse['data'];

          if (dataSection == null) {
            _error = 'Data section missing in response';
            _isLoading = false;
            notifyListeners();
            return;
          }

          final List<dynamic>? historiesJson = dataSection['histories'];
          if (historiesJson == null || historiesJson.isEmpty) {
            _hasMoreData = false;
            _isLoading = false;
            notifyListeners();
            return;
          }

          final newActivities = historiesJson
              .where((json) => json != null)
              .map((json) => HistoryModel.fromJson(json))
              .toList();

          if (newActivities.isEmpty) {
            _hasMoreData = false;
            _isLoading = false;
            notifyListeners();
            return;
          }

          _activities.addAll(newActivities);

          if (dataSection['pagination'] != null) {
            final paginationData = dataSection['pagination'];
            _pagination = HistoryPagination.fromJson(paginationData);
            _hasMoreData = _pagination!.hasNext;
            _currentPage = nextPage + 1;
          } else {
            _hasMoreData = false;
          }

          // Update grouped activities
          _groupActivitiesByMonth();
        } else {
          _error = jsonResponse['message'] ?? 'Failed to load more activities';
        }
      } else {
        _error =
            'Failed to load more activities. Status: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading more data: ${e.toString()}';
      print('Exception in loadMoreActivities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _groupActivitiesByMonth() {
    _activitiesByMonth = {};

    for (var activity in _activities) {
      final monthYear = _getIndonesianMonthName(activity.actionDate);

      if (!_activitiesByMonth.containsKey(monthYear)) {
        _activitiesByMonth[monthYear] = [];
      }

      _activitiesByMonth[monthYear]!.add(activity);
    }
  }

  String _getIndonesianMonthName(DateTime date) {
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
    return '${months[date.month - 1]} ${date.year}';
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get today's activities only
  List<HistoryModel> getTodayActivities() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _activities.where((activity) {
      final activityDate = DateTime(
        activity.actionDate.year,
        activity.actionDate.month,
        activity.actionDate.day,
      );
      return activityDate.isAtSameMomentAs(today);
    }).toList();
  }

  void resetState() {
    _activities = [];
    _activitiesByMonth = {};
    _pagination = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMoreData = true;
    _isSuccess = false;
    notifyListeners();
  }
}
