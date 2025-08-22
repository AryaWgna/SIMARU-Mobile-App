import 'package:flutter/material.dart';
import 'dart:convert';
import '../auth/auth_controller.dart' as auth;
import '../../models/scan/scan_result_model.dart';
import '../../utils/logger_util.dart';

class ScanResultController extends ChangeNotifier {
  // Data dari API
  List<AssetScanDetail> _foundAssets = [];
  List<AssetScanDetail> _missingAssets = [];
  List<AssetScanDetail> _misplacedAssets = [];
  SummaryData? _summaryData;
  RoomInfo? _roomInfo;
  OpnameInfo? _opnameInfo;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  List<AssetScanDetail> get foundAssets => _foundAssets;
  List<AssetScanDetail> get missingAssets => _missingAssets;
  List<AssetScanDetail> get misplacedAssets => _misplacedAssets;
  SummaryData? get summaryData => _summaryData;
  RoomInfo? get roomInfo => _roomInfo;
  OpnameInfo? get opnameInfo => _opnameInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mengambil data scan dari API
  Future<void> loadScanResults(int opnameId) async {
    setLoading(true);
    clearError();

    try {
      // Ambil semua data sekaligus dan filter berdasarkan status
      await _fetchAllAssets(opnameId);
    } catch (e) {
      setError('Gagal memuat data: $e');
    } finally {
      setLoading(false);
    }
  }

  // Mengambil semua data aset sekaligus
  Future<void> _fetchAllAssets(int opnameId) async {
    try {
      LoggerUtil.i('Memuat semua aset untuk opname ID: $opnameId');

      // Menggunakan endpoint API yang baru
      final response = await auth.ApiService.get(
        '/asset-opname-details/opname/$opnameId',
      );

      LoggerUtil.d('Response API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Reset data
          _foundAssets = [];
          _missingAssets = [];
          _misplacedAssets = [];

          // Parse data dari format API yang baru
          if (data['data'] != null && data['data']['details'] != null) {
            List<dynamic> assetsJson = data['data']['details'];

            LoggerUtil.i('Total assets loaded: ${assetsJson.length}');

            // Filter dan kategorikan aset berdasarkan status
            for (var json in assetsJson) {
              final asset = AssetScanDetail.fromJson(json);

              LoggerUtil.d(
                  'Processing asset: ${asset.assetCode}, status: ${asset.scanStatus}');

              switch (asset.scanStatus.toLowerCase()) {
                case 'found':
                  _foundAssets.add(asset);
                  break;
                case 'missing':
                  _missingAssets.add(asset);
                  break;
                case 'misplaced':
                  _misplacedAssets.add(asset);
                  break;
                default:
                  LoggerUtil.w('Unknown scan status: ${asset.scanStatus}');
              }
            }

            LoggerUtil.i('Found assets: ${_foundAssets.length}');
            LoggerUtil.i('Missing assets: ${_missingAssets.length}');
            LoggerUtil.i('Misplaced assets: ${_misplacedAssets.length}');
          }

          // Simpan data summary
          if (data['data'] != null && data['data']['summary'] != null) {
            _summaryData = SummaryData.fromJson(data['data']['summary']);
          }

          // Simpan data room info
          if (data['data'] != null && data['data']['room_info'] != null) {
            _roomInfo = RoomInfo.fromJson(data['data']['room_info']);
          }

          // Simpan data opname info
          if (data['data'] != null && data['data']['opname_info'] != null) {
            _opnameInfo = OpnameInfo.fromJson(data['data']['opname_info']);
          }

          notifyListeners();
        } else {
          throw data['message'] ?? 'Gagal memuat data';
        }
      } else {
        throw 'Error status code: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      LoggerUtil.e('Error saat memuat data', e, stackTrace);
      setError('Gagal memuat data: $e');
    }
  }

  // Menyimpan catatan untuk aset
  Future<bool> saveNotes(
      int detailId, String notes, BuildContext context) async {
    try {
      setLoading(true);

      LoggerUtil.i('===== SAVING NOTES TO API =====');
      LoggerUtil.d('Detail ID: $detailId');
      LoggerUtil.d('Notes: $notes');

      // Menggunakan endpoint dari dokumentasi API
      final endpoint = '/asset-opname-details/$detailId/notes';
      LoggerUtil.d('API Endpoint: $endpoint');

      final payload = {
        'notes': notes,
      };
      LoggerUtil.d('Request Payload: $payload');

      // Menggunakan endpoint dari dokumentasi API
      final response = await auth.ApiService.put(
        endpoint,
        body: payload,
        context: context,
      );

      LoggerUtil.d('API Response Status: ${response.statusCode}');
      LoggerUtil.d('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerUtil.d('API Response Decoded: $data');

        if (data['success'] == true) {
          LoggerUtil.i('Notes saved successfully to API!');
          // Perbarui data lokal
          _updateLocalNotes(detailId, notes);
          return true;
        } else {
          final errorMessage = data['message'] ?? 'Gagal menyimpan catatan';
          LoggerUtil.w('API Error: $errorMessage');
          throw errorMessage;
        }
      } else {
        final errorMessage = 'Error status code: ${response.statusCode}';
        LoggerUtil.w('API Error: $errorMessage');
        throw errorMessage;
      }
    } catch (e) {
      LoggerUtil.e('Exception during saveNotes', e, StackTrace.current);
      setError('Gagal menyimpan catatan: $e');
      return false;
    } finally {
      LoggerUtil.d('===== END SAVING NOTES =====');
      setLoading(false);
    }
  }

