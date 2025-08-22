import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/auth_controller.dart' as auth;
import '../../models/asset/asset_history_item_model.dart';
import '../../utils/logger_util.dart';
import 'package:intl/intl.dart';

class HistoryPagination {
  final int currentPage;
  final int totalPages;
  final int perPage;
  final bool hasNext;
  final bool hasPrev;

  HistoryPagination({
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
    required this.hasNext,
    required this.hasPrev,
  });

  factory HistoryPagination.fromJson(Map<String, dynamic> json) {
    return HistoryPagination(
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      perPage: json['per_page'] ?? 10,
      hasNext: json['has_next'] ?? false,
      hasPrev: json['has_prev'] ?? false,
    );
  }
}

class AssetHistoryController extends ChangeNotifier {
  List<AssetHistoryItem> _histories = [];
  List<AssetHistoryItem> _filteredHistories = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pagination;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _limit = 10;
  DateTime _selectedDate = DateTime.now();
  bool _hasFilteredOnce =
      false; // Track apakah filtering sudah pernah dilakukan

  // Getters - FIXED: Always return filtered results, even if empty
  List<AssetHistoryItem> get histories {
    // Jika sudah pernah melakukan filtering, selalu return hasil filter (bahkan jika kosong)
    // Jika belum pernah filtering, return semua data
    final shouldReturnFiltered =
        _filteredHistories.isNotEmpty || _hasFilteredOnce;
    final result = shouldReturnFiltered ? _filteredHistories : _histories;

    LoggerUtil.d(
        '🔍 GETTER DEBUG: _hasFilteredOnce=$_hasFilteredOnce, _filteredHistories.length=${_filteredHistories.length}, _histories.length=${_histories.length}, returning ${result.length} items');

    return result;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get pagination => _pagination;
  bool get hasMoreData => _hasMoreData;
  DateTime get selectedDate => _selectedDate;

  // Method untuk mengubah tanggal terpilih
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _isLoading = true; // Set loading saat tanggal berubah
    notifyListeners();
  }

