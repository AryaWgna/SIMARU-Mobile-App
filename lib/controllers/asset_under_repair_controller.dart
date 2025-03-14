import 'package:flutter/material.dart';
import '../models/asset_under_repair.dart';
import '../services/asset_under_repair_service.dart';

class AssetUnderRepairController extends ChangeNotifier {
  final AssetUnderRepairService _service = AssetUnderRepairService();
  AssetUnderRepair? _assetUnderRepair;
  bool _isLoading = false;
  String? _error;

  AssetUnderRepair? get assetUnderRepair => _assetUnderRepair;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAssetUnderRepair() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _assetUnderRepair = await _service.getAssetUnderRepair();
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