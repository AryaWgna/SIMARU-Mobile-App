import 'package:flutter/material.dart';
import '../models/total_asset.dart';
import '../services/total_asset_service.dart';

class TotalAssetController extends ChangeNotifier {
  final TotalAssetService _service = TotalAssetService();
  TotalAsset? _totalAsset;
  bool _isLoading = false;
  String? _error;

  TotalAsset? get totalAsset => _totalAsset;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTotalAsset() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _totalAsset = await _service.getTotalAsset();
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
