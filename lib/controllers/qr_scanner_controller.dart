import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart';
import '../services/socket_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import '../utils/logger_util.dart';

class QRScannerController extends ChangeNotifier {
  String? _scannedCode;
  String? _lastScannedCode;
  bool _isProcessing = false;
  bool _flashOn = false;
  String? _errorMessage;
  Map<String, dynamic>? _assetData;
  final _storage = const FlutterSecureStorage();
  MobileScannerController? _mobileScannerController;

  // Tambahkan state untuk kamera
  bool _isCameraInitialized = false;
  bool _isCameraPaused = false;
  int _animationUpdateCounter = 0;

  // Getters
  String? get scannedCode => _scannedCode;
  String? get lastScannedCode => _lastScannedCode;
  bool get isProcessing => _isProcessing;
  bool get flashOn => _flashOn;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get assetData => _assetData;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isCameraPaused => _isCameraPaused;
  int get animationUpdateCounter => _animationUpdateCounter;
  MobileScannerController? get qrViewController => _mobileScannerController;

  // Setters
  void setScannedCode(String? code) {
    _scannedCode = code;
    notifyListeners();
  }

  void setLastScannedCode(String? code) {
    _lastScannedCode = code;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void toggleFlash() {
    _flashOn = !_flashOn;
    if (_mobileScannerController != null) {
      _mobileScannerController!.toggleTorch();
    }
    notifyListeners();
  }

  void setFlash(bool on) {
    _flashOn = on;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Metode untuk mengelola MobileScannerController
  void setQRViewController(MobileScannerController controller) {
    _mobileScannerController = controller;
    notifyListeners();
  }

  void pauseCamera() {
    if (_mobileScannerController != null && !_isCameraPaused) {
      _mobileScannerController!.stop();
      _isCameraPaused = true;
      notifyListeners();
    }
  }

  void resumeCamera() {
    if (_mobileScannerController != null && _isCameraPaused) {
      _mobileScannerController!.start();
      _isCameraPaused = false;
      notifyListeners();
    }
  }

  void disposeQRController() {
    if (_mobileScannerController != null) {
      _mobileScannerController!.dispose();
      _mobileScannerController = null;
    }
  }

  void reassembleCamera() {
    if (_mobileScannerController != null) {
      if (Platform.isAndroid) {
        _mobileScannerController!.stop();
      }
      _mobileScannerController!.start();
    }
  }

  // Metode untuk mengelola state kamera
  void setCameraInitialized(bool initialized) {
    _isCameraInitialized = initialized;
    notifyListeners();
  }

  void setCameraPaused(bool paused) {
    _isCameraPaused = paused;
    notifyListeners();
  }

  void triggerAnimationUpdate() {
    _animationUpdateCounter++;
    notifyListeners();
  }

  // Process scanned QR code
  Future<Map<String, dynamic>?> processScannedQR(
      String code, SocketService socketService, BuildContext context) async {
    // Prevent multiple processing of the same code
    if (_isProcessing || code == _lastScannedCode) {
      return null;
    }

    setProcessing(true);
    setLastScannedCode(code);
    clearError();

    try {
      LoggerUtil.i('Processing QR code: $code');

      // Try to parse the QR code as a URL or asset code
      String assetCode;

      if (code.contains('/')) {
        // Extract asset code from URL
        final uri = Uri.parse(code);
        final pathSegments = uri.pathSegments;

        if (pathSegments.isEmpty) {
          throw Exception('Format QR code tidak valid');
        }

        assetCode = pathSegments.last;
      } else {
        // Use the code directly as asset code
        assetCode = code;
      }

      LoggerUtil.d('Extracted asset code: $assetCode');

      // Get asset data
      final assetData = await _getAssetData(assetCode, context);
      _assetData = assetData;

      // Emit socket event for tracking
      _emitScanEvent(socketService, assetData, context);

      return assetData;
    } catch (e) {
      LoggerUtil.e('Error processing QR', e, StackTrace.current);
      setError('Error: ${e.toString().replaceAll('Exception: ', '')}');
      return null;
    } finally {
      setProcessing(false);
    }
  }

  // Get asset data from API
  Future<Map<String, dynamic>> _getAssetData(
      String assetCode, BuildContext context) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      // Menggunakan endpoint /assets/qr/:assetCode sesuai dengan dokumentasi API
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/assets/qr/${Uri.encodeComponent(assetCode)}');

      LoggerUtil.d('Calling API endpoint: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(url, headers: headers);
      LoggerUtil.d('API response status: ${response.statusCode}');
      LoggerUtil.d('API response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerUtil.d('API response data structure: ${data.keys}');

        if (data['data'] != null) {
          // Cek struktur data yang diterima
          final assetData = data['data'];
          LoggerUtil.d('Asset data fields: ${assetData.keys}');

          // Debugging untuk employee_number dan brand
          LoggerUtil.d('Employee number: ${assetData['employee_number']}');
          LoggerUtil.d('Brand info direct: ${assetData['brand']}');

          if (assetData['asset_master'] != null) {
            LoggerUtil.d(
                'Asset master fields: ${assetData['asset_master'].keys}');

            // Debug brand dari asset_master
            if (assetData['asset_master']['brand'] != null) {
              LoggerUtil.d(
                  'Brand from asset_master: ${assetData['asset_master']['brand']}');
            }
          }

          return data['data'];
        } else {
          throw Exception('Data aset tidak ditemukan');
        }
      } else if (response.statusCode == 401) {
        // Handle unauthorized - token expired
        throw Exception('Sesi berakhir. Silakan login kembali.');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mendapatkan data aset');
      }
    } catch (e) {
      LoggerUtil.e('Error getting asset data', e, StackTrace.current);
      throw Exception('Gagal mengambil data aset: ${e.toString()}');
    }
  }

  // Emit socket event for tracking
  void _emitScanEvent(SocketService socketService,
      Map<String, dynamic> assetData, BuildContext context) {
    try {
      if (socketService.isConnected && assetData.isNotEmpty) {
        final assetId = assetData['id'] ?? assetData['asset_id'];
        final assetCode = assetData['asset_code'] ?? '';

        if (assetId != null) {
          // Send message through socket
          final eventData = {
            'type': 'asset_scanned',
            'asset_id': assetId.toString(),
            'asset_code': assetCode,
            'timestamp': DateTime.now().toIso8601String()
          };

          socketService.sendMessage(json.encode(eventData), context);
        }
      }
    } catch (e) {
      LoggerUtil.e('Error emitting socket event', e, StackTrace.current);
    }
  }

  // Reset controller state
  void reset() {
    _scannedCode = null;
    _lastScannedCode = null;
    _isProcessing = false;
    _errorMessage = null;
    _assetData = null;
    _isCameraInitialized = false;
    _isCameraPaused = false;
    _animationUpdateCounter = 0;
    notifyListeners();
  }
}
