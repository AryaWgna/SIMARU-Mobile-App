import 'package:flutter/material.dart';
import '../models/net_asset_value.dart';
import '../services/net_asset_value_service.dart';

class NetAssetValueController extends ChangeNotifier {
  final NetAssetValueService _service = NetAssetValueService();
  NetAssetValue? _netAssetValue;
  bool _isLoading = false;
  String? _error;

  NetAssetValue? get netAssetValue => _netAssetValue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNetAssetValue() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _netAssetValue = await _service.getNetAssetValue();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