  // Memperbarui catatan pada data lokal
  void _updateLocalNotes(int detailId, String notes) {
    LoggerUtil.d('Updating local notes for detailId: $detailId, notes: $notes');

    // Cari dan perbarui catatan di setiap daftar aset
    for (int i = 0; i < _foundAssets.length; i++) {
      if (_foundAssets[i].detailId == detailId) {
        // Gunakan metode copyWith untuk memperbarui catatan
        _foundAssets[i] = _foundAssets[i].copyWith(notes: notes);
        LoggerUtil.d('Updated notes in foundAssets list');
        break;
      }
    }

    // Lakukan hal yang sama untuk aset yang hilang
    for (int i = 0; i < _missingAssets.length; i++) {
      if (_missingAssets[i].detailId == detailId) {
        _missingAssets[i] = _missingAssets[i].copyWith(notes: notes);
        LoggerUtil.d('Updated notes in missingAssets list');
        break;
      }
    }

    // Lakukan hal yang sama untuk aset yang berpindah
    for (int i = 0; i < _misplacedAssets.length; i++) {
      if (_misplacedAssets[i].detailId == detailId) {
        _misplacedAssets[i] = _misplacedAssets[i].copyWith(notes: notes);
        LoggerUtil.d('Updated notes in misplacedAssets list');
        break;
      }
    }

    // Beri tahu listener bahwa data telah berubah
    notifyListeners();
    LoggerUtil.d('Notified listeners of notes update');
  }

  // Update kondisi aset berdasarkan asset code
  void updateAssetCondition(String assetCode, String newCondition) {
    LoggerUtil.d('Updating condition for asset: $assetCode to $newCondition');

    bool updated = false;

    // Update di found assets
    for (int i = 0; i < _foundAssets.length; i++) {
      if (_foundAssets[i].assetCode == assetCode) {
        // Preserve original condition if not already set
        String? originalCondition = _foundAssets[i].originalCondition;
        if (originalCondition == null || originalCondition.isEmpty) {
          originalCondition = _foundAssets[i].condition;
        }

        _foundAssets[i] = _foundAssets[i].copyWith(
          condition: newCondition,
          originalCondition: originalCondition,
        );
        LoggerUtil.d('Updated condition in foundAssets list');
        updated = true;
        break;
      }
    }

    // Update di missing assets
    for (int i = 0; i < _missingAssets.length; i++) {
      if (_missingAssets[i].assetCode == assetCode) {
        // Preserve original condition if not already set
        String? originalCondition = _missingAssets[i].originalCondition;
        if (originalCondition == null || originalCondition.isEmpty) {
          originalCondition = _missingAssets[i].condition;
        }

        _missingAssets[i] = _missingAssets[i].copyWith(
          condition: newCondition,
          originalCondition: originalCondition,
        );
        LoggerUtil.d('Updated condition in missingAssets list');
        updated = true;
        break;
      }
    }

    // Update di misplaced assets
    for (int i = 0; i < _misplacedAssets.length; i++) {
      if (_misplacedAssets[i].assetCode == assetCode) {
        // Preserve original condition if not already set
        String? originalCondition = _misplacedAssets[i].originalCondition;
        if (originalCondition == null || originalCondition.isEmpty) {
          originalCondition = _misplacedAssets[i].condition;
        }

        _misplacedAssets[i] = _misplacedAssets[i].copyWith(
          condition: newCondition,
          originalCondition: originalCondition,
        );
        LoggerUtil.d('Updated condition in misplacedAssets list');
        updated = true;
        break;
      }
    }

    if (updated) {
      notifyListeners();
      LoggerUtil.d('Notified listeners of condition update');
    } else {
      LoggerUtil.w('Asset with code $assetCode not found for condition update');
    }
  }

  // Helper methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset controller state
  void reset() {
    _foundAssets = [];
    _missingAssets = [];
    _misplacedAssets = [];
    _summaryData = null;
    _roomInfo = null;
    _opnameInfo = null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }
}
