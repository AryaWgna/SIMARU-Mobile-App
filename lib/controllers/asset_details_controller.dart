import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart' as auth;

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

  Future<void> fetchAssetData(String assetCode, {BuildContext? context}) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      print('[ASSET_DETAILS] Mengambil data aset untuk: $assetCode');

      // Gunakan endpoint untuk mengambil data aset berdasarkan kode/QR
      final endpoint = '/assets/qr/${Uri.encodeComponent(assetCode)}';

      print('[ASSET_DETAILS] Memanggil API endpoint: $endpoint');
      final response = await auth.ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final fullAssetData = responseData['data'];

          // Set data aset
          _assetData = fullAssetData;

          // Ambil data master aset
          if (fullAssetData['asset_master'] != null) {
            _masterAssetData = fullAssetData['asset_master'];
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
      print('[ASSET_DETAILS] Error saat mengambil data aset: $e');
    }

    notifyListeners();
  }

  Future<void> _fetchMasterAssetData(int assetMasterId,
      {BuildContext? context}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      print(
          '[ASSET_DETAILS] Mengambil data master aset dengan ID: $assetMasterId');

      // Gunakan endpoint untuk mengambil data master aset berdasarkan ID
      final endpoint = '/assets/$assetMasterId';

      print('[ASSET_DETAILS] Memanggil API endpoint: $endpoint');
      final response = await auth.ApiService.get(endpoint, context: context);

      print('[ASSET_DETAILS] Status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('[ASSET_DETAILS] Response data: $responseData');

        if (responseData['success'] == true && responseData['data'] != null) {
          _masterAssetData = responseData['data'];
          _isLoading = false;
          print(
              '[ASSET_DETAILS] Data master aset berhasil diambil: $_masterAssetData');
        } else {
          print(
              '[ASSET_DETAILS] Response sukses tapi data tidak valid: ${responseData['message']}');
          _hasError = true;
          _errorMessage =
              responseData['message'] ?? 'Data master aset tidak ditemukan';
          _isLoading = false;
        }
      } else {
        print('[ASSET_DETAILS] Error API: ${response.statusCode}');
        _hasError = true;
        _errorMessage =
            'Error ${response.statusCode}: Gagal mengambil data master aset';
        _isLoading = false;
      }
    } catch (e) {
      print('[ASSET_DETAILS] Exception saat mengambil data: $e');
      _hasError = true;
      _errorMessage = 'Error: $e';
      _isLoading = false;
    }

    notifyListeners();
  }

  // Fungsi untuk mendapatkan warna status
  Color getStatusColor(String status) {
    // Debug - tampilkan status yang diterima
    print('[DETAIL DEBUG] Mendapatkan warna untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke lowercase
    switch (status.toLowerCase()) {
      case 'available':
        return const Color(0xFF659B09); // Hijau
      case 'check out':
        return const Color(0xFF0086C3); // Biru
      case 'under repair':
        return const Color(0xFFFF9900); // Oranye
      case 'dispose':
        return const Color(0xFF7A7A7A); // Abu-abu
      case 'lost':
        return const Color(0xFFDC3545); // Merah
      default:
        print(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return const Color(0xFF659B09); // Default hijau
    }
  }

  // Fungsi untuk mendapatkan teks status
  String getStatusText(String status) {
    // Debug - tampilkan status yang diterima
    print('[DETAIL DEBUG] Mendapatkan teks untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke lowercase
    switch (status.toLowerCase()) {
      case 'available':
        return 'Tersedia';
      case 'check out':
        return 'Dipinjam';
      case 'under repair':
        return 'Perbaikan';
      case 'dispose':
        return 'Dibuang';
      case 'lost':
        return 'Hilang';
      default:
        print(
            '[DETAIL DEBUG] Status tidak dikenal: $status, menggunakan default');
        return 'Tersedia';
    }
  }

  // Fungsi untuk mendapatkan ikon status
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Icons.help_outline;
      case 'dispose':
        return Icons.delete_outline;
      case 'under repair':
        return Icons.build_outlined;
      default:
        return Icons.error_outline;
    }
  }

  // Fungsi untuk mendapatkan pesan status unavailable
  String getStatusUnavailableMessage(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return 'Aset Ini Dilaporkan Hilang';
      case 'dispose':
        return 'Aset Ini Telah Dibuang';
      case 'under repair':
        return 'Aset Ini Sedang Dalam Perbaikan';
      default:
        return 'Aset Tidak Tersedia';
    }
  }

  // Fungsi untuk mendapatkan warna background notifikasi
  Color getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Colors.red.shade50;
      case 'dispose':
        return Colors.grey.shade100;
      case 'under repair':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  // Fungsi untuk mendapatkan warna border notifikasi
  Color getStatusBorderColor(String status) {
    switch (status.toLowerCase()) {
      case 'lost':
        return Colors.red.shade200;
      case 'dispose':
        return Colors.grey.shade300;
      case 'under repair':
        return Colors.orange.shade200;
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
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
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

  // Fungsi untuk menerjemahkan tipe aset ke Bahasa Indonesia
  String getIndonesianAssetType(String assetType) {
    if (assetType == '-') return assetType;

    // Format teks terlebih dahulu
    String formatted = formatText(assetType);

    // Map terjemahan tipe aset
    Map<String, String> assetTypeMap = {
      'Fixed Asset': 'Aset Tetap',
      'Consumable': 'Barang Habis Pakai',
      'Equipment': 'Peralatan',
      'Furniture': 'Furnitur',
      'It Equipment': 'Peralatan IT',
      'Medical Equipment': 'Peralatan Medis',
      'Non Medical': 'Non Medis',
      'Non Medical Equipment': 'Peralatan Non Medis',
      'Office Equipment': 'Peralatan Kantor',
      'Vehicle': 'Kendaraan',
      'Building': 'Bangunan',
      'Land': 'Tanah',
    };

    return assetTypeMap[formatted] ?? formatted;
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
}
