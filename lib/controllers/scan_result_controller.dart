import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart' as auth;
import '../models/scan_result_model.dart';

class ScanResultController extends ChangeNotifier {
  // Data dari API
  List<AssetScanDetail> _foundAssets = [];
  List<AssetScanDetail> _missingAssets = [];
  List<AssetScanDetail> _misplacedAssets = [];
  SummaryData? _summaryData;
  RoomInfo? _roomInfo;
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  List<AssetScanDetail> get foundAssets => _foundAssets;
  List<AssetScanDetail> get missingAssets => _missingAssets;
  List<AssetScanDetail> get misplacedAssets => _misplacedAssets;
  SummaryData? get summaryData => _summaryData;
  RoomInfo? get roomInfo => _roomInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Mengambil data scan dari API
  Future<void> loadScanResults(int opnameId) async {
    setLoading(true);
    clearError();

    try {
      // Ambil data untuk setiap status scan
      await Future.wait([
        _fetchAssetsByStatus('found', opnameId),
        _fetchAssetsByStatus('missing', opnameId),
        _fetchAssetsByStatus('misplaced', opnameId),
      ]);
    } catch (e) {
      setError('Gagal memuat data: $e');
    } finally {
      setLoading(false);
    }
  }

  // Mengambil data aset berdasarkan status scan
  Future<void> _fetchAssetsByStatus(String status, int opnameId) async {
    try {
      print('Memuat aset dengan status: $status');
      final response = await auth.ApiService.get(
        '/asset-opname-details/opname/$opnameId?scan_status=$status',
      );

      print(
          'Response untuk status $status: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Tambahkan penanganan untuk berbagai format data yang mungkin dikembalikan
          List<dynamic> assetsJson = [];

          // Periksa tipe data dari data['data']
          if (data['data'] is List) {
            // Jika sudah berupa list, gunakan langsung
            assetsJson = data['data'];
          } else if (data['data'] is Map) {
            // Jika berupa map, cek apakah ada kunci yang berisi list
            // Ini adalah solusi sementara, lebih baik menyesuaikan dengan struktur API yang sebenarnya
            if (data['data']['assets'] is List) {
              assetsJson = data['data']['assets'];
            } else {
              // Jika tidak ada list di dalam map, gunakan list kosong
              print(
                  'Data assets tidak ditemukan atau bukan list: ${data['data']}');
              assetsJson = [];
            }
          } else {
            // Jika bukan list atau map, gunakan list kosong
            print('Tipe data tidak didukung: ${data['data']}');
            assetsJson = [];
          }

          final List<AssetScanDetail> assets = assetsJson
              .where((json) => json != null)
              .map((json) => AssetScanDetail.fromJson(json))
              .toList();

          // Simpan data summary dan room info saat first call
          if (_summaryData == null && data['summary'] != null) {
            try {
              _summaryData = SummaryData.fromJson(data['summary']);
            } catch (e) {
              print('Error saat parsing summary: $e');
            }
          }

          if (_roomInfo == null && data['room_info'] != null) {
            try {
              _roomInfo = RoomInfo.fromJson(data['room_info']);
            } catch (e) {
              print('Error saat parsing room_info: $e');
            }
          }

          if (status == 'found') {
            _foundAssets = assets;
          } else if (status == 'missing') {
            _missingAssets = assets;
          } else if (status == 'misplaced') {
            _misplacedAssets = assets;
          }
          notifyListeners();
        } else {
          throw data['message'] ?? 'Gagal memuat data';
        }
      } else {
        throw 'Error status code: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      print('Error saat memuat data: $e');
      print('Stack trace: $stackTrace');
      setError('Gagal memuat data: $e');
    }
  }

  // Menyimpan catatan untuk aset
  Future<bool> saveNotes(
      int detailId, String notes, BuildContext context) async {
    try {
      setLoading(true);

      final response = await auth.ApiService.put(
        '/asset-opname-details/$detailId/notes',
        body: {
          'notes': notes,
        },
        context: context,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return true;
        } else {
          throw data['message'] ?? 'Gagal menyimpan catatan';
        }
      } else {
        throw 'Error status code: ${response.statusCode}';
      }
    } catch (e) {
      setError('Gagal menyimpan catatan: $e');
      return false;
    } finally {
      setLoading(false);
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }
}
