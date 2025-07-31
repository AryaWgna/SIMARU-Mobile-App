import 'package:flutter/material.dart';
import '../../models/scan/stockopname_model.dart';
import '../auth/auth_controller.dart' as auth;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../utils/logger_util.dart';

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

  // Add local progress tracking
  Map<int, int> _localScannedCounts = {}; // Map of opnameId -> scanned count

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

  // Add getter for local scanned counts
  Map<int, int> get localScannedCounts => _localScannedCounts;

  // Method to get local scanned count for a specific opname
  int getLocalScannedCount(int opnameId) {
    return _localScannedCounts[opnameId] ?? 0;
  }

  // Method to increment local scanned count
  void incrementLocalScannedCount(int opnameId) {
    _localScannedCounts[opnameId] = (_localScannedCounts[opnameId] ?? 0) + 1;

    // Also update the pending opnames list with new count
    final opnameIndex =
        _pendingOpnames.indexWhere((opname) => opname.opnameId == opnameId);
    if (opnameIndex != -1) {
      _pendingOpnames[opnameIndex] = _pendingOpnames[opnameIndex]
          .copyWith(scannedAssets: _localScannedCounts[opnameId]!);
    }

    notifyListeners();
    LoggerUtil.d(
        'Local scanned count for opname $opnameId incremented to ${_localScannedCounts[opnameId]}');
  }

  // Method to manually set local scanned count
  void setLocalScannedCount(int opnameId, int count) {
    _localScannedCounts[opnameId] = count;

    // Also update the pending opnames list with new count
    final opnameIndex =
        _pendingOpnames.indexWhere((opname) => opname.opnameId == opnameId);
    if (opnameIndex != -1) {
      _pendingOpnames[opnameIndex] =
          _pendingOpnames[opnameIndex].copyWith(scannedAssets: count);
    }

    notifyListeners();
  }

  // Variabel untuk pagination
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

          // Extract asset master information if available
          final assetMaster = assetData['asset_master'];

          // Extract depreciation information if available
          final depreciationInfo = assetData['depreciation'];

          return StockOpnameItem(
            // Basic asset information
            assetId: assetData['asset_id'],
            assetCode: assetData['asset_code'],
            assetName: assetData['asset_master_name'] ??
                assetData['asset_name'] ??
                'Tidak diketahui',
            location: assetData['room_name'] ?? 'Tidak diketahui',
            condition: assetData['condition'] ?? 'Tidak diketahui',
            currentStatus: assetData['current_status'] ?? 'Tidak diketahui',
            scanTime: DateTime.now(),

            // Asset Master information
            assetMasterId: assetData['asset_master_id'],
            assetMasterCode: assetMaster?['asset_master_code'],
            assetMasterName: assetMaster?['asset_name'],
            description: assetMaster?['description'],
            assetType: assetMaster?['asset_type'],
            subcategoryName: assetMaster?['subcategory_name'],
            referenceImagePath: assetMaster?['reference_image_path'],
            isDepreciable: assetMaster?['is_depreciable'],
            needsCalibration: assetMaster?['needs_calibration'],

            // Physical asset details
            serialNumber: assetData['serial_number'],
            model: assetData['model'],
            brandId: assetData['brand_id'],
            brandName: assetData['brand_name'],

            // Purchase information
            purchaseDate: assetData['purchase_date'],
            purchaseCost: assetData['purchase_cost'],
            warrantyEndDate: assetData['warranty_end_date'],

            // Employee/PIC information
            userId: assetData['user_id'],
            employeeNumber: assetData['employee_number'],
            employeeName: assetData['employee_name'],

            // Location details
            roomId: assetData['room_id'],
            roomName: assetData['room_name'],
            buildingName: assetData['building_name'],
            floorNumber: assetData['floor_number'],
            actualLocationName:
                assetData['actual_location_name'] ?? assetData['room_name'],
            expectedLocationName:
                assetData['expected_location_name'] ?? assetData['room_name'],
            expectedBuildingName: assetData['expected_building_name'] ??
                assetData['building_name'],
            expectedFloorNumber:
                assetData['expected_floor_number'] ?? assetData['floor_number'],

            // QR and timestamps
            qrCodePath: assetData['qr_code'],
            createdAt: assetData['created_at'],
            updatedAt: assetData['updated_at'],

            // Depreciation info
            depreciationInfo: depreciationInfo,
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

      LoggerUtil.d(
          'Processing QR code: "$qrCode", opnameId: $opnameId, roomId: $roomId');
      final assetCode = qrCode.trim();
      LoggerUtil.d('Trimmed asset code: "$assetCode"');

      // Validasi format QR yang lebih longgar
      if (assetCode.isEmpty) {
        LoggerUtil.w('Empty asset code detected');
        _error = 'Format kode QR tidak valid';
        return false;
      }

      // Cek apakah asset sudah di-scan sebelumnya
      if (_scannedItems.any((item) => item.assetCode == assetCode)) {
        LoggerUtil.w('Asset already scanned: $assetCode');
        _error = 'Aset ini sudah dipindai sebelumnya';
        return false;
      }

      // Pastikan tipe data yang dikirim sesuai dengan yang diharapkan API
      Map<String, dynamic> requestBody = {
        'opname_id': opnameId, // Pastikan ini adalah integer
        'asset_code': assetCode, // String
        'actual_location_id': roomId, // Pastikan ini adalah integer
        'condition': 'good', // String
      };

      LoggerUtil.d('Sending request to API: $requestBody');

      try {
        // Menggunakan endpoint dari dokumentasi API
        final response = await auth.ApiService.post(
          '/asset-opname-details',
          body: requestBody,
          context: context,
        );

        LoggerUtil.d('API response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);

          // Set as last scanned code
          setLastScannedCode(assetCode);
          LoggerUtil.d('Last scanned code set to: $assetCode');

          if (data['success'] == true && data['data'] != null) {
            // Handle array or object response
            dynamic assetData;

            if (data['data'] is List) {
              // If data is a list, get the first item
              if ((data['data'] as List).isNotEmpty) {
                assetData = data['data'][0];
                LoggerUtil.d(
                    'Data is a list. Using first element: ${json.encode(assetData)}');
              } else {
                LoggerUtil.w('Data is an empty list');
                _error = 'Data aset tidak ditemukan';
                _isLoading = false;
                notifyListeners();
                return false;
              }
            } else {
              // Data is an object
              assetData = data['data'];
              LoggerUtil.d('Data is an object: ${json.encode(assetData)}');
            }

            // Handle berbagai kemungkinan tipe data dari API
            int? assetId;
            if (assetData['asset_id'] != null) {
              if (assetData['asset_id'] is String) {
                assetId = int.tryParse(assetData['asset_id']);
              } else {
                assetId = assetData['asset_id'];
              }
            }

            final asset = StockOpnameItem(
              // Basic asset information
              assetId: assetId,
              assetCode: assetCode,
              assetName:
                  assetData['asset_name']?.toString() ?? 'Tidak diketahui',
              location: assetData['actual_location_name']?.toString() ??
                  'Tidak diketahui',
              condition: assetData['condition']?.toString() ?? 'good',
              currentStatus:
                  assetData['scan_status']?.toString() ?? 'Tidak diketahui',
              scanTime: DateTime.now(),

              // Additional detailed asset information from API
              brandName: assetData['brand_name']?.toString(),
              model: assetData['model']?.toString(),
              serialNumber: assetData['serial_number']?.toString(),
              pic: assetData['pic']?.toString(),
              category: assetData['category']?.toString(),
              assetType: assetData['asset_type']?.toString(),

              // Location details - Use actual data from scan for current location
              roomId: assetData['actual_location_id'] ?? assetData['room_id'],
              roomName: assetData['actual_location_name']?.toString(),
              buildingName: assetData['actual_building_name']?.toString() ??
                  assetData['building_name']?.toString(),
              floorNumber: assetData['actual_floor_number']?.toString() ??
                  assetData['floor_number']?.toString(),
              actualLocationName: assetData['actual_location_name']?.toString(),
              expectedLocationName:
                  assetData['expected_location_name']?.toString(),
              expectedBuildingName:
                  assetData['expected_building_name']?.toString() ??
                      assetData['building_name']?.toString(),
              expectedFloorNumber:
                  assetData['expected_floor_number']?.toString() ??
                      assetData['floor_number']?.toString(),

              // QR and timestamps
              createdAt: assetData['created_at']?.toString(),
              updatedAt: assetData['updated_at']?.toString(),

              // Reference image
              referenceImagePath: assetData['reference_image_path']?.toString(),
            );

            LoggerUtil.i(
                'Created asset item: ${asset.assetName} (${asset.assetCode})');
            addScannedItem(asset);

            // Check if this asset is in the allRoomAssets list and update its status
            final assetIndex = _allRoomAssets
                .indexWhere((item) => item.assetCode == assetCode);
            if (assetIndex != -1) {
              _allRoomAssets[assetIndex] = asset;
              LoggerUtil.d('Updated asset in room assets list: $assetCode');
            }
            // If not found in the list, this might be an asset from another room or a new asset
            // We can still add it to our local scanned items

            // Increment local scanned count
            incrementLocalScannedCount(opnameId);
            LoggerUtil.d(
                'Local scanned count incremented for opname $opnameId');

            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            _error = data['message']?.toString() ?? 'Gagal memindai aset';
            LoggerUtil.w('API reported error: $_error');
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          Map<String, dynamic> errorData = {};
          try {
            errorData = jsonDecode(response.body);
            LoggerUtil.e('API error response: $errorData');
          } catch (e) {
            LoggerUtil.e('Could not parse error response: ${response.body}', e,
                StackTrace.current);
          }

          // Handle specific HTTP status codes with user-friendly messages
          if (response.statusCode == 404) {
            _error =
                'Aset dengan kode ${assetCode} tidak ditemukan. Pastikan kode QR valid.';
          } else if (response.statusCode == 401) {
            _error = 'Sesi telah berakhir. Silakan login kembali.';
          } else if (response.statusCode == 403) {
            _error = 'Anda tidak memiliki akses untuk memindai aset ini.';
          } else if (response.statusCode == 400) {
            _error = errorData['message']?.toString() ??
                'Format permintaan tidak valid. Coba lagi.';
          } else if (response.statusCode == 500) {
            _error = 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
          } else {
            _error = errorData['message']?.toString() ??
                'Error ${response.statusCode}: Gagal memindai aset';
          }
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } catch (e) {
        LoggerUtil.e('Exception during API call', e, StackTrace.current);
        _error = 'Gagal memindai aset: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggerUtil.e('Exception during processScannedQR', e, StackTrace.current);
      _error = 'Gagal memindai aset: ${e.toString()}';
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

      LoggerUtil.d('Completing stockopname for opnameId: $opnameId');

      // Menggunakan endpoint dari dokumentasi API
      final response = await auth.ApiService.post(
        '/asset-opnames/$opnameId/complete',
        body: {}, // Empty body as per endpoint documentation
        context: context,
      );

      LoggerUtil.d(
          'Complete API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> data;
        try {
          data = jsonDecode(response.body);
          LoggerUtil.d('Success response decoded: $data');
        } catch (e) {
          LoggerUtil.e(
              'Error decoding success response', e, StackTrace.current);
          _error = 'Format respons tidak valid';
          return false;
        }

        if (data['success'] == true) {
          // Simpan summary
          if (data['data'] != null) {
            _summary = data['data'];
          }

          // Update status of the opname in the local list
          final index =
              _pendingOpnames.indexWhere((op) => op.opnameId == opnameId);
          if (index != -1) {
            _pendingOpnames[index] =
                _pendingOpnames[index].copyWith(status: 'completed');
          }

          // Refresh list opname setelah selesai
          await fetchPendingOpnames(context, resetList: true);
          return true;
        } else {
          _error =
              data['message']?.toString() ?? 'Gagal menyelesaikan stockopname';
          LoggerUtil.w('API reported error: $_error');
          return false;
        }
      } else {
        Map<String, dynamic> errorData = {};
        try {
          errorData = jsonDecode(response.body);
          LoggerUtil.e('API error response on complete: $errorData');
        } catch (e) {
          LoggerUtil.e('Could not parse error response', e, StackTrace.current);
        }

        _error = errorData['message']?.toString() ??
            'Gagal menyelesaikan stockopname: Error ${response.statusCode}';
        LoggerUtil.e('Complete failed with status ${response.statusCode}',
            _error, StackTrace.current);
        return false;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      LoggerUtil.e('Exception completing stockopname', e, StackTrace.current);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menghapus aset dari daftar yang telah dipindai
  void removeItem(String assetCode) {
    // Hapus dari daftar yang dipindai
    final removedItem = _scannedItems.firstWhere(
      (item) => item.assetCode == assetCode,
      orElse: () => null as StockOpnameItem,
    );

    if (removedItem != null) {
      _scannedItems.removeWhere((item) => item.assetCode == assetCode);

      // Update status in allRoomAssets if the asset exists there
      final assetIndex =
          _allRoomAssets.indexWhere((item) => item.assetCode == assetCode);
      if (assetIndex != -1) {
        // Reset to pending status
        final currentAsset = _allRoomAssets[assetIndex];
        _allRoomAssets[assetIndex] = StockOpnameItem(
          assetId: currentAsset.assetId,
          assetCode: currentAsset.assetCode,
          assetName: currentAsset.assetName,
          location: currentAsset.location,
          condition: currentAsset.condition,
          currentStatus: 'pending', // Reset to pending
          scanTime: DateTime.now(),
          notes: currentAsset.notes, // Preserve any notes
        );
        LoggerUtil.d('Reset asset status in room assets list: $assetCode');
      }

      notifyListeners();
    }
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

  // Variabel untuk pagination pending opnames
  int _currentPendingOpnamesPage = 1;
  int _totalPendingOpnamesPages = 1;
  bool _hasMorePendingOpnames = true;
  int _pendingOpnamesLimit = 10;
  bool _isLoadingMorePendingOpnames = false;

  // Getters untuk pagination pending opnames
  int get currentPendingOpnamesPage => _currentPendingOpnamesPage;
  int get totalPendingOpnamesPages => _totalPendingOpnamesPages;
  bool get hasMorePendingOpnames => _hasMorePendingOpnames;
  bool get isLoadingMorePendingOpnames => _isLoadingMorePendingOpnames;

  // Memuat daftar stock opname yang sedang berjalan dengan pagination
  Future<void> fetchPendingOpnames(BuildContext context,
      {bool resetList = true}) async {
    // Jika ini adalah request baru (bukan load more), reset pagination
    if (resetList) {
      _currentPendingOpnamesPage = 1;
      _pendingOpnames = [];
      _hasMorePendingOpnames = true;
    }

    try {
      // Construct URL with pagination parameters
      String endpoint =
          '/asset-opnames?status=pending&page=$_currentPendingOpnamesPage&limit=$_pendingOpnamesLimit';

      final response = await auth.ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Process pagination info if available
          if (data['pagination'] != null) {
            _totalPendingOpnamesPages = data['pagination']['total_pages'] ?? 1;
            _hasMorePendingOpnames = data['pagination']['has_next'] ?? false;
            _currentPendingOpnamesPage =
                data['pagination']['current_page'] ?? 1;
            LoggerUtil.d(
                'Pending Opnames Pagination: Page $_currentPendingOpnamesPage of $_totalPendingOpnamesPages, Has more: $_hasMorePendingOpnames');
          }

          final List<dynamic> opnamesJson = data['data'] ?? [];
          final newOpnames =
              opnamesJson.map((json) => StockOpname.fromJson(json)).toList();

          // Tambahkan opnames baru ke daftar yang ada (atau ganti jika ini adalah request baru)
          if (resetList) {
            _pendingOpnames = newOpnames;
          } else {
            _pendingOpnames.addAll(newOpnames);
          }

          LoggerUtil.i(
              'Successfully loaded ${newOpnames.length} pending opnames, total now: ${_pendingOpnames.length}');

          // Restore local scanned counts
          for (var opname in _pendingOpnames) {
            // If we have a local count, compare with API count and use the higher value
            if (_localScannedCounts.containsKey(opname.opnameId)) {
              final localCount = _localScannedCounts[opname.opnameId]!;
              if (localCount > opname.scannedAssets) {
                // Our local count is higher, update the opname object
                final index = _pendingOpnames
                    .indexWhere((o) => o.opnameId == opname.opnameId);
                if (index != -1) {
                  _pendingOpnames[index] = _pendingOpnames[index]
                      .copyWith(scannedAssets: localCount);
                }
              } else {
                // API count is higher, update our local count
                _localScannedCounts[opname.opnameId] = opname.scannedAssets;
              }
            } else {
              // Initialize local count from API
              _localScannedCounts[opname.opnameId] = opname.scannedAssets;
            }
          }

          // Increment page for next load if there are more opnames
          if (_hasMorePendingOpnames) {
            _currentPendingOpnamesPage++;
          }
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

  // Load more pending opnames
  Future<void> loadMorePendingOpnames(BuildContext context) async {
    // Avoid duplicate requests or loading when we don't have more data
    if (!_hasMorePendingOpnames || _isLoadingMorePendingOpnames) {
      LoggerUtil.d(
          'Load more pending opnames skipped: hasMore=$_hasMorePendingOpnames, loadingMore=$_isLoadingMorePendingOpnames');
      return;
    }

    LoggerUtil.d(
        'Loading more pending opnames, current page: $_currentPendingOpnamesPage, total pages: $_totalPendingOpnamesPages');

    try {
      // Set loading flag
      _isLoadingMorePendingOpnames = true;
      notifyListeners();

      // Call fetchPendingOpnames with resetList=false to append data
      await fetchPendingOpnames(context, resetList: false);
    } catch (e, stackTrace) {
      _error = 'Gagal memuat data stock opname tambahan: ${e.toString()}';
      LoggerUtil.e(
          'Exception saat memuat pending opnames tambahan', e, stackTrace);
    } finally {
      // Reset loading flag
      _isLoadingMorePendingOpnames = false;
      notifyListeners();
      LoggerUtil.d(
          'Pending opnames load more completed. Total opnames: ${_pendingOpnames.length}, hasMore: $_hasMorePendingOpnames, currentPage: $_currentPendingOpnamesPage');
    }
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
          await fetchPendingOpnames(context, resetList: true);

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
        fetchPendingOpnames(context, resetList: true),
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

  // Add these properties to the StockOpnameController class
  List<StockOpnameItem> _allRoomAssets = [];
  bool _isLoadingRoomAssets = false;

  // Getter for all room assets
  List<StockOpnameItem> get allRoomAssets => _allRoomAssets;
  bool get isLoadingRoomAssets => _isLoadingRoomAssets;

  // Fetch all assets for a specific room
  Future<void> fetchRoomAssets(
      int roomId, int opnameId, BuildContext context) async {
    try {
      _isLoadingRoomAssets = true;
      notifyListeners();

      // Get ALL room assets directly from assets endpoint with room_id filter
      final response = await auth.ApiService.get(
        '/assets?room_id=$roomId',
        context: context,
      );

      LoggerUtil.d('Fetching room assets for room ID: $roomId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          // Extract assets directly from room assets API
          final List<dynamic> assetsList = data['data'];

          // Extract all assets and set them as pending by default
          _allRoomAssets = [];

          LoggerUtil.d(
              'Processing ${assetsList.length} assets from room $roomId');

          // Process all assets in the room
          for (final asset in assetsList) {
            final item = StockOpnameItem(
              // Basic asset information
              assetId: asset['asset_id'],
              assetCode: asset['asset_code'] ?? '',
              assetName: asset['asset_master_name'] ??
                  asset['asset_name'] ??
                  'Tidak diketahui',
              location: asset['room_name'] ?? 'Tidak diketahui',
              condition: asset['condition'] ?? 'good',
              currentStatus: 'pending', // Default all room assets to pending
              scanTime: DateTime.now(),
              notes: '',

              // Asset Master information
              assetMasterId: asset['asset_master_id'],
              assetMasterCode: asset['asset_master_code'],
              assetMasterName: asset['asset_master_name'],
              description: asset['description'],
              assetType: asset['asset_type'],
              subcategoryName: asset['subcategory_name'],
              referenceImagePath: asset['reference_image_path'] ??
                  asset['picture_path'] ??
                  asset['qr_code'] ??
                  '',
              isDepreciable: asset['is_depreciable'],
              needsCalibration: asset['needs_calibration'],

              // Physical asset details
              serialNumber: asset['serial_number'],
              model: asset['model'],
              brandId: asset['brand_id'],
              brandName: asset['brand_name'],

              // Purchase information
              purchaseDate: asset['purchase_date'],
              purchaseCost: asset['purchase_cost'],
              warrantyEndDate: asset['warranty_end_date'],

              // Employee/PIC information
              userId: asset['user_id'],
              employeeNumber: asset['employee_number'],
              employeeName: asset['employee_name'],
              pic: asset['pic'],

              // Location details
              roomId: asset['room_id'],
              roomName: asset['room_name'],
              buildingName: asset['building_name'],
              floorNumber: asset['floor_number'],
              actualLocationName: asset[
                  'room_name'], // For unscanned assets, actual = expected = room
              expectedLocationName: asset['room_name'],
              expectedBuildingName: asset['building_name'],
              expectedFloorNumber: asset['floor_number'],

              // QR and timestamps
              qrCodePath: asset['qr_code'],
              createdAt: asset['created_at'],
              updatedAt: asset['updated_at'],

              // Category information
              category: asset['category'],
            );

            _allRoomAssets.add(item);
          }

          LoggerUtil.i(
              'Fetched ${_allRoomAssets.length} assets for room $roomId');
        } else {
          // If no data is returned, fall back to mock data
          _allRoomAssets = [];
          LoggerUtil.w(
              'No assets returned for room $roomId, falling back to mock data');
          await mockRoomAssets(roomId, opnameId);
        }
      } else {
        // Handle error response
        _allRoomAssets = [];

        try {
          final errorData = jsonDecode(response.body);
          _error =
              errorData['message']?.toString() ?? 'Failed to fetch room assets';
          LoggerUtil.e('Error from API: $_error');
        } catch (e) {
          _error = 'Failed to fetch room assets: ${response.statusCode}';
          LoggerUtil.e('Error parsing response: $e');
        }

        LoggerUtil.e('Error fetching room assets: $_error');
        await mockRoomAssets(roomId, opnameId);
      }
    } catch (e) {
      _error = 'Error fetching room assets: ${e.toString()}';
      LoggerUtil.e('Exception fetching room assets', e, StackTrace.current);
      await mockRoomAssets(roomId, opnameId);
    } finally {
      _isLoadingRoomAssets = false;
      notifyListeners();
    }
  }

  // Mock room assets if the API doesn't have the endpoint yet
  Future<void> mockRoomAssets(int roomId, int opnameId) async {
    // This is a temporary method to create mock data if the API endpoint isn't available
    try {
      _isLoadingRoomAssets = true;
      notifyListeners();

      await Future.delayed(
          const Duration(milliseconds: 800)); // Simulate network delay

      // Create mock data based on total assets for the opname
      final int totalAssets = getTotalAssets(opnameId);

      // Asset types for more realistic data
      final List<String> assetTypes = [
        'Patient Monitor',
        'Hospital Bed',
        'Ventilator',
        'ECG Machine',
        'Wheelchair',
        'Infusion Pump',
        'Defibrillator',
        'Ultrasound',
        'X-Ray Machine',
        'MRI Scanner',
        'CT Scanner',
        'Blood Pressure Monitor',
        'Oxygen Tank',
        'Nebulizer',
        'Surgical Instruments',
        'Stethoscope'
      ];

      final List<String> assetConditions = ['good', 'damaged'];

      _allRoomAssets = [];

      // Make sure we generate more assets than just what's scanned
      int mockTotal = math.max(10, totalAssets); // At least 10 assets

      // Generate mix of found, missing, pending assets
      for (int i = 0; i < mockTotal; i++) {
        final String assetCode =
            'ASSET-${roomId.toString().padLeft(3, '0')}-${(i + 1).toString().padLeft(4, '0')}';
        final String assetType = assetTypes[i % assetTypes.length];
        final String condition =
            assetConditions[i % 2]; // Alternate between good and damaged

        // Determine status based on position
        String status;
        if (i < _scannedItems.length) {
          // Already scanned assets
          status = 'found';
        } else if (i >= mockTotal - 3) {
          // Last 3 assets are missing
          status = 'missing';
        } else {
          // Rest are pending
          status = 'pending';
        }

        // Check if already in scanned items
        final existingScannedItem = _scannedItems
                .where((item) => item.assetCode == assetCode)
                .isEmpty
            ? null
            : _scannedItems.firstWhere((item) => item.assetCode == assetCode);

        if (existingScannedItem != null) {
          status = existingScannedItem.currentStatus;
        }

        final StockOpnameItem asset = StockOpnameItem(
          assetId: 1000 + i,
          assetCode: assetCode,
          assetName: assetType,
          location: 'Room $roomId',
          condition: condition,
          currentStatus: status,
          scanTime: DateTime.now().subtract(Duration(minutes: i)),
          notes: i % 5 == 0 ? 'Sample note for $assetType' : null,

          // Add mock image data
          referenceImagePath:
              i % 3 == 0 ? 'placeholder.png' : null, // Some assets have images
          brandName: i % 2 == 0 ? 'Brand ${i + 1}' : null,
          model: i % 3 == 0 ? 'Model-${i + 1}' : null,
          serialNumber: 'SN${(1000 + i).toString()}',
          category: assetTypes[i % assetTypes.length],
          assetType: i % 2 == 0 ? 'medical' : 'non_medical',

          // Location details
          roomId: roomId,
          roomName: 'Room $roomId',
          actualLocationName: 'Room $roomId',
          expectedLocationName: 'Room $roomId',
          expectedBuildingName: 'Building Mock',
          expectedFloorNumber: '1',
        );

        _allRoomAssets.add(asset);
      }

      // Add specific missing assets to ensure we have some
      for (int i = 0; i < 3; i++) {
        final String assetCode = 'MISSING-${opnameId}-${i + 1}';
        final String assetType =
            assetTypes[(mockTotal + i) % assetTypes.length];

        final StockOpnameItem missingItem = StockOpnameItem(
          assetId: -1000 - i, // Use negative IDs for placeholders
          assetCode: assetCode,
          assetName: 'Asset Tidak Ditemukan ${i + 1}',
          location: 'Room $roomId',
          condition: 'unknown',
          currentStatus: 'missing',
          scanTime: DateTime.now(),
          notes: 'Aset hilang atau tidak ditemukan',

          // Location details for missing items
          roomId: roomId,
          roomName: 'Room $roomId',
          actualLocationName: '',
          expectedLocationName: 'Room $roomId',
          expectedBuildingName: 'Building Mock',
          expectedFloorNumber: '1',
        );

        _allRoomAssets.add(missingItem);
      }

      // Make sure allRoomAssets contains all scannedItems
      for (final scannedItem in _scannedItems) {
        if (!_allRoomAssets
            .any((asset) => asset.assetCode == scannedItem.assetCode)) {
          _allRoomAssets.add(scannedItem);
        }
      }

      // Log details of the generated assets
      int foundCount = _allRoomAssets
          .where((asset) => asset.currentStatus == 'found')
          .length;
      int missingCount = _allRoomAssets
          .where((asset) => asset.currentStatus == 'missing')
          .length;
      int pendingCount = _allRoomAssets
          .where((asset) => asset.currentStatus == 'pending')
          .length;
      int misplacedCount = _allRoomAssets
          .where((asset) => asset.currentStatus == 'misplaced')
          .length;

      LoggerUtil.i(
          'Created ${_allRoomAssets.length} mock assets for room $roomId (Found: $foundCount, Missing: $missingCount, Pending: $pendingCount, Misplaced: $misplacedCount)');
    } catch (e) {
      _error = 'Error creating mock assets: ${e.toString()}';
      LoggerUtil.e('Exception creating mock assets', e, StackTrace.current);
    } finally {
      _isLoadingRoomAssets = false;
      notifyListeners();
    }
  }

  // Helper to get the total assets count for an opname
  int getTotalAssets(int opnameId) {
    final opname = _pendingOpnames.firstWhere(
      (o) => o.opnameId == opnameId,
      orElse: () => StockOpname(
        opnameId: opnameId,
        opnameCode: 'UNKNOWN',
        roomId: 0,
        roomName: 'Unknown',
        totalAssets: 10, // Default if not found
        scannedAssets: 0,
        status: 'pending',
      ),
    );

    return opname.totalAssets > 0 ? opname.totalAssets : 10;
  }

  // Method to load existing scanned items for an opname from API
  Future<void> loadExistingScannedItems(int opnameId) async {
    try {
      LoggerUtil.d('Loading existing scanned items for opname: $opnameId');

      final response =
          await auth.ApiService.get('/asset-opname-details/opname/$opnameId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['details'] != null) {
          List<dynamic> assetsJson = data['data']['details'];

          // Clear existing scanned items and reload from API
          _scannedItems.clear();

          for (var json in assetsJson) {
            try {
              // Only add items that were actually scanned (have scan_date and found/misplaced status)
              if (json['scan_date'] != null &&
                  (json['scan_status'] == 'found' ||
                      json['scan_status'] == 'misplaced')) {
                final item = StockOpnameItem(
                  // Basic asset information
                  assetId: json['asset_id'],
                  assetCode: json['asset_code'] ?? '',
                  assetName: json['asset_name'] ?? 'Unknown Asset',
                  location: json['actual_location_name'] ?? '',
                  condition: json['condition'] ?? 'good',
                  currentStatus: json['scan_status'] ?? 'found',
                  scanTime: json['scan_date'] != null
                      ? DateTime.tryParse(json['scan_date']) ?? DateTime.now()
                      : DateTime.now(),
                  notes: json['notes'],

                  // Additional detailed asset information
                  brandName: json['brand_name'],
                  model: json['model'],
                  serialNumber: json['serial_number'],
                  pic: json['pic'],
                  category: json['category'],
                  assetType: json['asset_type'],
                  referenceImagePath: json['reference_image_path'],

                  // Location details
                  roomId: json['actual_location_id'],
                  roomName: json['actual_location_name'],
                  actualLocationName: json['actual_location_name'],
                  expectedLocationName: json['expected_location_name'],
                  expectedBuildingName: json['expected_building_name'],
                  expectedFloorNumber: json['expected_floor_number'],

                  // QR and timestamps
                  createdAt: json['created_at'],
                  updatedAt: json['updated_at'],
                );

                _scannedItems.add(item);
              }
            } catch (e) {
              LoggerUtil.w('Error parsing scanned asset: $e');
            }
          }

          // Update local scanned count to match loaded items
          setLocalScannedCount(opnameId, _scannedItems.length);

          LoggerUtil.i(
              'Loaded ${_scannedItems.length} existing scanned items for opname $opnameId');
          notifyListeners();
        }
      }
    } catch (e) {
      LoggerUtil.e(
          'Error loading existing scanned items', e, StackTrace.current);
      // Don't throw error, just log it - this is not critical
    }
  }

  // Method to fetch all room assets (new endpoint-based approach)
  Future<List<Map<String, dynamic>>> fetchAllRoomAssets(int roomId) async {
    try {
      LoggerUtil.d('Fetching all assets for room ID: $roomId');

      // Use assets endpoint with room_id filter to get ALL assets in the room
      final response = await auth.ApiService.get('/assets?room_id=$roomId');

      LoggerUtil.d('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          List<dynamic> assetsJson = data['data'];
          LoggerUtil.d('Total assets loaded from API: ${assetsJson.length}');

          // Convert all room assets to our format
          List<Map<String, dynamic>> allAssets = [];

          for (var json in assetsJson) {
            try {
              // Get asset data from the room assets API
              final roomName = json['room_name'] ?? '';

              allAssets.add({
                'asset_id': json['asset_id'],
                'asset_code': json['asset_code']?.toString() ?? '',
                'asset_name': json['asset_master_name']?.toString() ??
                    json['asset_name']?.toString() ??
                    'Unknown Asset',
                'scan_status':
                    'pending', // Default to pending since these are all room assets
                'condition': json['condition']?.toString() ?? 'good',
                'actual_location_name': roomName,
                'expected_location_name': roomName,
                'expected_building_name':
                    json['building_name']?.toString() ?? '',
                'expected_floor_number': json['floor_number']?.toString() ?? '',
                'notes': '',
                'scan_date': null,
                // Additional detailed asset information
                'brand_name': json['brand_name']?.toString() ?? '',
                'model': json['model']?.toString() ?? '',
                'serial_number': json['serial_number']?.toString() ?? '',
                'asset_type': json['asset_type']?.toString() ?? '',
                'category': json['category']?.toString() ?? '',
                'pic': json['pic']?.toString() ?? '',
                'employee_name': json['employee_name']?.toString() ?? '',
                'employee_number': json['employee_number']?.toString() ?? '',
                'purchase_date': json['purchase_date']?.toString() ?? '',
                'purchase_cost': json['purchase_cost']?.toString() ?? '',
                'warranty_end_date':
                    json['warranty_end_date']?.toString() ?? '',
                'building_name': json['building_name']?.toString() ?? '',
                'floor_number': json['floor_number']?.toString() ?? '',
                'qr_code': json['qr_code']?.toString() ?? '',
                'current_status':
                    json['current_status']?.toString() ?? 'active',
                'created_at': json['created_at']?.toString() ?? '',
                'updated_at': json['updated_at']?.toString() ?? '',
                'reference_image_path':
                    json['reference_image_path']?.toString() ??
                        json['picture_path']?.toString() ??
                        json['qr_code']?.toString() ??
                        '',
                // Asset master information
                'asset_master_id': json['asset_master_id'],
                'asset_master_code':
                    json['asset_master_code']?.toString() ?? '',
                'asset_master_name':
                    json['asset_master_name']?.toString() ?? '',
                'description': json['description']?.toString() ?? '',
                'is_depreciable': json['is_depreciable'] ?? false,
                'needs_calibration': json['needs_calibration'] ?? false,
                'subcategory_name': json['subcategory_name']?.toString() ?? '',
                // Room and user information
                'room_id': json['room_id'],
                'user_id': json['user_id'],
                'brand_id': json['brand_id'],
              });
            } catch (e) {
              LoggerUtil.w('Error parsing asset: $e');
            }
          }

          LoggerUtil.d('Final asset count from room: ${allAssets.length}');
          return allAssets;
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      LoggerUtil.e('Error fetching room assets', e, StackTrace.current);
      // Fallback: try to get data from opname endpoint if room endpoint fails
      return await fetchOpnameAssetsAsFallback(roomId);
    }
  }

  // Fallback method to get data from opname endpoint if room endpoint fails
  Future<List<Map<String, dynamic>>> fetchOpnameAssetsAsFallback(
      int opnameId) async {
    try {
      LoggerUtil.w(
          'Using opname endpoint as fallback for opname ID: $opnameId');

      final response =
          await auth.ApiService.get('/asset-opname-details/opname/$opnameId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['details'] != null) {
          List<dynamic> assetsJson = data['data']['details'];

          // Convert to list of maps for easier processing
          List<Map<String, dynamic>> allAssets = [];

          for (var json in assetsJson) {
            try {
              allAssets.add({
                'asset_id': json['asset_id'],
                'asset_code': json['asset_code']?.toString() ?? '',
                'asset_name': json['asset_name']?.toString() ?? 'Unknown Asset',
                'scan_status': json['scan_status']?.toString() ?? 'pending',
                'condition': json['condition']?.toString() ?? 'unknown',
                'actual_location_name':
                    json['actual_location_name']?.toString() ?? '',
                'expected_location_name':
                    json['expected_location_name']?.toString() ?? '',
                'expected_building_name':
                    json['expected_building_name']?.toString() ?? '',
                'expected_floor_number':
                    json['expected_floor_number']?.toString() ?? '',
                'notes': json['notes']?.toString(),
                'scan_date': json['scan_date']?.toString(),
              });
            } catch (e) {
              LoggerUtil.w('Error parsing asset: $e');
            }
          }

          // Add placeholder for unscanned assets based on summary
          if (data['data']['summary'] != null) {
            final summary = data['data']['summary'];
            final int totalAssets = summary['total_assets'] ?? 0;
            final assetsInDetails = allAssets.length;

            if (assetsInDetails < totalAssets) {
              int unscannedToAdd = totalAssets - assetsInDetails;
              for (int i = 0; i < unscannedToAdd; i++) {
                allAssets.add({
                  'asset_id': 888888 + i,
                  'asset_code': 'PENDING-$opnameId-${i + 1}',
                  'asset_name': 'Asset Belum Dipindai ${i + 1}',
                  'scan_status': 'pending',
                  'condition': 'unknown',
                  'actual_location_name': '',
                  'expected_location_name': '',
                  'expected_building_name': '',
                  'expected_floor_number': '',
                  'notes': 'Asset belum dipindai',
                  'scan_date': null,
                });
              }
            }
          }

          return allAssets;
        }
      }

      // If fallback also fails, return empty list
      return [];
    } catch (e) {
      LoggerUtil.e('Fallback method also failed', e, StackTrace.current);
      return [];
    }
  }

  // Method to fetch room info including building details from server
  Future<Map<String, String?>> fetchRoomBuildingInfo(int roomId) async {
    try {
      LoggerUtil.d('Fetching room building info for room ID: $roomId');

      // Try to get room info from rooms endpoint first
      final response = await auth.ApiService.get('/rooms/$roomId');

      LoggerUtil.d(
          'Room info API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final roomData = data['data'];

          String? buildingName = roomData['building_name']?.toString();
          String? floorNumber = roomData['floor_number']?.toString();

          LoggerUtil.d(
              'Room info - Building: $buildingName, Floor: $floorNumber');

          return {
            'building_name': buildingName,
            'floor_number': floorNumber,
          };
        }
      }

      // Fallback: get building info from assets in that room
      LoggerUtil.d('Fallback: Getting building info from room assets');
      final roomAssets = await fetchAllRoomAssets(roomId);

      if (roomAssets.isNotEmpty) {
        final firstAsset = roomAssets.first;
        String? buildingName = firstAsset['building_name']?.toString();
        String? floorNumber = firstAsset['floor_number']?.toString();

        LoggerUtil.d(
            'From assets - Building: $buildingName, Floor: $floorNumber');

        return {
          'building_name': buildingName,
          'floor_number': floorNumber,
        };
      }

      LoggerUtil.w('No building info found for room $roomId');
      return {
        'building_name': null,
        'floor_number': null,
      };
    } catch (e) {
      LoggerUtil.e('Error fetching room building info', e, StackTrace.current);
      return {
        'building_name': null,
        'floor_number': null,
      };
    }
  }

  @override
  void dispose() {
    _buildingSearchDebounce?.cancel();
    _roomSearchDebounce?.cancel();
    super.dispose();
  }

  // Method to fetch complete asset details from server
  Future<StockOpnameItem?> fetchAssetDetails(
      String assetCode, BuildContext context) async {
    try {
      LoggerUtil.d('Fetching detailed asset information for: $assetCode');

      final response = await auth.ApiService.get(
        '/assets/qr/${Uri.encodeComponent(assetCode)}',
        context: context,
      );

      LoggerUtil.d(
          'Asset details API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final assetData = data['data'];

          // Extract asset master information if available
          final assetMaster = assetData['asset_master'];

          // Extract depreciation information if available
          final depreciationInfo = assetData['depreciation'];

          return StockOpnameItem(
            // Basic asset information
            assetId: assetData['asset_id'],
            assetCode: assetData['asset_code'],
            assetName: assetData['asset_master_name'] ??
                assetData['asset_name'] ??
                'Tidak diketahui',
            location: assetData['room_name'] ?? 'Tidak diketahui',
            condition: assetData['condition'] ?? 'Tidak diketahui',
            currentStatus: assetData['current_status'] ?? 'Tidak diketahui',
            scanTime: DateTime.now(),

            // Asset Master information
            assetMasterId: assetData['asset_master_id'],
            assetMasterCode: assetMaster?['asset_master_code'],
            assetMasterName: assetMaster?['asset_name'],
            description: assetMaster?['description'],
            assetType: assetMaster?['asset_type'],
            subcategoryName: assetMaster?['subcategory_name'],
            referenceImagePath: assetMaster?['reference_image_path'] ??
                assetData['reference_image_path'] ??
                assetData['qr_code'],
            isDepreciable: assetMaster?['is_depreciable'],
            needsCalibration: assetMaster?['needs_calibration'],

            // Physical asset details
            serialNumber: assetData['serial_number'],
            model: assetData['model'],
            brandId: assetData['brand_id'],
            brandName: assetData['brand_name'],

            // Purchase information
            purchaseDate: assetData['purchase_date'],
            purchaseCost: assetData['purchase_cost'],
            warrantyEndDate: assetData['warranty_end_date'],

            // Employee/PIC information
            userId: assetData['user_id'],
            employeeNumber: assetData['employee_number'],
            employeeName: assetData['employee_name'],
            pic: assetData['pic'],

            // Location details
            roomId: assetData['room_id'],
            roomName: assetData['room_name'],
            buildingName: assetData['building_name'],
            floorNumber: assetData['floor_number'],
            actualLocationName:
                assetData['actual_location_name'] ?? assetData['room_name'],
            expectedLocationName:
                assetData['expected_location_name'] ?? assetData['room_name'],
            expectedBuildingName: assetData['expected_building_name'] ??
                assetData['building_name'],
            expectedFloorNumber:
                assetData['expected_floor_number'] ?? assetData['floor_number'],

            // QR and timestamps
            qrCodePath: assetData['qr_code'],
            createdAt: assetData['created_at'],
            updatedAt: assetData['updated_at'],

            // Depreciation info
            depreciationInfo: depreciationInfo,

            // Category information
            category: assetData['category'],
          );
        } else {
          LoggerUtil.w(
              'Invalid response format or no data: ${data['message']}');
          return null;
        }
      } else {
        LoggerUtil.e('Failed to fetch asset details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerUtil.e('Exception fetching asset details', e, StackTrace.current);
      return null;
    }
  }

  // Method to save notes for scanned assets to API
  Future<bool> saveAssetNotes(
      String assetCode, String notes, BuildContext context) async {
    try {
      LoggerUtil.d('Saving notes for asset: $assetCode');

      // Find the scanned asset to get its detail information
      final scannedAsset = _scannedItems.firstWhere(
        (item) => item.assetCode == assetCode,
        orElse: () => throw Exception('Asset not found in scanned items'),
      );

      // For now, we'll simulate API call since we need the detail_id from opname-details endpoint
      // In a real scenario, you would need to get the detail_id from the asset-opname-details endpoint first
      LoggerUtil.d(
          'Simulating notes save for asset: $assetCode with notes: $notes');

      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Update local asset notes
      final assetIndex =
          _scannedItems.indexWhere((item) => item.assetCode == assetCode);
      if (assetIndex != -1) {
        _scannedItems[assetIndex] =
            _scannedItems[assetIndex].copyWith(notes: notes);

        // Also update in allRoomAssets if it exists there
        final roomAssetIndex =
            _allRoomAssets.indexWhere((item) => item.assetCode == assetCode);
        if (roomAssetIndex != -1) {
          _allRoomAssets[roomAssetIndex] =
              _allRoomAssets[roomAssetIndex].copyWith(notes: notes);
        }

        notifyListeners();
        LoggerUtil.i('Notes saved locally for asset: $assetCode');
        return true;
      }

      return false;
    } catch (e) {
      LoggerUtil.e('Error saving asset notes', e, StackTrace.current);
      _error = 'Gagal menyimpan catatan: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
