import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/complaint_model.dart';
import 'auth_controller.dart';
import '../utils/logger_util.dart';

class ComplaintController extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  String? _errorMessage;
  ComplaintPagination? _pagination;
  bool _isSuccess = false;
  ComplaintModel? _complaintDetail;
  bool _isApproving = false;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ComplaintPagination? get pagination => _pagination;
  bool get isSuccess => _isSuccess;
  bool get hasError => _errorMessage != null;
  ComplaintModel? get complaintDetail => _complaintDetail;
  bool get isApproving => _isApproving;

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d('ComplaintController loading state set to: $_isLoading');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearComplaintDetail() {
    _complaintDetail = null;
    notifyListeners();
  }

  Future<String?> _getUserId() async {
    try {
      // Ambil user_id dari Flutter Secure Storage
      final userId = await _storage.read(key: 'user_id');
      LoggerUtil.d('Retrieved user_id from storage: $userId');

      if (userId == null || userId.isEmpty) {
        // Coba ambil dari token
        final token = await ApiService.getAccessToken();
        if (token != null) {
          LoggerUtil.d('Trying to decode token: ${token.substring(0, 10)}...');
          // Decode token untuk mendapatkan user_id
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized =
                payload.replaceAll('-', '+').replaceAll('_', '/');
            final padded = normalized.padRight(
                normalized.length + (4 - normalized.length % 4) % 4, '=');
            final decoded = utf8.decode(base64Url.decode(padded));
            final decodedPayload = json.decode(decoded);
            LoggerUtil.d('Token payload decoded successfully');

            if (decodedPayload['user_id'] != null) {
              final userIdFromToken = decodedPayload['user_id'].toString();
              LoggerUtil.d('Found user_id in token: $userIdFromToken');
              await _storage.write(key: 'user_id', value: userIdFromToken);
              LoggerUtil.d('Saved user_id from token to storage');

              return userIdFromToken;
            }
          }
        }
        return null;
      }

      return userId;
    } catch (e) {
      LoggerUtil.e('Error getting user ID', e, StackTrace.current);
      return null;
    }
  }

  Future<void> fetchComplaints() async {
    setLoading(true);
    _errorMessage = null;
    _isSuccess = false;

    try {
      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('User ID tidak ditemukan');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/user/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      LoggerUtil.d(
          'Complaint API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        LoggerUtil.d('Complaint API response received successfully');

        if (jsonResponse['success'] == true) {
          if (jsonResponse['data'] != null) {
            final List<dynamic> complaintsJson = jsonResponse['data'];
            _complaints = complaintsJson
                .map((json) => ComplaintModel.fromJson(json))
                .toList();

            LoggerUtil.i('Loaded ${_complaints.length} complaints');

            // Parse pagination if available
            if (jsonResponse['pagination'] != null) {
              _pagination =
                  ComplaintPagination.fromJson(jsonResponse['pagination']);
              LoggerUtil.d(
                  'Pagination: ${_pagination?.totalItems} total items');
            }

            _isSuccess = true;
          } else {
            _complaints = [];
            LoggerUtil.i('No complaints data in response');
          }
        } else {
          _errorMessage =
              jsonResponse['message'] ?? 'Failed to load complaints';
          LoggerUtil.w('API error: $_errorMessage');
        }
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
        LoggerUtil.w('API status code error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = e.toString();
      LoggerUtil.e('Error loading complaints', e, StackTrace.current);
    } finally {
      // Explicitly ensure loading state is set to false
      setLoading(false);
    }
  }

  Future<void> fetchComplaintDetail(int complaintId) async {
    try {
      setLoading(true);
      _errorMessage = null;

      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/complaints/$complaintId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _complaintDetail = ComplaintModel.fromJson(data['data']);
          _isSuccess = true;
        } else {
          throw Exception(
              data['message'] ?? 'Failed to fetch complaint details');
        }
      } else {
        throw Exception(
            'Failed to load complaint details: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isSuccess = false;
      LoggerUtil.e('Error fetching complaint detail', e, StackTrace.current);
    } finally {
      setLoading(false);
    }
  }

  Future<bool> approveRepair() async {
    try {
      _isApproving = true;
      notifyListeners();
      _errorMessage = null;

      final accessToken = await ApiService.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      final repairId = _complaintDetail?.repair?['id'].toString();
      if (repairId == null) {
        throw Exception('Repair ID tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/repairs/$repairId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Refresh complaint detail
        await fetchComplaintDetail(_complaintDetail!.id);
        return true;
      } else {
        final responseData = jsonDecode(response.body);
        _errorMessage = responseData['message'] ?? 'Gagal menyetujui perbaikan';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      LoggerUtil.e('Error approving repair', e, StackTrace.current);
      return false;
    } finally {
      _isApproving = false;
      notifyListeners();
    }
  }

  // Format date helper
  String formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')} March ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
