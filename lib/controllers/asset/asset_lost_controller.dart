import 'package:flutter/material.dart';
import 'dart:convert';
import '../auth/auth_controller.dart';
import '../../utils/logger_util.dart';

class AssetLostController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Setters
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('AssetLostController loading state set to: $_isLoading');
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

  // Process lost report
  Future<Map<String, dynamic>?> reportLost({
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

      final requestBody = {
        "asset_id": assetId,
        "loss_reason": notes,
      };

      LoggerUtil.i('Sending lost report for asset ID: ${assetId}');

      final response = await ApiService.post(
        '/asset-transfers/loss',
        body: requestBody,
        context: context,
      );

      LoggerUtil.d('Response status: ${response.statusCode}');
      LoggerUtil.d('Response received with ${response.body.length} bytes');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final bool isSuccess =
            data['success'] == true || data['status'] == true;

        if (isSuccess) {
          // Return updated asset data
          return {
            'success': true,
            'message': 'Laporan kehilangan berhasil dikirim',
            'current_status': 'lost'
          };
        } else {
          throw Exception(data['message'] ?? 'Laporan kehilangan gagal');
        }
      } else {
        var errorMsg = 'Laporan kehilangan gagal: ${response.statusCode}';
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
    notifyListeners();
  }
}
