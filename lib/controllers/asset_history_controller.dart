import 'package:flutter/material.dart';
import 'dart:convert';
import '../controllers/auth_controller.dart' as auth;
import '../models/asset_history_item_model.dart';

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

  // Getters
  List<AssetHistoryItem> get histories =>
      _filteredHistories.isNotEmpty ? _filteredHistories : _histories;
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
      print('AssetHistoryController loading state set to: $_isLoading');
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

  // Method untuk memfilter riwayat berdasarkan tanggal yang dipilih
  void filterHistoriesByDate() {
    final selectedDateStr = formatDateForComparison(_selectedDate);

    _filteredHistories = _histories.where((history) {
      final historyDateStr = formatDateForComparison(history.actionDate);
      return historyDateStr == selectedDateStr;
    }).toList();

    print('Tanggal terpilih: $selectedDateStr');
    print('Total riwayat: ${_histories.length}');
    print('Riwayat terfilter: ${_filteredHistories.length}');

    // Pastikan notifyListeners dipanggil agar UI diperbarui
    notifyListeners();
  }

  // Helper untuk format tanggal untuk perbandingan (YYYY-MM-DD)
  String formatDateForComparison(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Format tanggal untuk parameter API
  String formatAPIDateParam(DateTime date) {
    // Format tanggal yang diharapkan API: DD-MM-YYYY
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
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

      // Format tanggal untuk parameter API: DD-MM-YYYY
      final selectedDateStr = formatAPIDateParam(_selectedDate);

      // Menggunakan endpoint dengan parameter tanggal
      final endpoint = '/asset-histories/$assetIdStr?date=$selectedDateStr';
      print('Memanggil API endpoint: $endpoint');
      print('Tanggal yang dipilih: $selectedDateStr');

      final response = await auth.ApiService.get(endpoint, context: context);
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response data: $data');

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
            }
          }

          print('Jumlah riwayat dari API: ${allHistories.length}');

          // Konversi ke model AssetHistoryItem
          _histories = allHistories
              .map((json) => AssetHistoryItem.fromJson(json))
              .toList();

          // Urutkan riwayat berdasarkan waktu terbaru
          _histories.sort((a, b) => b.actionDate.compareTo(a.actionDate));

          // Tidak perlu filter lagi karena API sudah mengembalikan data sesuai tanggal
          _filteredHistories = _histories;

          print('Berhasil mendapatkan ${_histories.length} riwayat aset');
        } else {
          _error = data['message'] ?? 'Gagal mengambil riwayat aset';
          print('Error dari API: $_error');
          _histories = [];
          _filteredHistories = [];
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
        print('HTTP Error: ${response.statusCode}');
        _histories = [];
        _filteredHistories = [];
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching asset history: $e');
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

  // Method untuk memperbarui UI ketika halaman dibuka kembali
  void refreshUI() {
    // Pastikan UI diperbarui
    notifyListeners();
  }

  // Method untuk mengubah tanggal terpilih dan langsung mengambil data baru
  Future<void> updateSelectedDateAndFetch(
      DateTime date, int assetId, BuildContext context) async {
    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    // Langsung ambil data baru dengan tanggal yang dipilih
    await fetchAssetHistory(assetId, context);
  }

  // Method untuk mengubah hari (+/-) dan langsung mengambil data baru
  Future<void> changeDayAndFetch(
      int days, int assetId, BuildContext context) async {
    _selectedDate = _selectedDate.add(Duration(days: days));
    _isLoading = true;
    notifyListeners();

    // Langsung ambil data baru dengan tanggal yang dipilih
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
    notifyListeners();
  }
}
