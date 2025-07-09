import 'package:flutter/material.dart';
import 'dart:convert';
import '../auth/auth_controller.dart';
import '../../utils/logger_util.dart';

class AssetCheckinController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCondition = 'GOOD'; // Default kondisi
  DateTime _currentDate = DateTime.now();

  // List kondisi yang tersedia
  final List<Map<String, String>> _conditions = [
    {'value': 'GOOD', 'label': 'BAIK'},
    {'value': 'DAMAGED', 'label': 'RUSAK'},
    {'value': 'NEEDS_REPAIR', 'label': 'PERLU PERBAIKAN'},
  ];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCondition => _selectedCondition;
  DateTime get currentDate => _currentDate;
  List<Map<String, String>> get conditions => _conditions;

  // Setters
  void setSelectedCondition(String value) {
    _selectedCondition = value;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('AssetCheckinController loading state set to: $_isLoading');
    }
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Process return
  Future<Map<String, dynamic>?> processReturn({
    required int assetId,
    required String notes,
    required BuildContext context,
  }) async {
    if (notes.isEmpty) {
      setError('Catatan tidak boleh kosong');
      return null;
    }

    try {
      setLoading(true);
      clearError();

      // Persiapkan body request
      Map<String, dynamic> requestBody = {
        "asset_id": assetId,
        "return_notes": notes,
        "condition": _selectedCondition,
      };

      LoggerUtil.i('Sending return request with asset ID: ${assetId}');

      final response = await ApiService.post(
        '/asset-transfers/return',
        body: requestBody,
        context: context,
      );

      LoggerUtil.d('Response status: ${response.statusCode}');
      LoggerUtil.d('Response received with ${response.body.length} bytes');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final bool isSuccess = data['success'] == true;

        if (isSuccess) {
          // Return updated asset data
          return {
            'success': true,
            'message': 'Pengembalian berhasil',
            'current_status': 'available',
            'condition': _selectedCondition
          };
        } else {
          throw Exception(data['message'] ?? 'Pengembalian gagal');
        }
      } else {
        var errorMsg = 'Pengembalian gagal: ${response.statusCode}';
        try {
          final data = json.decode(response.body);
          if (data['message'] != null) {
            errorMsg = data['message'];
          } else if (data['error'] != null) {
            errorMsg = data['error'];
          }
        } catch (e) {
          LoggerUtil.e('Failed to parse error response', e, StackTrace.current);
        }

        throw Exception(errorMsg);
      }
    } catch (e) {
      setError('Error: ${e.toString().replaceAll('Exception: ', '')}');
      return {
        'success': false,
        'message': _errorMessage ?? 'Terjadi kesalahan'
      };
    } finally {
      setLoading(false);
    }
  }

  // Reset controller state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _selectedCondition = 'GOOD';
    notifyListeners();
  }
}
