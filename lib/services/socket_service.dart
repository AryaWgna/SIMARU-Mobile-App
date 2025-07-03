import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger_util.dart';

// Class untuk layanan WebSocket
class SocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _lastMessage;

  bool get isConnected => _isConnected;
  String? get lastMessage => _lastMessage;

  // URL WebSocket, gunakan wss:// untuk HTTPS dan ws:// untuk HTTP
  String get _getWebSocketUrl {
    final baseUrl = kDebugMode
        ? ApiConfig.baseUrl.replaceFirst('http', 'ws')
        : ApiConfig.baseUrl.replaceFirst('https', 'wss');
    return '$baseUrl/ws';
  }

  // Metode untuk menghubungkan ke WebSocket
  void connect() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(_getWebSocketUrl),
      );
      _isConnected = true;
      notifyListeners();

      // Listen untuk pesan yang masuk
      _channel!.stream.listen(
        (message) {
          _lastMessage = message;
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
        onError: (error) {
          LoggerUtil.e('WebSocket Error', error, StackTrace.current);
          _isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      LoggerUtil.e('Failed to connect to WebSocket', e, StackTrace.current);
      _isConnected = false;
      notifyListeners();
    }
  }

  // Metode untuk mengirim pesan melalui WebSocket
  void sendMessage(String message, BuildContext context) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(message);
      } catch (e) {
        LoggerUtil.e('Error sending message', e, StackTrace.current);
      }
    } else {
      LoggerUtil.w('WebSocket not connected! Attempting to reconnect...');
      // Mencoba menghubungkan kembali
      connect();
    }
  }

  // Metode untuk menutup koneksi WebSocket
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _isConnected = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// Class untuk layanan REST API
class ApiService {
  static void Function(BuildContext context)? navigateToLogin;
  static const _storage = FlutterSecureStorage();

  // Metode untuk mendapatkan token dari secure storage
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: 'accessToken');
    } catch (e) {
      LoggerUtil.e('Error getting access token', e, StackTrace.current);
      return null;
    }
  }

  // Metode GET untuk REST API
  static Future<http.Response> get(String endpoint,
      {BuildContext? context}) async {
    try {
      final token = await getAccessToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      LoggerUtil.d('Making GET request to: $url');
      final response = await http.get(url, headers: headers);

      // Log response for debugging
      LoggerUtil.d('Response status: ${response.statusCode}');
      LoggerUtil.d('Response body length: ${response.body.length} bytes');

      // Handle 401 Unauthorized - Token expired or invalid
      if (response.statusCode == 401 &&
          context != null &&
          navigateToLogin != null) {
        LoggerUtil.w('401 Unauthorized - Navigating to login');
        navigateToLogin!(context);
        throw ApiException('Session expired. Please login again.');
      }

      return response;
    } catch (e) {
      LoggerUtil.e('Error in GET request', e, StackTrace.current);
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: $e');
    }
  }

  // Metode POST untuk REST API
  static Future<http.Response> post(String endpoint, dynamic data,
      {BuildContext? context}) async {
    try {
      final token = await getAccessToken();
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      LoggerUtil.d('Making POST request to: $url');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(data),
      );

      // Handle 401 Unauthorized - Token expired or invalid
      if (response.statusCode == 401 &&
          context != null &&
          navigateToLogin != null) {
        LoggerUtil.w('401 Unauthorized - Navigating to login');
        navigateToLogin!(context);
        throw ApiException('Session expired. Please login again.');
      }

      return response;
    } catch (e) {
      LoggerUtil.e('Error in POST request', e, StackTrace.current);
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: $e');
    }
  }
}

// Class untuk mengelola WebSocket dan komunikasi dengan bagian lain aplikasi
class WebSocketManager {
  static final Map<String, Function(String)> _messageHandlers = {};

  // Mendaftarkan handler untuk jenis pesan tertentu
  static void registerMessageHandler(String key, Function(String) handler) {
    _messageHandlers[key] = handler;
  }

  // Menghapus handler
  static void unregisterMessageHandler(String key) {
    _messageHandlers.remove(key);
  }

  // Memproses pesan masuk dan meneruskannya ke handler yang terdaftar
  static void processIncomingMessage(String message) {
    LoggerUtil.d(
        'WebSocketManager: Processing message: ${message.length} bytes');
    try {
      final data = jsonDecode(message);
      final String type = data['type'] ?? 'unknown';

      if (_messageHandlers.containsKey(type)) {
        _messageHandlers[type]!(message);
      } else {
        LoggerUtil.w(
            'WebSocketManager: No handler registered for message type: $type');
      }
    } catch (e) {
      LoggerUtil.e(
          'WebSocketManager: Error processing message', e, StackTrace.current);
    }
  }
}

// Class untuk exception API
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  String getUserFriendlyMessage() {
    return message;
  }

  @override
  String toString() {
    return 'ApiException: $message';
  }
}
