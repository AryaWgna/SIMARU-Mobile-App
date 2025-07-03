import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart';
import '../models/dashboard_summary_model.dart';
import '../utils/logger_util.dart';

class TotalAssetController extends ChangeNotifier {
  DashboardSummaryModel? _dashboardSummary;
  bool _isLoading = false;
  String? _error;

  DashboardSummaryModel? get dashboardSummary => _dashboardSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get totalAssets {
    if (_dashboardSummary == null) return "0";
    return _dashboardSummary!.totalAssets.toString();
  }

  String get upcomingCalibrations {
    if (_dashboardSummary == null) return "0";
    return _dashboardSummary!.totalUpcomingCalibrations.toString();
  }

  // Helper method to translate medical/non-medical to Indonesian
  String translateAssetType(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return 'Medis';
      case 'non_medical':
        return 'Non Medis';
      default:
        return type;
    }
  }

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('TotalAssetController loading state set to: $_isLoading');
    }
  }

  // Load dashboard summary which includes total assets
  Future<void> loadTotalAsset() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await ApiService.get(
        '/dashboard/summary',
      );

      LoggerUtil.d(
          'Dashboard API response status code: ${response.statusCode}');
      LoggerUtil.d(
          'Dashboard API response received with ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          _dashboardSummary =
              DashboardSummaryModel.fromJson(jsonResponse['data']);
          LoggerUtil.i(
              'Dashboard summary loaded: ${_dashboardSummary?.totalAssets} assets');
        } else {
          _error =
              jsonResponse['message'] ?? 'Failed to load dashboard summary';
          LoggerUtil.w('API error: $_error');
        }
      } else {
        _error = 'API Error: ${response.statusCode}';
        LoggerUtil.w('API status code error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error loading dashboard summary', e, StackTrace.current);
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
