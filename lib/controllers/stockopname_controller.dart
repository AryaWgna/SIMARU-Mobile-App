import 'package:flutter/material.dart';
import '../models/stockopname_model.dart';
import '../controllers/auth_controller.dart' as auth;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../utils/logger_util.dart';

class StockOpnameController extends ChangeNotifier {
  List<StockOpnameItem> _scannedItems = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _summary;

  // Variabel untuk manajemen stockopname
  List<Building> _buildings = [];
  Building? _selectedBuilding;
  List<Room> _rooms = [];
  List<Room> _filteredRooms = [];
  List<StockOpname> _pendingOpnames = [];
  bool _isLoadingBuildings = false;
  bool _isLoadingMoreBuildings = false;
  bool _isLoadingRooms = false;
  bool _isCreatingOpname = false;

  // Variabel untuk pagination
  int _currentBuildingPage = 1;
  int _totalBuildingPages = 1;
  bool _hasMoreBuildings = true;
  int _buildingLimit = 10;

  // Tambahan variabel untuk scanner
  String? _scannedCode;
  String? _lastScannedCode;
  bool _flashOn = false;
  bool _isFlashAvailable = false;
  bool _isBackCamera = true;
  bool _processingQR = false;

  // Variabel untuk debounce search
  Timer? _buildingSearchDebounce;
  Timer? _roomSearchDebounce;
  String _lastBuildingSearchQuery = '';
  String _lastRoomSearchQuery = '';

  // Getters
  List<StockOpnameItem> get scannedItems => _scannedItems;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get summary => _summary;

  // Getters untuk manajemen stockopname
  List<Building> get buildings => _buildings;
  Building? get selectedBuilding => _selectedBuilding;
  List<Room> get rooms => _rooms;
  List<Room> get filteredRooms => _filteredRooms;
  List<StockOpname> get pendingOpnames => _pendingOpnames;
  bool get isLoadingBuildings => _isLoadingBuildings;
  bool get isLoadingMoreBuildings => _isLoadingMoreBuildings;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isCreatingOpname => _isCreatingOpname;

  // Getters untuk pagination
  int get currentBuildingPage => _currentBuildingPage;
  int get totalBuildingPages => _totalBuildingPages;
  bool get hasMoreBuildings => _hasMoreBuildings;

