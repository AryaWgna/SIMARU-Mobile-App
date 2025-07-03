import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart' as auth;
import '../utils/logger_util.dart';
import 'package:intl/intl.dart';

class AssetDetailsController extends ChangeNotifier {
  Map<String, dynamic>? _assetData;
  Map<String, dynamic>? _masterAssetData;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _refreshCount = 0;

  Map<String, dynamic>? get assetData => _assetData;
  Map<String, dynamic>? get masterAssetData => _masterAssetData;
  bool get isLoading => _isLoading;
  bool get isLoadingMasterData => _isLoading;
  bool get hasError => _hasError;
  bool get hasMasterDataError => _hasError;
  String get errorMessage => _errorMessage;
  String get masterDataErrorMessage => _errorMessage;
  int get refreshCount => _refreshCount;

  void setAssetData(Map<String, dynamic>? data) {
    _assetData = data;

    // If data contains asset_master, also set masterAssetData
    if (data != null && data['asset_master'] != null) {
      String assetType =
          _getSimplifiedAssetType(data['asset_master']['asset_type'] ?? '-');

      // Get brand name from various possible sources
      String brandName = data['asset_master']['brands']?['brand_name'] ??
          data['asset_master']['brand']?['brand_name'] ??
          data['asset_master']['brand_name'] ??
          '-';

      // Ensure asset name is set properly
      if (data['asset_name'] == null &&
          data['asset_master']['asset_name'] != null) {
        data['asset_name'] = data['asset_master']['asset_name'];
      }

      _masterAssetData = {
        'asset_master_code': data['asset_master']['asset_master_code'] ?? '-',
        'asset_name': data['asset_master']['asset_name'] ?? '-',
        'asset_type': assetType,
        'subcategory_name': data['asset_master']['subcategory_name'] ?? '-',
        'brand_name': brandName,
        'needs_calibration': data['asset_master']['needs_calibration'] ?? false,
        'is_depreciable': data['asset_master']['is_depreciable'] ?? false,
        'description': data['asset_master']['description'] ?? '-'
      };
    }

    notifyListeners();
  }

  void incrementRefreshCount() {
    _refreshCount++;
    if (_refreshCount >= 3) {
      _refreshCount = 0;
    }
    notifyListeners();
  }

