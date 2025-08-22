import 'package:flutter/material.dart';
import '../../models/dashboard/history_model.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../auth/auth_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../utils/logger_util.dart';

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
  final _secureStorage = const FlutterSecureStorage();
  String? _userId;
  String? _employeeNumber;
  String? _employeeName;

  List<HistoryModel> get activities => _activities;
  Map<String, List<HistoryModel>> get activitiesByMonth => _activitiesByMonth;
  HistoryPagination? get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  bool get isSuccess => _isSuccess;
  ScrollController get scrollController => _scrollController;
  String? get employeeNumber => _employeeNumber;
  String? get employeeName => _employeeName;

  // Method to get the current user ID and employee number
  Future<Map<String, String?>> _getCurrentUserInfo() async {
    if (_userId != null && _employeeNumber != null && _employeeName != null) {
      return {
        'userId': _userId,
        'employeeNumber': _employeeNumber,
        'employeeName': _employeeName,
      };
    }

    try {
      // Try to get the user ID and employee number from secure storage
      _userId = await _secureStorage.read(key: 'user_id');
      _employeeNumber = await ApiService.getEmployeeNumber();
      _employeeName = await ApiService.getEmployeeName();

      LoggerUtil.d(
          'Retrieved user info from storage: ID: $_userId, Employee Number: $_employeeNumber, Employee Name: $_employeeName');

      if (_userId == null || _employeeNumber == null) {
        // Try to get the information from the JWT token
        final token = await ApiService.getAccessToken();
        if (token != null) {
          try {
            // Decode token to extract user information
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized =
                  payload.replaceAll('-', '+').replaceAll('_', '/');
              final padded = normalized.padRight(
                  normalized.length + (4 - normalized.length % 4) % 4, '=');
              final decoded = utf8.decode(base64Url.decode(padded));
              final decodedPayload = json.decode(decoded);

              if (decodedPayload['user_id'] != null) {
                _userId = decodedPayload['user_id'].toString();
                await _secureStorage.write(key: 'user_id', value: _userId);
                LoggerUtil.d('Saved user_id from token to storage: $_userId');
              }

              if (decodedPayload['employee_number'] != null) {
                _employeeNumber = decodedPayload['employee_number'].toString();
                await _secureStorage.write(
                    key: 'employee_number', value: _employeeNumber);
                LoggerUtil.d(
                    'Saved employee_number from token to storage: $_employeeNumber');
              }
            }
          } catch (e) {
            LoggerUtil.e('Error decoding token', e, StackTrace.current);
          }
        }
      }

      return {
        'userId': _userId,
        'employeeNumber': _employeeNumber,
        'employeeName': _employeeName,
      };
    } catch (e) {
      LoggerUtil.e('Error retrieving user info', e, StackTrace.current);
      return {
        'userId': null,
        'employeeNumber': null,
        'employeeName': null,
      };
    }
  }

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d(
          'RecentActivityController loading state set to: $_isLoading');
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
      if (!_isLoading) {
        _isLoading = true;
        _error = null;
        _isSuccess = false;
        notifyListeners();
      }

      // Get the current user information
      final userInfo = await _getCurrentUserInfo();
      final userId = userInfo['userId'];

      if (userId == null) {
        throw Exception('User ID tidak ditemukan. Silakan login kembali.');
      }

      LoggerUtil.d(
          'Loading activities for user $userId (${userInfo['employeeNumber']} - ${userInfo['employeeName']}) - page $_currentPage, refresh: $refresh');
      final response = await ApiService.get(
        '/asset-histories/activities/user/$userId?limit=$_limit&page=$_currentPage',
      );

      LoggerUtil.d('Activity API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final dataSection = jsonResponse['data'];

          if (dataSection == null) {
            LoggerUtil.w('Data section missing in response');
            _error = 'Data section missing in response';
            _isLoading = false;
            notifyListeners();
            return;
          }

          final List<dynamic>? historiesJson = dataSection['histories'];
          if (historiesJson == null || historiesJson.isEmpty) {
            LoggerUtil.i('No activities found');
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

          LoggerUtil.i('Loaded ${newActivities.length} activities');

          if (refresh) {
            _activities = newActivities;
          } else {
            _activities.addAll(newActivities);
          }

          if (dataSection['pagination'] != null) {
            final paginationData = dataSection['pagination'];
            _pagination = HistoryPagination.fromJson(paginationData);

            // Update hasMoreData based on pagination info
            _hasMoreData = _pagination!.currentPage < _pagination!.totalPages;

            LoggerUtil.d(
                'Pagination info: Page ${_pagination!.currentPage}/${_pagination!.totalPages}, hasNext: $_hasMoreData');

            if (_hasMoreData) {
              _currentPage++;
              LoggerUtil.d('Next page will be $_currentPage');
            }
          } else {
            LoggerUtil.w('No pagination info in response');
            _hasMoreData = false;
          }

          // Group activities by month
          _groupActivitiesByMonth();
          _isSuccess = true;
        } else {
          LoggerUtil.w(
              'API returned success=false: ${jsonResponse['message']}');
          _error = jsonResponse['message'] ?? 'Failed to load activities';
        }
      } else {
        LoggerUtil.e('API returned error status: ${response.statusCode}');
        _error = 'Failed to load activities. Status: ${response.statusCode}';
      }
    } catch (e) {
      LoggerUtil.e('Exception in loadRecentActivities', e, StackTrace.current);
      _error = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreActivities() async {
    if (_isLoadingMore || !_hasMoreData) {
      LoggerUtil.d("loadMoreActivities: Already loading or no more data");
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Get the current user information
      final userInfo = await _getCurrentUserInfo();
      final userId = userInfo['userId'];

      if (userId == null) {
        throw Exception('User ID tidak ditemukan. Silakan login kembali.');
      }

      LoggerUtil.d(
          'Loading more activities for user $userId - page $_currentPage');
      final url =
          '/asset-histories/activities/user/$userId?limit=$_limit&page=$_currentPage';
      LoggerUtil.d('API URL: $url');

      final response = await ApiService.get(url);

      LoggerUtil.d(
          'Load more activities response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        LoggerUtil.d(
            'Response body: ${jsonResponse.toString().substring(0, math.min(200, jsonResponse.toString().length))}...');

        if (jsonResponse['success'] == true) {
          final dataSection = jsonResponse['data'];

          if (dataSection == null) {
            LoggerUtil.w('Data section missing in load more response');
            _hasMoreData = false;
            _isLoadingMore = false;
            notifyListeners();
            return;
          }

          final List<dynamic>? historiesJson = dataSection['histories'];
          LoggerUtil.d('Histories in response: ${historiesJson?.length ?? 0}');

          if (historiesJson == null || historiesJson.isEmpty) {
            LoggerUtil.i('No more activities found');
            _hasMoreData = false;
            _isLoadingMore = false;
            notifyListeners();
            return;
          }

          final newActivities = historiesJson
              .where((json) => json != null)
              .map((json) => HistoryModel.fromJson(json))
              .toList();

          LoggerUtil.d('Parsed ${newActivities.length} new activities');

          if (newActivities.isEmpty) {
            LoggerUtil.w('No valid activities in response');
            _hasMoreData = false;
            _isLoadingMore = false;
            notifyListeners();
            return;
          }

          LoggerUtil.d('Before adding: ${_activities.length} activities');
          // Add the new activities to the list
          _activities.addAll(newActivities);
          LoggerUtil.d('After adding: ${_activities.length} activities');

          if (dataSection['pagination'] != null) {
            final paginationData = dataSection['pagination'];
            _pagination = HistoryPagination.fromJson(paginationData);
            LoggerUtil.d('Pagination data: $paginationData');

            // Update hasMoreData based on pagination info
            _hasMoreData = _pagination!.currentPage < _pagination!.totalPages;

            LoggerUtil.d(
                'Pagination info: Page ${_pagination!.currentPage}/${_pagination!.totalPages}, hasNext: ${_pagination!.hasNext}');
            LoggerUtil.d('Setting hasMoreData to $_hasMoreData');

            // Always increment current page for next request
            _currentPage++;
            LoggerUtil.d('Next page will be $_currentPage');
          } else {
            LoggerUtil.w('No pagination info in response');
            _hasMoreData = false;
          }

          // Update grouped activities
          _groupActivitiesByMonth();
          LoggerUtil.d(
              'After grouping: ${_activitiesByMonth.length} month groups');

          // Force a UI update
          notifyListeners();
        } else {
          LoggerUtil.w(
              'API returned success=false: ${jsonResponse['message']}');
          _error = jsonResponse['message'] ?? 'Failed to load more activities';
        }
      } else {
        LoggerUtil.e('API returned error status: ${response.statusCode}');
        _error =
            'Failed to load more activities. Status: ${response.statusCode}';
      }
    } catch (e) {
      LoggerUtil.e('Exception in loadMoreActivities', e, StackTrace.current);
      _error = 'Error loading more data: ${e.toString()}';
    } finally {
      _isLoadingMore = false;
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

  // Debug method to print the current state
  void debugPrintState() {
    LoggerUtil.d('=== RecentActivityController State ===');
    LoggerUtil.d('User ID: $_userId');
    LoggerUtil.d('Employee Number: $_employeeNumber');
    LoggerUtil.d('Employee Name: $_employeeName');
    LoggerUtil.d('Activities count: ${_activities.length}');
    LoggerUtil.d('Activities by month count: ${_activitiesByMonth.length}');
    LoggerUtil.d('Current page: $_currentPage');
    LoggerUtil.d('Has more data: $_hasMoreData');
    LoggerUtil.d('Is loading: $_isLoading');
    LoggerUtil.d('Is loading more: $_isLoadingMore');
    LoggerUtil.d('Error: $_error');

    if (_pagination != null) {
      LoggerUtil.d('Pagination:');
      LoggerUtil.d('  Current page: ${_pagination!.currentPage}');
      LoggerUtil.d('  Total pages: ${_pagination!.totalPages}');
      LoggerUtil.d('  Total items: ${_pagination!.totalItems}');
      LoggerUtil.d('  Has next: ${_pagination!.hasNext}');
      LoggerUtil.d('  Has prev: ${_pagination!.hasPrev}');
    } else {
      LoggerUtil.d('Pagination: null');
    }
    LoggerUtil.d('====================================');
  }

  // Reset state method to ensure the scroll controller is properly initialized
  void resetState() {
    LoggerUtil.d("Resetting RecentActivityController state");
    _activities = [];
    _activitiesByMonth = {};
    _pagination = null;
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMoreData = true;
    _isSuccess = false;
    _userId = null; // Reset the user ID to force re-fetching it
    _employeeNumber = null; // Reset the employee number too
    _employeeName = null; // Reset the employee name too

    // Re-initialize the scroll controller if needed
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }
}
