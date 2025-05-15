import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart';
import 'package:intl/intl.dart';
import '../core/config/api_config.dart';

class NetAssetModel {
  final double totalAcquisitionCost;
  final double totalBookValue;
  final double totalDepreciation;
  final int assetCount;
  final int depreciableAssetCount;
  final String asOfDate;
  final String formattedTotalBookValue;
  final String formattedTotalDepreciation;

  NetAssetModel({
    required this.totalAcquisitionCost,
    required this.totalBookValue,
    required this.totalDepreciation,
    required this.assetCount,
    required this.depreciableAssetCount,
    required this.asOfDate,
    required this.formattedTotalBookValue,
    required this.formattedTotalDepreciation,
  });

  factory NetAssetModel.fromJson(Map<String, dynamic> json) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id',
      symbol: '',
      decimalDigits: 0,
    );

    return NetAssetModel(
      totalAcquisitionCost: json['total_acquisition_cost'] != null
          ? json['total_acquisition_cost'].toDouble()
          : 0.0,
      totalBookValue: json['total_book_value'] != null
          ? json['total_book_value'].toDouble()
          : 0.0,
      totalDepreciation: json['total_depreciation'] != null
          ? json['total_depreciation'].toDouble()
          : 0.0,
      assetCount: json['asset_count'] ?? 0,
      depreciableAssetCount: json['depreciable_asset_count'] ?? 0,
      asOfDate: json['as_of_date'] ?? '-',
      formattedTotalBookValue:
          currencyFormatter.format(json['total_book_value'] ?? 0),
      formattedTotalDepreciation:
          currencyFormatter.format(json['total_depreciation'] ?? 0),
    );
  }
}

class NetAssetValueController extends ChangeNotifier {
  NetAssetModel? _netAssetValue;
  bool _isLoading = false;
  String? _error;

  NetAssetModel? get netAssetValue => _netAssetValue;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
