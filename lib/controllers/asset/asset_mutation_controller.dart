import 'package:flutter/material.dart';
import 'dart:convert';
import '../auth/auth_controller.dart' as auth;
import '../../models/asset/asset_mutation_model.dart';
import '../../utils/logger_util.dart';
import 'package:intl/intl.dart';

class AssetMutationController extends ChangeNotifier {
  List<AssetMutationItem> _mutations = [];
  List<BuildingItem> _buildings = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Form fields
  int? _selectedBuildingId;
  int? _selectedRoomId;
  String _reason = '';

  // Getters
  List<AssetMutationItem> get mutations => _mutations;
  List<BuildingItem> get buildings => _buildings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  int? get selectedBuildingId => _selectedBuildingId;
  int? get selectedRoomId => _selectedRoomId;
  String get reason => _reason;

  // Setters
  set selectedBuildingId(int? value) {
    _selectedBuildingId = value;
    // Reset room when building changes
    _selectedRoomId = null;
    notifyListeners();
  }

  set selectedRoomId(int? value) {
    _selectedRoomId = value;
    notifyListeners();
  }

  set reason(String value) {
    _reason = value;
    notifyListeners();
  }

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('AssetMutationController loading state set to: $_isLoading');
    }
  }

  // Mengambil riwayat mutasi aset berdasarkan asset_id
  Future<void> fetchAssetMutations(int assetId, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final endpoint = '/assets/$assetId/mutations';
      final response = await auth.ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> mutationsJson = data['data'];
          _mutations = mutationsJson
              .map((json) => AssetMutationItem.fromJson(json))
              .toList();
        } else {
          _error = data['message'] ?? 'Gagal mengambil data mutasi aset';
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error fetching asset mutations', e, StackTrace.current);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengambil daftar gedung dan ruangan
  Future<void> fetchBuildings(BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final endpoint = '/buildings?include=rooms';
      final response = await auth.ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> buildingsJson = data['data'];
          _buildings =
              buildingsJson.map((json) => BuildingItem.fromJson(json)).toList();
        } else {
          _error = data['message'] ?? 'Gagal mengambil data gedung';
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error fetching buildings', e, StackTrace.current);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mendapatkan ruangan untuk gedung yang dipilih
  List<RoomItem> getRoomsForSelectedBuilding() {
    if (_selectedBuildingId == null) return [];

    final building = _buildings.firstWhere(
      (b) => b.buildingId == _selectedBuildingId,
      orElse: () => BuildingItem(
        buildingId: 0,
        buildingName: '',
        rooms: [],
      ),
    );

    return building.rooms;
  }

  // Membuat permintaan mutasi aset
  Future<bool> createMutation(int assetId, BuildContext context) async {
    if (_selectedRoomId == null) {
      _error = 'Ruangan tujuan harus dipilih';
      notifyListeners();
      return false;
    }

    if (_reason.trim().isEmpty) {
      _error = 'Alasan mutasi harus diisi';
      notifyListeners();
      return false;
    }

    try {
      _isSaving = true;
      _error = null;
      notifyListeners();

      final endpoint = '/assets/$assetId/mutations';

      final mutationData = {
        'to_room_id': _selectedRoomId,
        'reason': _reason,
      };

      final response = await auth.ApiService.post(endpoint,
          body: mutationData, context: context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Reset form
          _selectedBuildingId = null;
          _selectedRoomId = null;
          _reason = '';

          // Refresh mutations
          await fetchAssetMutations(assetId, context);

          return true;
        } else {
          _error = data['message'] ?? 'Gagal membuat mutasi aset';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error creating mutation', e, StackTrace.current);
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<dynamic> _statusHistories = [];
  int _refreshCount = 0;

  List<dynamic> get statusHistories => _statusHistories;
  int get refreshCount => _refreshCount;

  void incrementRefreshCount() {
    _refreshCount++;
    if (_refreshCount >= 3) {
      _refreshCount = 0;
    }
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> fetchAssetStatusHistories(String assetId,
      {BuildContext? context, bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      LoggerUtil.i('Mengambil riwayat status untuk aset dengan ID: $assetId');

      // Gunakan endpoint untuk riwayat status aset
      final endpoint = '/asset-histories/status/$assetId';
      LoggerUtil.d('Endpoint yang digunakan: $endpoint');

      final response = await auth.ApiService.get(
        endpoint,
        context: context,
      );

      LoggerUtil.d('Response status: ${response.statusCode}');
      LoggerUtil.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> histories = [];
          if (data['data'] != null) {
            if (data['data'] is List) {
              // Jika data adalah array langsung
              histories = data['data'];
            } else if (data['data']['histories'] != null &&
                data['data']['histories'] is List) {
              // Struktur data dengan histories
              histories = data['data']['histories'];
            } else if (data['data']['items'] != null &&
                data['data']['items'] is List) {
              // Struktur data dengan items
              histories = data['data']['items'];
            }
            LoggerUtil.d(
                'Jumlah riwayat status ditemukan: ${histories.length}');
          }

          _statusHistories = histories;
          _isLoading = false;
          notifyListeners();
        } else {
          _isLoading = false;
          _error = data['message'] ?? 'Gagal memuat riwayat status aset';
          notifyListeners();
        }
      } else if (response.statusCode == 404) {
        _isLoading = false;
        _statusHistories = [];
        notifyListeners();
      } else if (response.statusCode == 500) {
        // Handle error 500 dengan pesan yang lebih jelas
        String serverError;
        try {
          final data = json.decode(response.body);
          serverError =
              data['message'] ?? 'Terjadi kesalahan pada server (500)';
        } catch (e) {
          serverError = 'Terjadi kesalahan pada server (500)';
        }

        LoggerUtil.e('Error 500: $serverError', null, StackTrace.current);
        _isLoading = false;
        _error =
            'Kesalahan server: $serverError. Silakan coba dengan ID aset yang benar.';
        notifyListeners();
      } else {
        _isLoading = false;
        _error =
            'Error ${response.statusCode}: Gagal memuat riwayat status aset';
        notifyListeners();
      }
    } catch (e) {
      LoggerUtil.e(
          'Exception saat mengambil riwayat status', e, StackTrace.current);
      _isLoading = false;
      _error = 'Terjadi kesalahan: $e';
      notifyListeners();
    }
  }

  // Fungsi untuk mendapatkan warna status
  Color getStatusColor(String status) {
    // Debug - tampilkan status yang diterima
    LoggerUtil.d('[MUTATION DEBUG] Mendapatkan warna untuk status: $status');

    // Gunakan status yang sudah dinormalisasi ke uppercase
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'TERSEDIA':
        return const Color(0xFF7CB60C); // Hijau
      case 'CHECK OUT':
      case 'CHECKED OUT':
      case 'DIPINJAM':
      case 'DIPINJAM KE LOKASI':
      case 'DIPINJAM KE KARYAWAN':
        return const Color(0xFFDAAE0F); // Kuning
      case 'UNDER REPAIR':
      case 'PERBAIKAN':
        return const Color(0xFF25B1FF); // Biru
      case 'DISPOSE':
      case 'DISPOSED':
      case 'DIHAPUSKAN':
        return const Color(
            0xFFACC3EF); // Abu-abu (sesuai asset_details_controller)
      case 'LOSS':
      case 'LOST':
      case 'HILANG':
        return const Color(0xFFFF4A2B); // Merah
      case 'FOUND':
      case 'DITEMUKAN':
        return const Color(0xFF7CB60C); // Hijau (sama seperti available)
      case 'RETURN':
      case 'DIKEMBALIKAN':
        return const Color(0xFF659B09); // Hijau tua
      default:
        LoggerUtil.w(
            '[MUTATION DEBUG] Status tidak dikenal: $status, menggunakan default');
        return const Color(0xFF7A7A7A); // Default Abu-abu
    }
  }

  // Format tanggal
  String formatDate(DateTime date) {
    // Format untuk Indonesia: DD Bulan YYYY
    List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Format hari
  String formatDay(DateTime date) {
    // Nama hari dalam bahasa Indonesia
    List<String> days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    return days[date.weekday % 7];
  }

  // Format tanggal dari API
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

  // Format tanggal API
  String formatAPIDateParam(DateTime date) {
    // Format tanggal yang diharapkan API: YYYY-MM-DD
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
