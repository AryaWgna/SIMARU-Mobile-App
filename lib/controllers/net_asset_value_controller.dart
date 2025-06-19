import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart';
import '../models/net_asset_model.dart';
import '../core/config/api_config.dart';

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
      print('NetAssetValueController loading state set to: $_isLoading');
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

      print('Loading depreciation data for year: $year, month: $month');

      // Use the ApiConfig URL
      final url = ApiConfig.getDepreciationTotalUrl(year: year, month: month);
      print('Using depreciation URL: $url');

      // Extract endpoint from full URL
      final endpoint = url.replaceAll(ApiConfig.baseUrl, '');
      print('Extracted endpoint: $endpoint');

      final response = await ApiService.get(endpoint);

      print('Depreciation API response status code: ${response.statusCode}');
      print('Depreciation API response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          _netAssetValue = NetAssetModel.fromJson(jsonResponse['data']);
          print('Loaded net asset value: $_netAssetValue');
          print(
              'Formatted book value: ${_netAssetValue?.formattedTotalBookValue}');
        } else {
          _error = jsonResponse['message'] ?? 'Failed to load net asset value';
          print('API returned error: $_error');
        }
      } else {
        _error = 'API Error: ${response.statusCode}';
        print('API status code error: $_error');
      }
    } catch (e) {
      _error = e.toString();
      print('Error loading net asset value: $e');
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