  // Method untuk mengubah hari (+/-)
  void changeDay(int days) {
    _selectedDate = _selectedDate.add(Duration(days: days));
    _isLoading = true; // Set loading saat tanggal berubah
    notifyListeners();
  }

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('AssetHistoryController loading state set to: $_isLoading');
    }
  }

  // Method untuk mengatur error secara manual
  void setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Method untuk memfilter riwayat berdasarkan tanggal
  void setFilteredHistories(List<AssetHistoryItem> filteredHistories) {
    _filteredHistories = filteredHistories;
    notifyListeners();
  }

  // Method untuk memfilter riwayat berdasarkan tanggal yang dipilih (STRICT VERSION)
  void filterHistoriesByDate() {
    final selectedDateStr = formatDateForComparison(_selectedDate);

    LoggerUtil.d('=== MULAI STRICT DATE FILTER DEBUG ===');
    LoggerUtil.d('Tanggal yang dipilih: $_selectedDate');
    LoggerUtil.d('Tanggal terpilih (formatted): $selectedDateStr');
    LoggerUtil.d('Total riwayat sebelum filter: ${_histories.length}');

    // Mark bahwa filtering sudah pernah dilakukan
    _hasFilteredOnce = true;

    _filteredHistories = _histories.where((history) {
      // Multiple validation untuk memastikan akurasi
      final historyDateStr = formatDateForComparison(history.actionDate);

      // Validation 1: String comparison
      final stringMatch = historyDateStr == selectedDateStr;

      // Validation 2: Component-wise comparison untuk extra safety
      final componentMatch = _selectedDate.year == history.actionDate.year &&
          _selectedDate.month == history.actionDate.month &&
          _selectedDate.day == history.actionDate.day;

      // Validation 3: DateTime comparison (normalize ke date-only)
      final selectedDateOnly =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final historyDateOnly = DateTime(history.actionDate.year,
          history.actionDate.month, history.actionDate.day);
      final dateTimeMatch = selectedDateOnly.isAtSameMomentAs(historyDateOnly);

      // SEMUA validation harus TRUE untuk lolos filter
      final isMatch = stringMatch && componentMatch && dateTimeMatch;

      // Log hanya untuk item yang tidak match atau yang bermasalah
      if (!isMatch ||
          (stringMatch != componentMatch || componentMatch != dateTimeMatch)) {
        LoggerUtil.d(
            '=== ITEM VALIDATION (${isMatch ? 'FAILED VALIDATION' : 'NO MATCH'}) ===');
        LoggerUtil.d('History: ${history.actionDate} -> $historyDateStr');
        LoggerUtil.d('Selected: $_selectedDate -> $selectedDateStr');
        LoggerUtil.d(
            'String match: $stringMatch, Component match: $componentMatch, DateTime match: $dateTimeMatch');
        LoggerUtil.d('Final result: $isMatch');
      }

      // Alert jika ada inconsistency dalam validation
      if (stringMatch != componentMatch ||
          componentMatch != dateTimeMatch ||
          stringMatch != dateTimeMatch) {
        LoggerUtil.e(
            'VALIDATION INCONSISTENCY! String: $stringMatch, Component: $componentMatch, DateTime: $dateTimeMatch');
        LoggerUtil.e(
            'History date: ${history.actionDate}, Selected date: $_selectedDate');
      }

      return isMatch;
    }).toList();

    LoggerUtil.d('Riwayat setelah STRICT filter: ${_filteredHistories.length}');

    // Improved result validation
    if (_filteredHistories.isEmpty) {
      LoggerUtil.i('✓ CORRECT: Tidak ada data untuk tanggal $selectedDateStr');

      // Show available dates for reference
      LoggerUtil.d('Available dates (first 5):');
      for (int i = 0; i < _histories.length && i < 5; i++) {
        final historyDateStr =
            formatDateForComparison(_histories[i].actionDate);
        LoggerUtil.d('  [$i] ${_histories[i].actionDate} -> $historyDateStr');
      }
    } else {
      LoggerUtil.i(
          '✓ FOUND: ${_filteredHistories.length} item(s) untuk tanggal $selectedDateStr');

      // Double-check: Pastikan semua hasil filter benar-benar sesuai tanggal
      bool hasWrongData = false;
      for (int i = 0; i < _filteredHistories.length; i++) {
        final item = _filteredHistories[i];
        final itemDateStr = formatDateForComparison(item.actionDate);
        if (itemDateStr != selectedDateStr) {
          LoggerUtil.e(
              '❌ ERROR: Item [$i] has WRONG DATE: ${item.actionDate} -> $itemDateStr (expected: $selectedDateStr)');
          hasWrongData = true;
        }
      }

      if (!hasWrongData) {
        LoggerUtil.i(
            '✓ VALIDATION PASSED: All filtered items have correct date');
      }
    }

    LoggerUtil.d('=== SELESAI STRICT DATE FILTER DEBUG ===');

    // Pastikan notifyListeners dipanggil agar UI diperbarui
    notifyListeners();
  }

  // Helper untuk format tanggal untuk perbandingan (YYYY-MM-DD) - STRICT VERSION
  String formatDateForComparison(DateTime date) {
    // Handle timezone issues: convert ke local time dulu
    final localTime = date.toLocal();

    // Extract hanya komponen tanggal, ignore waktu
    final dateOnly = DateTime(localTime.year, localTime.month, localTime.day);

    // Format ke string dengan padding zero
    final formatted =
        '${dateOnly.year}-${dateOnly.month.toString().padLeft(2, '0')}-${dateOnly.day.toString().padLeft(2, '0')}';

    // Debug logging untuk konversi timezone (hanya jika ada perbedaan signifikan)
    if ((date.timeZoneOffset.inHours.abs() > 0 &&
            (date.hour != 0 || date.minute != 0)) ||
        (localTime.day != date.day)) {
      LoggerUtil.d(
          'Timezone conversion: $date -> Local: $localTime -> DateOnly: $dateOnly -> Formatted: $formatted');
    }

    return formatted;
  }

  // Format tanggal untuk parameter API
  String formatAPIDateParam(DateTime date) {
    // Format tanggal yang diharapkan API: YYYY-MM-DD (format ISO standar)
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Format tanggal dari API ke format lokal
  String formatAPIDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // Format tanggal dan waktu (HH:MM) dalam waktu lokal
      final formatter = DateFormat('HH:mm');
      return formatter.format(date.toLocal());
    } catch (e) {
      return '';
    }
  }

  // Mengambil riwayat aset berdasarkan asset_id
  Future<void> fetchAssetHistory(dynamic assetId, BuildContext context,
      {bool refresh = true, bool showLoading = true}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    if (!_hasMoreData && !refresh) return;

    try {
      if (showLoading) {
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      // Convert assetId ke string jika perlu
      String assetIdStr = assetId.toString();

      // Format tanggal untuk parameter API: YYYY-MM-DD
      final selectedDateStr = formatAPIDateParam(_selectedDate);

      // Langsung gunakan endpoint tanpa parameter date (karena API tidak support date filter)
      // Kita akan lakukan filtering di client-side
      String endpoint = '/asset-histories/$assetIdStr';
      LoggerUtil.d('Memanggil API endpoint: $endpoint');
      LoggerUtil.d(
          'Tanggal yang dipilih untuk filter client-side: $selectedDateStr');

      http.Response response =
          await auth.ApiService.get(endpoint, context: context);
      LoggerUtil.d('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerUtil.d('Response data received');
        LoggerUtil.d('Full response: ${jsonEncode(data)}');

        if (data['success'] == true) {
          List<dynamic> allHistories = [];

          // Cek format respons - biasanya dalam 'data.histories'
          if (data['data'] != null) {
            if (data['data'] is List) {
              // Jika data adalah array langsung
              allHistories = data['data'];
            } else if (data['data']['histories'] != null) {
              // Format yang diharapkan: data.histories
              allHistories = data['data']['histories'];
            } else if (data['data']['items'] != null) {
              // Alternatif: data.items
              allHistories = data['data']['items'];
            } else {
              // Cek key lain yang mungkin
              LoggerUtil.d(
                  'Struktur data tidak dikenal, keys: ${data['data'].keys}');
              // Ambil semua values yang berupa List
              for (var value in data['data'].values) {
                if (value is List) {
                  allHistories = value;
                  break;
                }
              }
            }
          }

          LoggerUtil.d('Jumlah total riwayat dari API: ${allHistories.length}');

          // Konversi ke model AssetHistoryItem
          _histories = allHistories
              .map((json) => AssetHistoryItem.fromJson(json))
              .toList();

          // Urutkan riwayat berdasarkan waktu terbaru
          _histories.sort((a, b) => b.actionDate.compareTo(a.actionDate));

          // Selalu lakukan filter di client-side karena API tidak support date filtering
          filterHistoriesByDate();
          LoggerUtil.d(
              'Filter client-side selesai, hasil: ${_filteredHistories.length} dari ${_histories.length} item');

          LoggerUtil.i(
              'Berhasil mendapatkan ${_histories.length} total riwayat, ${_filteredHistories.length} sesuai tanggal');
        } else {
          _error = data['message'] ?? 'Gagal mengambil riwayat aset';
          LoggerUtil.w('Error dari API: $_error');
          _histories = [];
          _filteredHistories = [];
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
        LoggerUtil.w('HTTP Error: ${response.statusCode}');
        _histories = [];
        _filteredHistories = [];
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error fetching asset history', e, StackTrace.current);
      _histories = [];
      _filteredHistories = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // Pastikan UI diperbarui setelah data diambil
    }
  }

  // Memuat lebih banyak riwayat
  Future<void> loadMoreHistory(int assetId, BuildContext context) async {
    if (_isLoading || !_hasMoreData) return;
    await fetchAssetHistory(assetId, context, refresh: false);
  }

  // Mengelompokkan riwayat berdasarkan bulan/tahun
  Map<String, List<AssetHistoryItem>> getHistoriesByMonth() {
    Map<String, List<AssetHistoryItem>> result = {};

    for (var item in histories) {
      String key =
          '${_getMonthName(item.actionDate.month)} ${item.actionDate.year}';

      if (!result.containsKey(key)) {
        result[key] = [];
      }

      result[key]!.add(item);
    }

    return result;
  }

  // Helper untuk mendapatkan nama bulan dalam Bahasa Indonesia
  String _getMonthName(int month) {
    const months = [
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

    return months[month - 1];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Debug utility untuk memeriksa data filtering
  void debugFilteringData() {
    LoggerUtil.d('=== FILTERING DATA DEBUG ===');
    LoggerUtil.d('Selected date: $_selectedDate');
    LoggerUtil.d('Has filtered once: $_hasFilteredOnce');
    LoggerUtil.d('Total histories: ${_histories.length}');
    LoggerUtil.d('Filtered histories: ${_filteredHistories.length}');
    LoggerUtil.d('Getter will return: ${histories.length} items');

    // Group data by date untuk melihat distribusi
    final Map<String, int> dateDistribution = {};
    for (var history in _histories) {
      final dateStr = formatDateForComparison(history.actionDate);
      dateDistribution[dateStr] = (dateDistribution[dateStr] ?? 0) + 1;
    }

    LoggerUtil.d('Date distribution in _histories:');
    dateDistribution.entries.forEach((entry) {
      LoggerUtil.d('  ${entry.key}: ${entry.value} items');
    });

    LoggerUtil.d('==========================');
  }

  // Method untuk memperbarui UI ketika halaman dibuka kembali
  void refreshUI() {
    // Pastikan UI diperbarui
    notifyListeners();
  }

  // Method untuk mengubah tanggal terpilih dan filter ulang (optimized - tidak memanggil API)
  void updateSelectedDateAndFilter(DateTime date) {
    final oldDate = _selectedDate;
    _selectedDate = date;
    LoggerUtil.d('🗓️ PILIH TANGGAL: $oldDate → $_selectedDate');

    // Jika sudah ada data, langsung filter ulang tanpa memanggil API
    if (_histories.isNotEmpty) {
      filterHistoriesByDate();
    } else {
      // Jika belum ada data, set loading state
      _isLoading = true;
      notifyListeners();
    }
  }

  // Method untuk mengubah tanggal terpilih dan langsung mengambil data baru (fallback method)
  Future<void> updateSelectedDateAndFetch(
      DateTime date, int assetId, BuildContext context) async {
    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    // Langsung ambil data baru dengan tanggal yang dipilih
    await fetchAssetHistory(assetId, context);
  }

  // Method untuk fetch data tanpa mengubah tanggal (untuk konsistensi)
  Future<void> updateSelectedDateAndFetchOnly(
      int assetId, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Langsung ambil data baru dengan tanggal yang SUDAH diubah sebelumnya
    await fetchAssetHistory(assetId, context);
  }

  // Method untuk mengubah hari (+/-) dan filter ulang (optimized)
  void changeDayAndFilter(int days) {
    final oldDate = _selectedDate;
    _selectedDate = _selectedDate.add(Duration(days: days));
    LoggerUtil.d(
        '🗓️ NAVIGASI HARI: $oldDate → $_selectedDate (${days > 0 ? '+' : ''}$days hari)');

    // Jika sudah ada data, langsung filter ulang tanpa memanggil API
    if (_histories.isNotEmpty) {
      filterHistoriesByDate();
    } else {
      // Jika belum ada data, set loading state
      _isLoading = true;
      notifyListeners();
    }
  }

  // Method untuk mengubah hari (+/-) dan langsung mengambil data baru (fallback method)
  // PENTING: Tanggal sudah diubah di changeDayAndFilter, jangan ubah lagi di sini!
  Future<void> changeDayAndFetchOnly(int assetId, BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Langsung ambil data baru dengan tanggal yang SUDAH diubah sebelumnya
    await fetchAssetHistory(assetId, context);
  }

  // Reset controller saat halaman ditutup
  void reset() {
    _histories = [];
    _filteredHistories = [];
    _error = null;
    _currentPage = 1;
    _hasMoreData = true;
    _isLoading = false;
    _hasFilteredOnce = false; // Reset filtering flag
    notifyListeners();
  }

  // Fungsi untuk mendapatkan warna status
  Color getStatusColor(String status) {
    // Debug - tampilkan status yang diterima
    LoggerUtil.d('[HISTORY DEBUG] Mendapatkan warna untuk status: $status');

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
            '[HISTORY DEBUG] Status tidak dikenal: $status, menggunakan default');
        return const Color(0xFF7A7A7A); // Default Abu-abu
    }
  }
}
