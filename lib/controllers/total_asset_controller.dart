import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart';
import '../models/dashboard_summary_model.dart';

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

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      print('TotalAssetController loading state set to: $_isLoading');
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

      print('Dashboard API response status code: ${response.statusCode}');
      print('Dashboard API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          _dashboardSummary =
              DashboardSummaryModel.fromJson(jsonResponse['data']);
          print(
              'Dashboard summary loaded: ${_dashboardSummary?.totalAssets} assets');
        } else {
          _error =
              jsonResponse['message'] ?? 'Failed to load dashboard summary';
          print('API error: $_error');
        }
      } else {
        _error = 'API Error: ${response.statusCode}';
        print('API status code error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading dashboard summary: $e');
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
