import 'package:flutter/material.dart';
import 'dart:convert';
import 'auth_controller.dart';
import '../utils/logger_util.dart';

class AssetCheckoutController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _roomList = [];
  bool _isEmployeeSelected = true; // Default ke Employee
  String? _selectedRoom;
  DateTime _currentDate = DateTime.now();

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get roomList => _roomList;
  bool get isEmployeeSelected => _isEmployeeSelected;
  String? get selectedRoom => _selectedRoom;
  DateTime get currentDate => _currentDate;

  // Setters
  void setIsEmployeeSelected(bool value) {
    _isEmployeeSelected = value;
    notifyListeners();
  }

  void setSelectedRoom(String? value) {
    _selectedRoom = value;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('AssetCheckoutController loading state set to: $_isLoading');
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

  // Fetch rooms from API
  Future<void> fetchRooms(BuildContext context) async {
    try {
      setLoading(true);
      clearError();

      final response = await ApiService.get('/rooms', context: context);
      LoggerUtil.d('Room response: ${response.statusCode}');
      LoggerUtil.d('Room body received with ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool isSuccess =
            data['success'] == true || data['status'] == true;

        if (isSuccess && data['data'] != null) {
          if (data['data'] is List) {
            _roomList = List<Map<String, dynamic>>.from(data['data']);
            LoggerUtil.i('Rooms loaded: ${_roomList.length}');
          }
        } else {
          setError('Gagal memuat daftar ruangan: ${data['message']}');
        }
      } else {
        setError('Gagal memuat daftar ruangan: ${response.statusCode}');
      }
    } catch (e) {
      setError('Error: ${e.toString()}');
      LoggerUtil.e('Error fetching rooms', e, StackTrace.current);
    } finally {
      setLoading(false);
    }
  }

  // Process checkout
  Future<Map<String, dynamic>?> processCheckout({
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

      Map<String, dynamic> requestBody;

      if (_isEmployeeSelected) {
        // Checkout ke karyawan
        requestBody = {
          "asset_id": assetId,
          "checkout_notes": notes,
        };
      } else {
        // Checkout ke lokasi
        if (_selectedRoom == null) {
          setError('Silakan pilih ruangan');
          return null;
        }

        requestBody = {
          "asset_id": assetId,
          "room_id": int.parse(_selectedRoom!),
          "checkout_notes": notes,
        };
      }

      LoggerUtil.i('Sending checkout request for asset ID: ${assetId}');

      final response = await ApiService.post(
        '/asset-transfers/checkout',
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
            'message': 'Peminjaman berhasil',
            'current_status': 'check out'
          };
        } else {
          throw Exception(data['message'] ?? 'Peminjaman gagal');
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(
            data['message'] ?? 'Peminjaman gagal: ${response.statusCode}');
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
    _isEmployeeSelected = true;
    _selectedRoom = null;
    notifyListeners();
  }
}
