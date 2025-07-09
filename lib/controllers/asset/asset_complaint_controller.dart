import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../../core/config/api_config.dart';
import '../auth/auth_controller.dart';
import '../../utils/logger_util.dart';

class AssetComplaintController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedImage;
  bool _isSuccess = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get selectedImage => _selectedImage;
  bool get isSuccess => _isSuccess;

  // Method to reset all state when entering complaint screen
  void resetState() {
    _isLoading = false;
    _errorMessage = null;
    _selectedImage = null;
    _isSuccess = false;
    notifyListeners();
    LoggerUtil.d('AssetComplaintController: State reset');
  }

  void setImage(File? image) {
    _selectedImage = image;
    _errorMessage = null;
    notifyListeners();
    LoggerUtil.d('AssetComplaintController: Image set');
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
    LoggerUtil.d('AssetComplaintController: Image cleared');
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      LoggerUtil.d(
          'AssetComplaintController: Loading state set to $_isLoading');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> validateImageFile(File image) async {
    try {
      // Validasi format file
      final String extension = image.path.split('.').last.toLowerCase();
      LoggerUtil.d('[COMPLAINT DEBUG] Image extension: $extension');

      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        _errorMessage =
            'Format file tidak didukung. Gunakan: JPG, JPEG, atau PNG.';
        notifyListeners();
        return false;
      }

      // Validasi ukuran file
      final int fileSize = await image.length();
      final double fileSizeInMB = fileSize / (1024 * 1024);
      LoggerUtil.d(
          '[COMPLAINT DEBUG] Image size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      if (fileSizeInMB > 5) {
        _errorMessage = 'Ukuran file terlalu besar. Maksimal 5 MB.';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error memvalidasi gambar: $e';
      notifyListeners();
      LoggerUtil.e('[COMPLAINT DEBUG] Error in validateImageFile', e,
          StackTrace.current);
      return false;
    }
  }

  Future<bool> submitComplaint({
    required int assetId,
    required String description,
  }) async {
    if (description.length < 5) {
      _errorMessage = 'Deskripsi minimal 5 karakter';
      notifyListeners();
      return false;
    }

    setLoading(true);
    _errorMessage = null;
    _isSuccess = false;

    try {
      var complaintUrl = ApiConfig.complaintsUrl;
      LoggerUtil.d('[COMPLAINT DEBUG] Using complaint URL: $complaintUrl');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(complaintUrl),
      );

      // Menggunakan asset_id sebagai number
      request.fields['asset_id'] = assetId.toString();
      request.fields['description'] = description;

      // Menambahkan image jika ada
      if (_selectedImage != null) {
        try {
          // Mendapatkan MIME type
          final String extension =
              _selectedImage!.path.split('.').last.toLowerCase();
          String mimeType;

          if (extension == 'jpg' || extension == 'jpeg') {
            mimeType = 'image/jpeg';
          } else if (extension == 'png') {
            mimeType = 'image/png';
          } else {
            mimeType = 'application/octet-stream';
          }

          LoggerUtil.d(
              '[COMPLAINT DEBUG] File MIME type: $mimeType, extension: $extension');

          // Membaca file sebagai bytes
          final bytes = await _selectedImage!.readAsBytes();
          final filename = _selectedImage!.path.split('/').last;

          // Membuat multipart file dengan MIME type yang spesifik
          final multipartFile = http.MultipartFile.fromBytes(
            'image_file',
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          );

          request.files.add(multipartFile);
          LoggerUtil.d(
              '[COMPLAINT DEBUG] Added file $filename with MIME type $mimeType');
        } catch (e) {
          LoggerUtil.e(
              '[COMPLAINT DEBUG] Error adding file', e, StackTrace.current);
          _errorMessage = 'Error saat mengunggah gambar: $e';
          setLoading(false);
          return false;
        }
      }

      // Menambahkan token otorisasi
      final accessToken = await ApiService.getAccessToken();
      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Log request
      LoggerUtil.d('[COMPLAINT DEBUG] Request headers: ${request.headers}');
      LoggerUtil.d('[COMPLAINT DEBUG] Request fields: ${request.fields}');
      if (request.files.isNotEmpty) {
        LoggerUtil.d(
            '[COMPLAINT DEBUG] Request files: ${request.files.length} file(s)');
        for (var file in request.files) {
          LoggerUtil.d(
              '[COMPLAINT DEBUG] File: ${file.filename}, field: ${file.field}, contentType: ${file.contentType}');
        }
      }

      // Mengirim request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      LoggerUtil.d('Submit complaint response: ${response.statusCode}');
      LoggerUtil.d('Response body: ${response.body}');

      // Parse response
      var jsonResponse = json.decode(response.body);

      // Cek response code dan status
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (jsonResponse['success'] == true) {
          _isSuccess = true;
          setLoading(false);
          return true;
        } else {
          _errorMessage = jsonResponse['message'] ?? 'Gagal mengirim komplain';
        }
      } else if (response.statusCode == 400) {
        // Menampilkan pesan error untuk bad request
        if (jsonResponse['errors'] is List) {
          // Jika errors adalah array, gabungkan semua pesan
          _errorMessage = (jsonResponse['errors'] as List).join(', ');
        } else if (jsonResponse['errors'] is Map) {
          // Jika errors adalah object, gabungkan semua value
          _errorMessage = (jsonResponse['errors'] as Map).values.join(', ');
        } else {
          // Jika single string atau tipe lain
          _errorMessage =
              jsonResponse['errors']?.toString() ?? 'Data tidak valid';
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Sesi anda telah berakhir. Silakan login kembali.';
      } else if (response.statusCode == 404) {
        if (jsonResponse['errors'] is List) {
          _errorMessage = (jsonResponse['errors'] as List).join(', ');
        } else {
          _errorMessage =
              jsonResponse['errors']?.toString() ?? 'Aset tidak ditemukan';
        }
      } else if (response.statusCode == 500) {
        if (response.body
            .toLowerCase()
            .contains('format file tidak didukung')) {
          if (jsonResponse['errors'] is List) {
            _errorMessage = (jsonResponse['errors'] as List).join(', ');
          } else {
            _errorMessage = jsonResponse['errors']?.toString() ??
                'Format file tidak didukung. Gunakan: image/jpeg, image/jpg, atau image/png';
          }
        } else {
          if (jsonResponse['errors'] is List) {
            _errorMessage = (jsonResponse['errors'] as List).join(', ');
          } else {
            _errorMessage = jsonResponse['errors']?.toString() ??
                'Terjadi kesalahan pada server';
          }
        }
      } else {
        // Menampilkan pesan error umum
        if (jsonResponse['errors'] is List) {
          _errorMessage = (jsonResponse['errors'] as List).join(', ');
        } else {
          _errorMessage = 'Gagal mengirim komplain: ${response.statusCode}';
        }
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      LoggerUtil.e(
          'Exception during complaint submission', e, StackTrace.current);
    } finally {
      setLoading(false);
    }

    notifyListeners();
    return _isSuccess;
  }
}
