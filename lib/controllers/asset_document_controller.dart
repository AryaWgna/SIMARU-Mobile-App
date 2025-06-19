import 'package:flutter/material.dart';
import '../models/asset_document_model.dart';
import '../controllers/auth_controller.dart' as auth;
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../core/config/api_config.dart';

class AssetDocumentController extends ChangeNotifier {
  List<AssetDocumentModel> _documents = [];
  bool _isLoading = false;
  String? _error;
  File? _selectedFile;
  bool _isUploading = false;
  bool _showAntiScreenshotMessage = false;
  String _randomSecurityId = '';
  int _refreshCount = 0;

  // Getters
  List<AssetDocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  File? get selectedFile => _selectedFile;
  bool get isUploading => _isUploading;
  bool get showAntiScreenshotMessage => _showAntiScreenshotMessage;
  String get randomSecurityId => _randomSecurityId;
  int get refreshCount => _refreshCount;

  // Method untuk mengatur status loading secara manual
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      print('AssetDocumentController loading state set to: $_isLoading');
    }
  }

  // Method untuk mengatur error secara manual
  void setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Method untuk mengatur file yang dipilih
  void setSelectedFile(File file) {
    _selectedFile = file;
    notifyListeners();
  }

  // Method untuk menghapus file yang dipilih
  void clearSelectedFile() {
    _selectedFile = null;
    notifyListeners();
  }

  // Method untuk menampilkan pesan anti-screenshot
  void showAntiScreenshotNotification() {
    _showAntiScreenshotMessage = true;
    notifyListeners();

    // Sembunyikan pesan setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      _showAntiScreenshotMessage = false;
      notifyListeners();
    });
  }

  // Method untuk mengatur visibility pesan anti-screenshot
  void setAntiScreenshotMessageVisibility(bool visible) {
    _showAntiScreenshotMessage = visible;
    notifyListeners();
  }

  // Method untuk generate random ID
  String generateRandomId() {
    final random = Random();
    _randomSecurityId = DateTime.now().microsecondsSinceEpoch.toString() +
        random.nextInt(10000).toString();
    notifyListeners();
    return _randomSecurityId;
  }

  // Method untuk increment refresh counter
  void incrementRefreshCount() {
    _refreshCount++;
    notifyListeners();
  }

  // Mengambil dokumen aset berdasarkan asset_id
  Future<void> fetchAssetDocuments(int assetId, BuildContext context) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Menggunakan endpoint yang benar sesuai dengan dokumentasi API
      final endpoint = '/asset-documents/asset/$assetId/documents';
      print('Memanggil API endpoint: ${ApiConfig.baseUrl}$endpoint');

      final response = await auth.ApiService.get(endpoint, context: context);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> documentsJson = data['data'];
          _documents = documentsJson
              .map((json) => AssetDocumentModel.fromJson(json))
              .toList();
          print('Berhasil mendapatkan ${_documents.length} dokumen');
        } else {
          _error = data['message'] ?? 'Gagal mengambil data dokumen';
          print('Error dari API: $_error');
        }
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching asset documents: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengunggah dokumen baru
  Future<bool> uploadDocument(int assetId, String title, String description,
      BuildContext context) async {
    if (_selectedFile == null) {
      _error = 'Tidak ada file yang dipilih';
      notifyListeners();
      return false;
    }

    try {
      _isUploading = true;
      notifyListeners();

      // Persiapan data untuk multipart request - menggunakan endpoint yang benar
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/asset-documents/asset/$assetId/documents');
      print('Mengunggah dokumen ke: $url');

      // Ambil token autentikasi
      final token = await auth.ApiService.getAuthToken();
      if (token == null) {
        _error = 'Token autentikasi tidak tersedia';
        _isUploading = false;
        notifyListeners();
        return false;
      }

      // Buat request multipart
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Authorization': 'Bearer $token',
        })
        ..fields['document_title'] =
            title // Sesuaikan dengan field yang diharapkan API
        ..fields['notes'] =
            description // Sesuaikan dengan field yang diharapkan API
        ..files.add(await http.MultipartFile.fromPath(
          'file', // Nama field sesuai dengan API
          _selectedFile!.path,
          filename: path.basename(_selectedFile!.path),
        ));

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Upload response status: ${response.statusCode}');
      print('Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Muat ulang dokumen
          await fetchAssetDocuments(assetId, context);
          // Reset file yang dipilih
          _selectedFile = null;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Gagal mengunggah dokumen';
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
      print('Error uploading document: $e');
      notifyListeners();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Menghapus dokumen
  Future<bool> deleteDocument(
      int documentId, int assetId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Menggunakan endpoint yang benar untuk menghapus dokumen dari aset
      final endpoint = '/asset-documents/asset/$assetId/documents/$documentId';
      print(
          'Memanggil API endpoint untuk hapus: ${ApiConfig.baseUrl}$endpoint');

      final response = await auth.ApiService.delete(endpoint, context: context);
      print('Delete response status: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Muat ulang dokumen
          await fetchAssetDocuments(assetId, context);
          return true;
        } else {
          _error = data['message'] ?? 'Gagal menghapus dokumen';
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
      print('Error deleting document: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mengunduh dokumen
  Future<File?> downloadDocument(
      int documentId, String fileName, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Menggunakan endpoint yang benar untuk mengunduh dokumen
      final endpoint = '/asset-documents/documents/$documentId/download';
      print(
          'Memanggil API endpoint untuk download: ${ApiConfig.baseUrl}$endpoint');

      final response = await auth.ApiService.get(endpoint, context: context);
      print('Download response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // TODO: Implementasikan logika untuk menyimpan file ke penyimpanan lokal
        // Ini memerlukan package eksternal seperti path_provider
        // dan kode tambahan untuk menyimpan file

        _isLoading = false;
        notifyListeners();
        return null; // Kembalikan file jika berhasil diunduh
      } else {
        _error = 'HTTP Error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = e.toString();
      print('Error downloading document: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