  // Getters untuk scanner
  String? get scannedCode => _scannedCode;
  String? get lastScannedCode => _lastScannedCode;
  bool get flashOn => _flashOn;
  bool get isFlashAvailable => _isFlashAvailable;
  bool get isBackCamera => _isBackCamera;
  bool get processingQR => _processingQR;

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('StockOpnameController loading state set to: $_isLoading');
    }
  }

  // Metode untuk scanner
  void setScannedCode(String? code) {
    _scannedCode = code;
    notifyListeners();
  }

  void setLastScannedCode(String? code) {
    _lastScannedCode = code;
    notifyListeners();
  }

  void toggleFlash() {
    _flashOn = !_flashOn;
    notifyListeners();
  }

  void setFlash(bool on) {
    _flashOn = on;
    notifyListeners();
  }

  void setFlashAvailability(bool available) {
    _isFlashAvailable = available;
    notifyListeners();
  }

  void toggleCamera() {
    _isBackCamera = !_isBackCamera;
    notifyListeners();
  }

  void setProcessingQR(bool processing) {
    _processingQR = processing;
    notifyListeners();
  }

  // Menambahkan item yang dipindai
  void addScannedItem(StockOpnameItem item) {
    // Cek apakah item sudah ada
    final existingIndex = _scannedItems
        .indexWhere((element) => element.assetCode == item.assetCode);

    if (existingIndex == -1) {
      _scannedItems.add(item);
      notifyListeners();
    }
  }

  // Mendapatkan data aset dari QR code
  Future<StockOpnameItem?> getAssetByQrCode(
      String qrCode, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final endpoint = '/assets/qr/${Uri.encodeComponent(qrCode)}';
      final response = await auth.ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final assetData = responseData['data'];

          return StockOpnameItem(
            assetId: assetData['id'],
            assetCode: assetData['asset_code'],
            assetName: assetData['asset_name'],
            location: assetData['room']?['room_name'] ?? 'Tidak diketahui',
            condition: assetData['condition'] ?? 'Tidak diketahui',
            currentStatus: assetData['current_status'] ?? 'Tidak diketahui',
            scanTime: DateTime.now(),
          );
        } else {
          _error = responseData['message'] ?? 'Gagal mengambil data aset';
          notifyListeners();
          return null;
        }
      } else {
        _error = 'Error ${response.statusCode}: Gagal mengambil data aset';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Memproses QR yang dipindai
  Future<bool> processScannedQR(
      String qrCode, int opnameId, int roomId, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final assetCode = qrCode.trim();

      // Validasi format QR yang lebih longgar
      if (assetCode.isEmpty) {
        _error = 'Format kode QR tidak valid';
        return false;
      }

      // Cek apakah asset sudah di-scan sebelumnya
      if (_scannedItems.any((item) => item.assetCode == assetCode)) {
        _error = 'Aset ini sudah dipindai sebelumnya';
        return false;
      }

      // Menggunakan endpoint dari dokumentasi API
      final response = await auth.ApiService.post(
        '/asset-opname-details',
        body: {
          'opname_id': opnameId,
          'asset_code': assetCode,
          'actual_location_id': roomId,
        },
        context: context,
      );

      LoggerUtil.d('API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Set as last scanned code
        setLastScannedCode(assetCode);

        if (data['success'] == true && data['data'] != null) {
          // Tambahkan aset ke daftar aset yang dipindai
          final assetData = data['data'];

          final asset = StockOpnameItem(
            assetId: assetData['asset_id'],
            assetCode: assetCode,
            assetName: assetData['asset_name'] ?? 'Tidak diketahui',
            location: assetData['actual_location_name'] ?? 'Tidak diketahui',
            condition: assetData['asset_type'] ?? 'Tidak diketahui',
            currentStatus: assetData['scan_status'] ?? 'Tidak diketahui',
            scanTime: DateTime.now(),
          );

          addScannedItem(asset);

          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Gagal memindai aset';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        final errorData = jsonDecode(response.body);

        // Handle specific HTTP status codes with user-friendly messages
        if (response.statusCode == 404) {
          _error =
              'Aset dengan kode ${assetCode} tidak ditemukan. Pastikan kode QR valid.';
        } else if (response.statusCode == 401) {
          _error = 'Sesi telah berakhir. Silakan login kembali.';
        } else if (response.statusCode == 403) {
          _error = 'Anda tidak memiliki akses untuk memindai aset ini.';
        } else if (response.statusCode == 400) {
          _error = errorData['message'] ??
              'Format permintaan tidak valid. Coba lagi.';
        } else if (response.statusCode == 500) {
          _error = 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
        } else {
          _error = errorData['message'] ??
              'Error ${response.statusCode}: Gagal memindai aset';
        }

        LoggerUtil.e(
            'HTTP Error: ${response.statusCode}', _error, StackTrace.current);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Gagal memindai aset: ${e.toString()}';
      LoggerUtil.e('Exception during processScannedQR', e, StackTrace.current);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mengirim laporan stock opname
  Future<bool> submitStockOpnameReport(BuildContext context) async {
    if (_scannedItems.isEmpty) {
      _error = 'Tidak ada item yang dipindai untuk dilaporkan';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final endpoint = '/stockopname/report';

      // Siapkan data untuk dikirim
      final reportData = {
        'items': _scannedItems
            .map((item) => {
                  'asset_id': item.assetId,
                  'asset_code': item.assetCode,
                  'condition': item.condition,
                  'location': item.location,
                  'scan_time': item.scanTime.toIso8601String(),
                })
            .toList(),
      };

      final response = await auth.ApiService.post(endpoint,
          body: reportData, context: context);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          _summary = responseData['data'];
          // Reset scanned items setelah berhasil submit
          _scannedItems = [];
          notifyListeners();
          return true;
        } else {
          _error = responseData['message'] ?? 'Gagal mengirim laporan';
          notifyListeners();
          return false;
        }
      } else {
        _error = 'Error ${response.statusCode}: Gagal mengirim laporan';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menyelesaikan stockopname
  Future<bool> completeStockOpname(int opnameId, BuildContext context) async {
    if (_scannedItems.isEmpty) {
      _error = 'Belum ada aset yang dipindai';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Menggunakan endpoint dari dokumentasi API
      final response = await auth.ApiService.post(
        '/asset-opnames/$opnameId/complete',
        body: {},
        context: context,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Simpan summary
          if (data['data'] != null) {
            _summary = data['data'];
          }

          // Refresh list opname setelah selesai
          await fetchPendingOpnames(context);
          return true;
        } else {
          _error = data['message'] ?? 'Gagal menyelesaikan stockopname';
          return false;
        }
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Gagal menyelesaikan stockopname';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menghapus item dari daftar
  void removeItem(String assetCode) {
    _scannedItems.removeWhere((item) => item.assetCode == assetCode);
    notifyListeners();
  }

  // Reset daftar item
  void resetItems() {
    _scannedItems = [];
    _summary = null;
    _scannedCode = null;
    _lastScannedCode = null;
    _flashOn = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ----------------- Fungsi untuk manajemen stockopname -----------------

  // Memuat data gedung dengan parameter pencarian
  Future<void> fetchBuildings(BuildContext context,
      {String searchQuery = '', bool resetList = true}) async {
    LoggerUtil.d(
        'fetchBuildings called with searchQuery: "$searchQuery", resetList: $resetList');

    // Guard clause to prevent duplicate requests
    if (_isLoadingBuildings &&
        searchQuery == _lastBuildingSearchQuery &&
        resetList) {
      LoggerUtil.d('Skipping duplicate building fetch request');
      return;
    }

    // Jika ini adalah request baru (bukan load more), reset pagination
    if (resetList) {
      _currentBuildingPage = 1;
      _lastBuildingSearchQuery = searchQuery;
      _isLoadingBuildings = true;
      _buildings = [];
      _hasMoreBuildings = true;
      LoggerUtil.d('Reset building list and pagination for new search');
    } else {
      // Double-check to prevent duplicate load-more requests
      if (!_hasMoreBuildings || _isLoadingMoreBuildings) {
        LoggerUtil.d(
            'Skipping load more: hasMore=$_hasMoreBuildings, isLoadingMore=$_isLoadingMoreBuildings');
        return;
      }
      _isLoadingMoreBuildings = true;
      LoggerUtil.d(
          'Loading more buildings, current page: $_currentBuildingPage');
    }

    _error = null;
    notifyListeners();

    try {
      // Cek apakah sudah login/ada token
      final token = await auth.ApiService.getAccessToken();
      if (token == null || token.isEmpty) {
        _error = 'Anda tidak memiliki akses. Silakan login kembali.';
        LoggerUtil.e('Error: Token tidak ditemukan, pengguna belum login');
        _isLoadingBuildings = false;
        _isLoadingMoreBuildings = false;
        notifyListeners();
        return;
      }

      // Perbaiki format URL, pastikan tidak ada karakter khusus yang tidak di-encode
      String endpoint =
          '/buildings?sort_order=asc&page=$_currentBuildingPage&limit=$_buildingLimit';
      if (searchQuery.isNotEmpty) {
        endpoint = '$endpoint&search=${Uri.encodeComponent(searchQuery)}';
        LoggerUtil.d('Search query added to endpoint: $endpoint');
      }

      // Log URL lengkap untuk debugging
      final fullUrl = '${auth.ApiService.baseUrl}$endpoint';
      LoggerUtil.d('Base URL yang digunakan: ${auth.ApiService.baseUrl}');
      LoggerUtil.d('Full URL for request: $fullUrl');
      LoggerUtil.d('Fetching buildings with endpoint: $endpoint');
      LoggerUtil.d(
          'Using token: ${token.substring(0, math.min(10, token.length))}...');
      LoggerUtil.d(
          'Current page: $_currentBuildingPage, Has more: $_hasMoreBuildings');

      try {
        // Coba gunakan http.get langsung untuk debugging
        final client = http.Client();
        final uri = Uri.parse(fullUrl);

        LoggerUtil.d('Trying direct HTTP request to: $uri');
        final directResponse = await client.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            LoggerUtil.e('Direct HTTP request timed out after 15 seconds');
            throw TimeoutException('Connection timeout');
          },
        );

        LoggerUtil.d(
            'Direct HTTP response: ${directResponse.statusCode} - ${directResponse.body}');

        // Kemudian coba dengan ApiService
        LoggerUtil.d('Now trying with ApiService');
        final response = await auth.ApiService.get(endpoint, context: context);
        LoggerUtil.d(
            'Building API response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            // Debug: Cetak detail struktur data mentah
            _debugJsonStructure(data['data'], 'Building data');

            // Process pagination info
            if (data['pagination'] != null) {
              _totalBuildingPages = data['pagination']['total_pages'] ?? 1;
              _hasMoreBuildings = data['pagination']['has_next'] ?? false;
              _currentBuildingPage = data['pagination']['current_page'] ?? 1;
              LoggerUtil.d(
                  'Pagination info: Page $_currentBuildingPage of $_totalBuildingPages, Has more: $_hasMoreBuildings');
            }

            final List<dynamic> buildingsJson = data['data'] ?? [];
            LoggerUtil.d('Building data count: ${buildingsJson.length}');

            // Log raw data for debugging
            LoggerUtil.d('Raw building data: ${jsonEncode(buildingsJson)}');

            // Parse gedung dari JSON
            final newBuildings = buildingsJson
                .map((json) {
                  try {
                    // Print detail JSON untuk debugging
                    LoggerUtil.d('Building JSON item: $json');
                    final building = Building.fromJson(json);
                    LoggerUtil.d(
                        'Successfully parsed building: id=${building.id}, name=${building.name}');
                    return building;
                  } catch (e) {
                    LoggerUtil.e(
                        'Error parsing building', e, StackTrace.current);
                    LoggerUtil.e('Error item: $json');
                    return null;
                  }
                })
                .whereType<Building>()
                .toList(); // Filter null values

            // Tambahkan gedung baru ke daftar yang ada (atau ganti jika ini adalah request baru)
            if (resetList) {
              _buildings = newBuildings;
            } else {
              _buildings.addAll(newBuildings);
            }

            LoggerUtil.i(
                'Successfully parsed ${newBuildings.length} buildings, total now: ${_buildings.length}');

            // Increment page for next load if there are more buildings
            if (_hasMoreBuildings) {
              _currentBuildingPage++;
            }
          } else {
            _error = data['message'] ?? 'Gagal memuat data gedung';
            LoggerUtil.w('Error dari API: $_error');
          }
        } else {
          _error = 'Error ${response.statusCode}: Gagal memuat data gedung';
          LoggerUtil.e('Error status code: ${response.statusCode}');
          // Coba cetak body untuk melihat detail error
          LoggerUtil.e('Error body: ${response.body}');
        }
      } catch (e) {
        LoggerUtil.e('HTTP request error', e, StackTrace.current);
        throw e; // Re-throw untuk ditangkap di catch luar
      } finally {
        // Tutup koneksi client
        http.Client().close();
      }
    } catch (e, stackTrace) {
      _error = 'Gagal memuat data gedung: ${e.toString()}';
      LoggerUtil.e('Exception saat memuat gedung', e, stackTrace);
    } finally {
      // Reset loading flags appropriately based on request type
      if (resetList) {
        _isLoadingBuildings = false;
        LoggerUtil.d('Reset _isLoadingBuildings flag');
      } else {
        _isLoadingMoreBuildings = false;
        LoggerUtil.d('Reset _isLoadingMoreBuildings flag');
      }

      // Always notify listeners about state changes
      notifyListeners();

      // Log final state
      LoggerUtil.d(
          'Buildings fetch completed. Total buildings: ${_buildings.length}, hasMore: $_hasMoreBuildings, currentPage: $_currentBuildingPage');
    }
  }

  // Load more buildings
  Future<void> loadMoreBuildings(BuildContext context) async {
    // Avoid duplicate requests or loading when we don't have more data
    if (!_hasMoreBuildings || _isLoadingMoreBuildings || _isLoadingBuildings) {
      LoggerUtil.d(
          'Load more buildings skipped: hasMore=$_hasMoreBuildings, loadingMore=$_isLoadingMoreBuildings, loading=$_isLoadingBuildings');
      return;
    }

    LoggerUtil.d(
        'Loading more buildings, current page: $_currentBuildingPage, total pages: $_totalBuildingPages');

    try {
      // Set loading flag and notify listeners immediately
      _isLoadingMoreBuildings = true;
      notifyListeners();

      // Cek apakah sudah login/ada token
      final token = await auth.ApiService.getAccessToken();
      if (token == null || token.isEmpty) {
        _error = 'Anda tidak memiliki akses. Silakan login kembali.';
        LoggerUtil.e('Error: Token tidak ditemukan, pengguna belum login');
        _isLoadingMoreBuildings = false;
        notifyListeners();
        return;
      }

      // Perbaiki format URL, pastikan tidak ada karakter khusus yang tidak di-encode
      String endpoint =
          '/buildings?sort_order=asc&page=$_currentBuildingPage&limit=$_buildingLimit';
      if (_lastBuildingSearchQuery.isNotEmpty) {
        endpoint =
            '$endpoint&search=${Uri.encodeComponent(_lastBuildingSearchQuery)}';
        LoggerUtil.d('Search query added to endpoint: $endpoint');
      }

      // Log URL lengkap untuk debugging
      final fullUrl = '${auth.ApiService.baseUrl}$endpoint';
      LoggerUtil.d('Base URL yang digunakan: ${auth.ApiService.baseUrl}');
      LoggerUtil.d('Full URL for request: $fullUrl');
      LoggerUtil.d('Fetching more buildings with endpoint: $endpoint');
      LoggerUtil.d(
          'Current page: $_currentBuildingPage, Has more: $_hasMoreBuildings');

      final response = await auth.ApiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Process pagination info
          if (data['pagination'] != null) {
            _totalBuildingPages = data['pagination']['total_pages'] ?? 1;
            _hasMoreBuildings = data['pagination']['has_next'] ?? false;
            _currentBuildingPage = data['pagination']['current_page'] ?? 1;
            LoggerUtil.d(
                'Pagination info: Page $_currentBuildingPage of $_totalBuildingPages, Has more: $_hasMoreBuildings');
          }

          final List<dynamic> buildingsJson = data['data'] ?? [];
          LoggerUtil.d('Building data count: ${buildingsJson.length}');

          // Parse gedung dari JSON
          final newBuildings = buildingsJson
              .map((json) {
                try {
                  final building = Building.fromJson(json);
                  LoggerUtil.d(
                      'Successfully parsed building: id=${building.id}, name=${building.name}');
                  return building;
                } catch (e) {
                  LoggerUtil.e('Error parsing building', e, StackTrace.current);
                  return null;
                }
              })
              .whereType<Building>()
              .toList(); // Filter null values

          // Tambahkan gedung baru ke daftar yang ada
          _buildings.addAll(newBuildings);
          LoggerUtil.i(
              'Successfully added ${newBuildings.length} more buildings, total now: ${_buildings.length}');

          // Increment page for next load if there are more buildings
          if (_hasMoreBuildings) {
            _currentBuildingPage++;
          }
        } else {
          _error = data['message'] ?? 'Gagal memuat data gedung tambahan';
          LoggerUtil.w('Error dari API: $_error');
        }
      } else {
        _error =
            'Error ${response.statusCode}: Gagal memuat data gedung tambahan';
        LoggerUtil.e('Error status code: ${response.statusCode}');
        LoggerUtil.e('Error body: ${response.body}');
      }
    } catch (e, stackTrace) {
      _error = 'Gagal memuat data gedung tambahan: ${e.toString()}';
      LoggerUtil.e('Exception saat memuat gedung tambahan', e, stackTrace);
    } finally {
      // Reset loading flag
      _isLoadingMoreBuildings = false;
      notifyListeners();
      LoggerUtil.d(
          'Buildings load more completed. Total buildings: ${_buildings.length}, hasMore: $_hasMoreBuildings, currentPage: $_currentBuildingPage');
    }
  }

  // Fungsi debugging untuk struktur JSON
  void _debugJsonStructure(dynamic data, String label) {
    try {
      LoggerUtil.d('===== DEBUG $label =====');

      if (data == null) {
        LoggerUtil.d('Data adalah null');
        return;
      }

      if (data is List) {
        LoggerUtil.d('Data adalah List dengan ${data.length} item');
        if (data.isNotEmpty) {
          LoggerUtil.d('Item pertama:');
          LoggerUtil.d(jsonEncode(data.first));

          // Cetak semua keys di item pertama untuk debugging
          if (data.first is Map<String, dynamic>) {
            Map<String, dynamic> firstItem = data.first;
            LoggerUtil.d('Keys dari item pertama: ${firstItem.keys.toList()}');
            LoggerUtil.d('Nilai untuk setiap key:');
            firstItem.forEach((key, value) {
              LoggerUtil.d('$key: $value (${value?.runtimeType})');
            });
          }
        }
      } else if (data is Map) {
        LoggerUtil.d('Data adalah Map dengan ${data.length} pasang key-value');
        LoggerUtil.d('Keys: ${data.keys.toList()}');
        LoggerUtil.d('Nilai untuk setiap key:');
        data.forEach((key, value) {
          LoggerUtil.d('$key: $value (${value?.runtimeType})');
        });
      } else {
        LoggerUtil.d('Data bertipe: ${data.runtimeType}');
        LoggerUtil.d('Nilai: $data');
      }

      LoggerUtil.d('========================');
    } catch (e) {
      LoggerUtil.e('Error saat debugging JSON', e, StackTrace.current);
    }
  }

  // Set gedung terpilih dan preload ruangan
  void selectBuilding(Building building) {
    _selectedBuilding = building;
    _rooms = [];
    _filteredRooms = [];
    notifyListeners();
  }

  // Preload semua ruangan untuk gedung tertentu
  Future<void> preloadRoomsForBuilding(
      int buildingId, BuildContext context) async {
    // Fetch rooms for this building immediately
    await fetchRoomsByBuilding(buildingId, context);

    // Cache the rooms data so it's immediately available when needed
    LoggerUtil.d('Preloaded ${_rooms.length} rooms for building $buildingId');
  }

  // Reset pencarian gedung dan ruangan
  void resetSearch() {
    _lastBuildingSearchQuery = '';
    _lastRoomSearchQuery = '';
    _currentBuildingPage = 1;
    _hasMoreBuildings = true;
    if (_buildingSearchDebounce?.isActive ?? false) {
      _buildingSearchDebounce!.cancel();
    }
    if (_roomSearchDebounce?.isActive ?? false) {
      _roomSearchDebounce!.cancel();
    }
  }

  // Membersihkan state pencarian saat reset building selection
  void resetBuildingSelection() {
    if (_selectedBuilding == null) {
      return; // Jika sudah null, tidak perlu melakukan apa-apa
    }

    _selectedBuilding = null;
    _rooms = [];
    _filteredRooms = [];
    _lastRoomSearchQuery = '';

    // Reset juga ruangan jika ada
    resetRoomSelection();

    notifyListeners();
  }

  // Memuat data ruangan dengan parameter pencarian
  Future<void> fetchRoomsByBuilding(int buildingId, BuildContext context,
      {String searchQuery = ''}) async {
    if (_isLoadingRooms && searchQuery == _lastRoomSearchQuery) return;

    _lastRoomSearchQuery = searchQuery;
    _isLoadingRooms = true;
    _rooms = searchQuery.isEmpty ? _rooms : [];
    _filteredRooms = searchQuery.isEmpty ? _filteredRooms : [];
    _error = null;
    notifyListeners();

    try {
      // Cek apakah sudah login/ada token
      final token = await auth.ApiService.getAccessToken();
      if (token == null || token.isEmpty) {
        _error = 'Anda tidak memiliki akses. Silakan login kembali.';
        LoggerUtil.e('Error: Token tidak ditemukan, pengguna belum login');
        _isLoadingRooms = false;
        notifyListeners();
        return;
      }

      // Perbaiki format URL
      String endpoint = '/rooms?building_id=$buildingId';
      if (searchQuery.isNotEmpty) {
        endpoint = '$endpoint&search=${Uri.encodeComponent(searchQuery)}';
      }

      // Log URL lengkap untuk debugging
      final fullUrl = '${auth.ApiService.baseUrl}$endpoint';
      LoggerUtil.d('Base URL yang digunakan: ${auth.ApiService.baseUrl}');
      LoggerUtil.d('Full URL for request: $fullUrl');
      LoggerUtil.d('Fetching rooms with endpoint: $endpoint');
      LoggerUtil.d(
          'Using token: ${token.substring(0, math.min(10, token.length))}...');

      try {
        // Coba gunakan http.get langsung untuk debugging
        final client = http.Client();
        final uri = Uri.parse(fullUrl);

        LoggerUtil.d('Trying direct HTTP request to: $uri');
        final directResponse = await client.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            LoggerUtil.e('Direct HTTP request timed out after 15 seconds');
            throw TimeoutException('Connection timeout');
          },
        );

        LoggerUtil.d(
            'Direct HTTP response: ${directResponse.statusCode} - ${directResponse.body}');

        // Kemudian coba dengan ApiService
        LoggerUtil.d('Now trying with ApiService');
        final response = await auth.ApiService.get(endpoint, context: context);
        LoggerUtil.d(
            'Rooms API response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            // Debug: Cetak detail struktur data mentah
            _debugJsonStructure(data['data'], 'Room data');

            final List<dynamic> roomsJson = data['data'];
            LoggerUtil.d('Room data count: ${roomsJson.length}');

            // Hapus daftar ruangan yang sudah ada sebelumnya
            _rooms = [];

            // Parse ruangan dari JSON
            _rooms = roomsJson
                .map((json) {
                  try {
                    // Print detail JSON untuk debugging
                    LoggerUtil.d('Room JSON item: $json');
                    return Room.fromJson(json);
                  } catch (e) {
                    LoggerUtil.e('Error parsing room', e, StackTrace.current);
                    LoggerUtil.e('Error item: $json');
                    return null;
                  }
                })
                .whereType<Room>()
                .toList(); // Filter null values

            LoggerUtil.i('Successfully parsed ${_rooms.length} rooms');
            // Debug print parsed rooms
            for (var room in _rooms) {
              LoggerUtil.d(
                  'Room parsed: id=${room.id}, name=${room.name}, buildingId=${room.buildingId}');
            }

            _filteredRooms = List.from(_rooms);
          } else {
            _error = data['message'] ?? 'Gagal memuat data ruangan';
            LoggerUtil.w('Error dari API: $_error');
          }
        } else {
          _error = 'Error ${response.statusCode}: Gagal memuat data ruangan';
          LoggerUtil.e('Error status code: ${response.statusCode}');
          LoggerUtil.e('Error body: ${response.body}');
        }
      } catch (e) {
        LoggerUtil.e('HTTP request error', e, StackTrace.current);
        throw e; // Re-throw untuk ditangkap di catch luar
      } finally {
        // Tutup koneksi client
        http.Client().close();
      }
    } catch (e, stackTrace) {
      _error = 'Gagal memuat data ruangan: ${e.toString()}';
      LoggerUtil.e('Exception saat memuat ruangan', e, stackTrace);
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  // Filter ruangan berdasarkan kata kunci (lokal)
  void filterRooms(String query) {
    if (query.isEmpty) {
      _filteredRooms = List.from(_rooms);
    } else {
      _filteredRooms = _rooms
          .where((room) =>
              room.name?.toLowerCase().contains(query.toLowerCase()) ?? false)
          .toList();
    }
    notifyListeners();
  }

  // Pilih ruangan
  Room? _selectedRoom;
  Room? get selectedRoom => _selectedRoom;

  void selectRoom(Room? room) {
    _selectedRoom = room;
    notifyListeners();
  }

  // Reset pilihan ruangan
  void resetRoomSelection() {
    if (_selectedRoom == null) {
      return; // Jika sudah null, tidak perlu melakukan apa-apa
    }

    _selectedRoom = null;
    notifyListeners();
  }

  // Memuat daftar stock opname yang sedang berjalan
  Future<void> fetchPendingOpnames(BuildContext context) async {
    try {
      final response = await auth.ApiService.get(
          '/asset-opnames?status=pending',
          context: context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> opnamesJson = data['data'];
          _pendingOpnames =
              opnamesJson.map((json) => StockOpname.fromJson(json)).toList();
        } else {
          _error = data['message'] ?? 'Gagal memuat data stock opname';
        }
      } else {
        _error = 'Error ${response.statusCode}: Gagal memuat data stock opname';
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error saat memuat pending opnames', e, StackTrace.current);
    }
    notifyListeners();
  }

  // Membuat stock opname baru
  Future<StockOpname?> createStockOpname(
      int roomId, BuildContext context) async {
    _isCreatingOpname = true;
    _error = null;
    notifyListeners();

    try {
      final response = await auth.ApiService.post(
        '/asset-opnames',
        body: {'room_id': roomId},
        context: context,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Refresh daftar opname yang sedang berjalan
          await fetchPendingOpnames(context);

          // Return data untuk diteruskan ke StockopnameScanner
          return StockOpname.fromJson(data['data']);
        } else {
          _error = data['message'] ?? 'Gagal membuat stock opname';
          return null;
        }
      } else {
        final data = jsonDecode(response.body);
        _error = data['message'] ?? 'Gagal membuat stock opname';
        return null;
      }
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error saat membuat stock opname', e, StackTrace.current);
      return null;
    } finally {
      _isCreatingOpname = false;
      notifyListeners();
    }
  }

  // Memuat semua data yang diperlukan
  Future<void> loadAllData(BuildContext context) async {
    try {
      // Uji koneksi API terlebih dahulu
      await testApiConnection(context);

      await Future.wait([
        fetchBuildings(context),
        fetchPendingOpnames(context),
      ]);
    } catch (e) {
      _error = e.toString();
      LoggerUtil.e('Error saat memuat data', e, StackTrace.current);
      notifyListeners();
    }
  }

  // Fungsi untuk menguji koneksi ke server API
  Future<void> testApiConnection(BuildContext context) async {
    LoggerUtil.d('====== DEBUG INFO ======');
    LoggerUtil.d('Base URL API: ${auth.ApiService.baseUrl}');

    try {
      // Coba ambil token autentikasi
      final token = await auth.ApiService.getAccessToken();
      LoggerUtil.d(
          'Access Token: ${token != null ? (token.length > 10 ? "${token.substring(0, 10)}..." : token) : "null"}');

      // Coba lakukan ping ke server
      LoggerUtil.d('Testing API connection...');
      final pingUrl = Uri.parse('${auth.ApiService.baseUrl}/ping');

      try {
        final pingResponse = await http.get(pingUrl).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('Connection timeout');
          },
        );
        LoggerUtil.d(
            'Ping response: ${pingResponse.statusCode} - ${pingResponse.body}');
      } catch (e) {
        LoggerUtil.e('Ping error', e, StackTrace.current);
      }

      LoggerUtil.d('========================');
    } catch (e) {
      LoggerUtil.e('Test API connection error', e, StackTrace.current);
      LoggerUtil.d('========================');
    }
  }

  // Pencarian gedung dengan debounce
  void searchBuildings(String query, BuildContext context) {
    LoggerUtil.d('Search buildings called with query: $query');

    // Batalkan timer debounce sebelumnya jika masih aktif
    if (_buildingSearchDebounce?.isActive ?? false) {
      _buildingSearchDebounce?.cancel();
    }

    // Tampilkan loading segera
    if (!_isLoadingBuildings) {
      _isLoadingBuildings = true;
      notifyListeners();
    }

    // Reset pagination untuk pencarian baru
    _currentBuildingPage = 1;
    _hasMoreBuildings = true;
    _buildings = [];

    // Buat timer debounce baru
    _buildingSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      LoggerUtil.d(
          'Debounce timer expired, now fetching buildings with query: $query');
      fetchBuildings(context, searchQuery: query, resetList: true);
    });
  }

  // Pencarian ruangan dengan debounce
  void searchRooms(String query, BuildContext context) {
    LoggerUtil.d('Search rooms called with query: $query');

    if (selectedBuilding == null) return;

    // Batalkan timer debounce sebelumnya jika masih aktif
    if (_roomSearchDebounce?.isActive ?? false) {
      _roomSearchDebounce?.cancel();
    }

    // Tampilkan loading segera
    if (!_isLoadingRooms) {
      _isLoadingRooms = true;
      notifyListeners();
    }

    // Buat timer debounce baru
    _roomSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      LoggerUtil.d(
          'Debounce timer expired, now fetching rooms with query: $query');
      fetchRoomsByBuilding(selectedBuilding!.id, context, searchQuery: query);
    });
  }

  @override
  void dispose() {
    _buildingSearchDebounce?.cancel();
    _roomSearchDebounce?.cancel();
    super.dispose();
  }
}