  void resetRefreshCount() {
    _refreshCount = 0;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchAssetData(String assetCode, {BuildContext? context}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      LoggerUtil.i('[ASSET_DETAILS] Mengambil data aset untuk: $assetCode');

      // Gunakan endpoint untuk mengambil data aset berdasarkan kode/QR
      final endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';

      LoggerUtil.d('[ASSET_DETAILS] Memanggil API endpoint: $endpoint');
      final response = await auth.ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        LoggerUtil.d('[ASSET_DETAILS] Response data: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          final fullAssetData = responseData['data'];

          // Log data lengkap untuk debugging
          LoggerUtil.d('[ASSET_DETAILS] Full asset data: $fullAssetData');

          // Ensure asset name is set properly in the API response
          if (fullAssetData['asset_name'] == null &&
              fullAssetData['asset_master'] != null &&
              fullAssetData['asset_master']['asset_name'] != null) {
            fullAssetData['asset_name'] =
                fullAssetData['asset_master']['asset_name'];
          }

          // Map respons API ke format yang diharapkan aplikasi
          Map<String, dynamic> mappedData = {
            'asset_id': fullAssetData['asset_id'],
            'asset_code': fullAssetData['asset_code'],
            'asset_name': fullAssetData['asset_name'] ??
                fullAssetData['asset_master']?['asset_name'] ??
                'Tidak diketahui',
            'asset_master_id': fullAssetData['asset_master_id'],
            'asset_master_code': fullAssetData['asset_master']
                ?['asset_master_code'],
            'current_status': fullAssetData['current_status'] ?? 'available',
            'condition': fullAssetData['condition'] ?? '-',
            'serial_number': fullAssetData['serial_number'] ?? '-',
            'warranty_end_date': fullAssetData['warranty_end_date'] ?? '-',
            'purchase_date': fullAssetData['purchase_date'] ?? '-',
            'purchase_price': fullAssetData['purchase_cost'] ?? '-',
            'disposal_date': fullAssetData['disposal_date'] ??
                fullAssetData['disposed_at'] ??
                '-',
            'updated_at':
                fullAssetData['updated_at'] ?? _assetData?['updated_at'],
            'picture_path': fullAssetData['qr_code'] ?? '',
            'subcategory': {
              'subcategory_name':
                  fullAssetData['asset_master']?['subcategory_name'] ?? '-',
              'asset_type': _getSimplifiedAssetType(
                  fullAssetData['asset_master']?['asset_type'] ?? '-')
            },
            'brands': {
              'brand_name': fullAssetData['asset_master']?['brands']
                      ?['brand_name'] ??
                  fullAssetData['asset_master']?['brand']?['brand_name'] ??
                  fullAssetData['asset_master']?['brand_name'] ??
                  '-'
            },
            'room': {
              'room_name': fullAssetData['room_name'] ?? '-',
              'building': {
                'building_name': fullAssetData['building_name'] ?? '-'
              }
            },
            'responsible_user': fullAssetData['user_id'] != null
                ? {
                    'user_id': fullAssetData['user_id'] ?? '-',
                    'name': fullAssetData['employee_number'] ?? '-'
                  }
                : null,
            'description': fullAssetData['asset_master']?['description'] ?? '-'
          };

          // Set data aset yang telah dimap
          _assetData = mappedData;

          // Ambil data master aset
          if (fullAssetData['asset_master'] != null) {
            String assetType = _getSimplifiedAssetType(
                fullAssetData['asset_master']['asset_type'] ?? '-');

            // Get brand name from various possible sources
            String brandName = fullAssetData['asset_master']['brands']
                    ?['brand_name'] ??
                fullAssetData['asset_master']['brand']?['brand_name'] ??
                fullAssetData['asset_master']['brand_name'] ??
                '-';

            _masterAssetData = {
              'asset_master_code':
                  fullAssetData['asset_master']['asset_master_code'] ?? '-',
              'asset_name': fullAssetData['asset_master']['asset_name'] ?? '-',
              'asset_type': assetType,
              'subcategory_name':
                  fullAssetData['asset_master']['subcategory_name'] ?? '-',
              'brand_name': brandName,
              'needs_calibration':
                  fullAssetData['asset_master']['needs_calibration'] ?? false,
              'is_depreciable':
                  fullAssetData['asset_master']['is_depreciable'] ?? false,
              'description': fullAssetData['asset_master']['description'] ?? '-'
            };
            _isLoading = false;
          } else if (fullAssetData['asset_master_id'] != null) {
            // Jika ada asset_master_id tapi tidak ada nested asset_master, ambil data master
            await _fetchMasterAssetData(fullAssetData['asset_master_id'],
                context: context);
          } else {
            _hasError = true;
            _errorMessage = 'Data master aset tidak ditemukan';
            _isLoading = false;
          }
        } else {
          _hasError = true;
          _errorMessage =
              responseData['message'] ?? 'Gagal mengambil data aset';
          _isLoading = false;
        }
      } else {
        _hasError = true;
        _errorMessage =
            'Error ${response.statusCode}: Gagal mengambil data aset';
        _isLoading = false;
      }
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error: $e';
      _isLoading = false;
      LoggerUtil.e('[ASSET_DETAILS] Error saat mengambil data aset', e,
          StackTrace.current);
    } finally {
      // Pastikan loading state selalu di-reset di akhir proses
      _isLoading = false;
    }

