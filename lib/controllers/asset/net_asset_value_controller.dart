import 'package:flutter/material.dart';
import 'dart:convert';
import '../auth/auth_controller.dart';
import '../../models/asset/net_asset_model.dart';
import '../../core/config/api_config.dart';
import '../../utils/logger_util.dart';

class NetAssetValueController extends ChangeNotifier {
  NetAssetModel? _netAssetValue;
  bool _isLoading = false;
  String? _error;

  NetAssetModel? get netAssetValue => _netAssetValue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('NetAssetValueController loading state set to: $_isLoading');
    }
  }

  Future<void> loadNetAssetValue() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current date for parameters
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      LoggerUtil.i('Loading depreciation data for year: $year, month: $month');

      // Use the ApiConfig URL
      final url = ApiConfig.getDepreciationTotalUrl(year: year, month: month);
      LoggerUtil.d('Using depreciation URL: $url');

      // Extract endpoint from full URL
      final endpoint = url.replaceAll(ApiConfig.baseUrl, '');
      LoggerUtil.d('Extracted endpoint: $endpoint');

      final response = await ApiService.get(endpoint);

      LoggerUtil.d(
          'Depreciation API response status code: ${response.statusCode}');
      LoggerUtil.d(
          'Depreciation API response received with ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          _netAssetValue = NetAssetModel.fromJson(jsonResponse['data']);
          LoggerUtil.d('Loaded net asset value: $_netAssetValue');
          LoggerUtil.i(
              'Formatted book value: ${_netAssetValue?.formattedTotalBookValue}');
        } else {
          _error = jsonResponse['message'] ?? 'Failed to load net asset value';
          LoggerUtil.w('API returned error: $_error');
        }
      } else {
        _error = 'API Error: ${response.statusCode}';
        LoggerUtil.w('API status code error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error loading net asset value', e, StackTrace.current);
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
