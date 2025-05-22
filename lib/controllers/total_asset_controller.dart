import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart';

class DashboardSummaryModel {
  final int totalUsers;
  final int totalAssets;
  final Map<String, int> assetsByType;
  final Map<String, int> assetsByStatus;
  final Map<String, int> assetsByCondition;
  final List<Map<String, dynamic>> assetsBySubcategory;
  final List<Map<String, dynamic>> assetsByLocation;
  final Map<String, dynamic> upcomingCalibrations;

  DashboardSummaryModel({
    required this.totalUsers,
    required this.totalAssets,
    required this.assetsByType,
    required this.assetsByStatus,
    required this.assetsByCondition,
    required this.assetsBySubcategory,
    required this.assetsByLocation,
    required this.upcomingCalibrations,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    // Parse assetsByType
    Map<String, int> assetsByType = {};
    if (json['assets_by_type'] != null) {
      json['assets_by_type'].forEach((key, value) {
        assetsByType[key] = value is int ? value : int.parse(value.toString());
      });
    }

    // Parse assetsByStatus
    Map<String, int> assetsByStatus = {};
    if (json['assets_by_status'] != null) {
      json['assets_by_status'].forEach((key, value) {
        assetsByStatus[key] =
            value is int ? value : int.parse(value.toString());
      });
    }

    // Parse assetsByCondition
    Map<String, int> assetsByCondition = {};
    if (json['assets_by_condition'] != null) {
      json['assets_by_condition'].forEach((key, value) {
        assetsByCondition[key] =
            value is int ? value : int.parse(value.toString());
      });
    }

    // Parse assetsBySubcategory
    List<Map<String, dynamic>> assetsBySubcategory = [];
    if (json['assets_by_subcategory'] != null) {
      assetsBySubcategory = List<Map<String, dynamic>>.from(
          json['assets_by_subcategory']
              .map((x) => Map<String, dynamic>.from(x)));
    }

    // Parse assetsByLocation
    List<Map<String, dynamic>> assetsByLocation = [];
    if (json['assets_by_location'] != null) {
      assetsByLocation = List<Map<String, dynamic>>.from(
          json['assets_by_location'].map((x) => Map<String, dynamic>.from(x)));
    }

    return DashboardSummaryModel(
      totalUsers: json['total_users'] ?? 0,
      totalAssets: json['total_assets'] ?? 0,
      assetsByType: assetsByType,
      assetsByStatus: assetsByStatus,
      assetsByCondition: assetsByCondition,
      assetsBySubcategory: assetsBySubcategory,
      assetsByLocation: assetsByLocation,
      upcomingCalibrations: json['upcoming_calibrations'] ?? {},
    );
  }

  int get totalUpcomingCalibrations {
    if (upcomingCalibrations.containsKey('all') &&
        upcomingCalibrations['all'] is List) {
      return (upcomingCalibrations['all'] as List).length;
    }
    return 0;
  }
}

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
