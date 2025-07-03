import 'package:flutter/material.dart';
import 'total_asset_controller.dart';
import '../utils/logger_util.dart';

class AssetUnderRepairController extends ChangeNotifier {
  TotalAssetController? _totalAssetController;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d(
          'AssetUnderRepairController loading state set to: $_isLoading');
    }
  }

  void setTotalAssetController(TotalAssetController controller) {
    _totalAssetController = controller;
    notifyListeners();
  }

  String get totalUnderRepair {
    if (_totalAssetController == null ||
        _totalAssetController!.dashboardSummary == null) {
      return "0";
    }

    final status = _totalAssetController!.dashboardSummary!.assetsByStatus;
    return status['under repair']?.toString() ?? "0";
  }

  String get totalCalibrationsNeeded {
    if (_totalAssetController == null ||
        _totalAssetController!.dashboardSummary == null) {
      return "0";
    }

    // Get the "under repair" value from assetsByStatus instead of upcoming calibrations
    final status = _totalAssetController!.dashboardSummary!.assetsByStatus;
    final underRepairCount = status['under repair'] ?? 0;

    // Convert to string and return
    return underRepairCount.toString();
  }

  Future<void> loadAssetUnderRepair() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // We don't need to load data separately as it comes from the dashboard summary

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