    notifyListeners();
  }

  Future<void> _fetchMasterAssetData(int assetMasterId,
      {BuildContext? context}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      LoggerUtil.i(
          '[ASSET_DETAILS] Mengambil data master aset dengan ID: $assetMasterId');

      // Gunakan endpoint untuk mengambil data master aset berdasarkan ID
      final endpoint = '/asset-masters/$assetMasterId';

      LoggerUtil.d('[ASSET_DETAILS] Memanggil API endpoint: $endpoint');
      final response = await auth.ApiService.get(endpoint, context: context);

      LoggerUtil.d('[ASSET_DETAILS] Status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        LoggerUtil.d('[ASSET_DETAILS] Response data: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          final masterData = responseData['data'];

          // Map respons API ke format yang diharapkan aplikasi
          String assetType =
              _getSimplifiedAssetType(masterData['asset_type'] ?? '-');

          // Get brand name from various possible sources
          String brandName = masterData['brands']?['brand_name'] ??
              masterData['brand']?['brand_name'] ??
              masterData['brand_name'] ??
              '-';

          _masterAssetData = {
            'asset_master_code': masterData['asset_master_code'] ?? '-',
            'asset_name': masterData['asset_name'] ?? '-',
            'asset_type': assetType,
            'subcategory_name': masterData['subcategory_name'] ?? '-',
            'brand_name': brandName,
            'needs_calibration': masterData['needs_calibration'] ?? false,
            'is_depreciable': masterData['is_depreciable'] ?? false,
            'description': masterData['description'] ?? '-'
          };

          _isLoading = false;
          LoggerUtil.i(
              '[ASSET_DETAILS] Data master aset berhasil diambil: $_masterAssetData');
        } else {
          LoggerUtil.w(
              '[ASSET_DETAILS] Response sukses tapi data tidak valid: ${responseData['message']}');
          _hasError = true;
          _errorMessage =
              responseData['message'] ?? 'Data master aset tidak ditemukan';
          _isLoading = false;
        }
      } else {
        LoggerUtil.w('[ASSET_DETAILS] Error API: ${response.statusCode}');
        _hasError = true;
        _errorMessage =
            'Error ${response.statusCode}: Gagal mengambil data master aset';
        _isLoading = false;
      }
    } catch (e) {
      LoggerUtil.e('[ASSET_DETAILS] Exception saat mengambil data', e,
          StackTrace.current);
      _hasError = true;
      _errorMessage = 'Error: $e';
      _isLoading = false;
    } finally {
      // Pastikan loading state selalu di-reset di akhir proses
      _isLoading = false;
    }

    notifyListeners();
  }

  // Fungsi untuk mendapatkan warna status
  Color getStatusColor(String status) {
    // Debug - tampilkan status yang diterima
    LoggerUtil.d('[DETAIL DEBUG] Mendapatkan warna untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke uppercase
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'TERSEDIA':
        return const Color(0xFF7CB60C); // Hijau
      case 'CHECK OUT':
      case 'DIPINJAM':
      case 'CHECKOUT':
        return const Color(0xFFDAAE0F); // Kuning (sesuai history_screen)
      case 'UNDER REPAIR':
      case 'PERBAIKAN':
      case 'UNDERREPAIR':
        return const Color(0xFF25B1FF); // Biru (sesuai history_screen)
      case 'DISPOSE':
      case 'DISPOSED':
      case 'DIHAPUSKAN':
        return const Color(0xFFACC3EF); // Abu-abu (sesuai history_screen)
      case 'LOST':
      case 'HILANG':
        return const Color(0xFFFF4A2B); // Merah (sesuai history_screen)
      default:
        LoggerUtil.w(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return const Color(0xFF7A7A7A); // Default Abu-abu
    }
  }

  // Fungsi untuk mendapatkan teks status
  String getStatusText(String status) {
    // Debug - tampilkan status yang diterima
    LoggerUtil.d('[DETAIL DEBUG] Mendapatkan teks untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke uppercase
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return 'TERSEDIA';
      case 'CHECK OUT':
      case 'CHECKOUT':
        return 'DIPINJAM';
      case 'UNDER REPAIR':
      case 'UNDERREPAIR':
        return 'PERBAIKAN';
      case 'DISPOSE':
      case 'DISPOSED':
        return 'DIHAPUSKAN';
      case 'LOST':
        return 'HILANG';
      default:
        LoggerUtil.w(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return 'TERSEDIA';
    }
  }

  // Fungsi untuk mendapatkan ikon status
  IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'LOST':
      case 'HILANG':
        return Icons.help_outline;
      case 'DISPOSE':
      case 'DIHAPUSKAN':
        return Icons.delete_outline;
      case 'UNDER REPAIR':
      case 'PERBAIKAN':
        return Icons.build_outlined;
      default:
        return Icons.error_outline;
    }
  }

  // Fungsi untuk mendapatkan pesan status unavailable
  String getStatusUnavailableMessage(String status) {
    switch (status.toUpperCase()) {
      case 'LOST':
      case 'HILANG':
        return 'Aset Ini Dilaporkan Hilang';
      case 'DISPOSE':
      case 'DIHAPUSKAN':
        return 'Aset Ini Telah Dibuang';
      case 'UNDER REPAIR':
      case 'PERBAIKAN':
        return 'Aset Ini Sedang Dalam Perbaikan';
      default:
        return 'Aset Tidak Tersedia';
    }
  }

  // Fungsi untuk mendapatkan warna background notifikasi
  Color getStatusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'LOST':
      case 'HILANG':
        return Colors.white;
      case 'DISPOSE':
      case 'DIHAPUSKAN':
        return Colors.white;
      case 'UNDER REPAIR':
      case 'PERBAIKAN':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  // Fungsi untuk mendapatkan warna border notifikasi
  Color getStatusBorderColor(String status) {
    switch (status.toUpperCase()) {
      case 'LOST':
      case 'HILANG':
        return Colors.red.shade200;
      case 'DISPOSE':
      case 'DIHAPUSKAN':
        return Colors.grey.shade300;
      case 'UNDER REPAIR':
      case 'PERBAIKAN':
        return Colors.blue.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  // Format mata uang
  String formatCurrency(dynamic value) {
    if (value == null) return '-';
    try {
      double numValue = double.parse(value.toString());
      return numValue.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } catch (e) {
      return value.toString();
    }
  }

  // Format tanggal
  String formatDate(String date) {
    if (date == '-' || date == null || date.isEmpty) {
      return '-';
    }

    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      LoggerUtil.e('[ASSET_DETAILS] Error formatting date: $date', e,
          StackTrace.current);
      return date;
    }
  }

  // Helper function untuk format boolean values
  String formatBoolean(bool value) {
    return value ? 'Ya' : 'Tidak';
  }

  // Fungsi untuk menerjemahkan kondisi ke Bahasa Indonesia
  String getIndonesianCondition(String condition) {
    if (condition == '-') return condition;

    // Format teks terlebih dahulu
    String formatted = formatText(condition);

    // Map terjemahan kondisi
    Map<String, String> conditionMap = {
      'Good': 'Baik',
      'Fair': 'Cukup Baik',
      'Poor': 'Buruk',
      'Excellent': 'Sangat Baik',
      'New': 'Baru',
      'Used': 'Bekas',
      'Damaged': 'Rusak',
      'Broken': 'Rusak Berat',
      'Needs Repair': 'Perlu Perbaikan',
      'Under Maintenance': 'Dalam Pemeliharaan',
      'Obsolete': 'Usang',
    };

    return conditionMap[formatted] ?? formatted;
  }

  // Helper untuk mendapatkan tipe aset yang disederhanakan
  String _getSimplifiedAssetType(String assetType) {
    if (assetType == '-') return assetType;

    if (assetType.toLowerCase().contains('medical') ||
        assetType.toLowerCase().contains('medis')) {
      return 'Medis';
    } else {
      return 'Non Medis';
    }
  }

  // Fungsi untuk menerjemahkan tipe aset ke Bahasa Indonesia
  String getIndonesianAssetType(String assetType) {
    if (assetType == '-') return assetType;

    // Format teks terlebih dahulu
    String formatted = formatText(assetType);

    // Gunakan fungsi helper untuk menyederhanakan tipe aset
    return _getSimplifiedAssetType(formatted);
  }

  // Format text hanya untuk Condition dan Asset Type
  String formatText(String text) {
    if (text == '-') return text;

    // Replace underscores and dashes with spaces
    String formatted = text.replaceAll('_', ' ').replaceAll('-', ' ');

    // Capitalize each word
    List<String> words = formatted.split(' ');
    words = words.map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).toList();

    return words.join(' ');
  }

  // Format tanggal API untuk menampilkan waktu lokal
  String formatAPIDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // Format tanggal dan waktu (DD MMM YYYY, HH:MM) dalam waktu lokal
      final formatter = DateFormat('dd MMM yyyy, HH:mm');
      return formatter.format(date.toLocal());
    } catch (e) {
      return '';
    }
  }
}
