import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/complaint_model.dart';
import 'auth_controller.dart';

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
      print('ComplaintController loading state set to: $_isLoading');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<String?> _getUserId() async {
    try {
      // Ambil user_id dari Flutter Secure Storage
      final userId = await _storage.read(key: 'user_id');
      print('Retrieved user_id from storage: $userId');

      if (userId == null || userId.isEmpty) {
        // Coba ambil dari token
        final token = await ApiService.getAccessToken();
        if (token != null) {
          print('Trying to decode token: $token');
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
            print('Token payload: $decodedPayload');

            if (decodedPayload['user_id'] != null) {
              final userIdFromToken = decodedPayload['user_id'].toString();
              print('Found user_id in token: $userIdFromToken');
              await _storage.write(key: 'user_id', value: userIdFromToken);
              print('Saved user_id from token to storage');

              return userIdFromToken;
            }
          }
        }
        return null;
      }

      return userId;
    } catch (e) {
      print('Error getting user ID: $e');
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

      print('Complaint API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Complaint API response body: ${response.body}');

        if (jsonResponse['success'] == true) {
          if (jsonResponse['data'] != null) {
            final List<dynamic> complaintsJson = jsonResponse['data'];
            _complaints = complaintsJson
                .map((json) => ComplaintModel.fromJson(json))
                .toList();

            print('Loaded ${_complaints.length} complaints');

            // Parse pagination if available
            if (jsonResponse['pagination'] != null) {
              _pagination =
                  ComplaintPagination.fromJson(jsonResponse['pagination']);
              print('Pagination: ${_pagination?.totalItems} total items');
            }

            _isSuccess = true;
          } else {
            _complaints = [];
            print('No complaints data in response');
          }
        } else {
          _errorMessage =
              jsonResponse['message'] ?? 'Failed to load complaints';
          print('API error: $_errorMessage');
        }
      } else {
        _errorMessage = 'Server error: ${response.statusCode}';
        print('API status code error: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading complaints: $e');
    } finally {
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
      print('Error fetching complaint detail: $e');
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
      print('Error approving repair: $e');
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
