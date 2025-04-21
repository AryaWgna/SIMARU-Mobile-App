import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import '../views/dashboard/dashboard.dart'; // Import for DashboardScreen

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final String? details;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    return 'ApiException: $message${code != null ? ' (Code: $code)' : ''}';
  }

  // Helper untuk membuat pesan yang user-friendly
  String getUserFriendlyMessage() {
    if (statusCode == 401) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    } else if (statusCode == 403) {
      return 'employee_number atau password salah. Silakan periksa kembali.';
    } else if (statusCode == 404) {
      return 'Layanan tidak ditemukan. Silakan hubungi administrator.';
    } else if (statusCode == 500) {
      return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
    } else if (message.contains('SocketException') ||
        message.contains('Connection refused')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    } else if (message.contains('timeout')) {
      return 'Koneksi timeout. Server mungkin sedang sibuk, silakan coba lagi.';
    }

    return message;
  }
}

class ApiService {
  // Base URL untuk perangkat fisik
  static String baseUrl = 'http://10.0.2.2:8026';
  // Alternatif: 'http://localhost:3000' untuk iOS simulator
  // Gunakan URL publik Anda untuk perangkat fisik, misalnya: 'https://api.example.com'

  // Membuat instance untuk flutter_secure_storage
  static const _secureStorage = FlutterSecureStorage();

  // Variabel untuk menyimpan token sementara jika flutter_secure_storage gagal
  static String? _tempAccessToken;
  static String? _tempRefreshToken;
  static String? _tempemployee_number;
  static String? _tempPassword;

  // Callback untuk navigasi ke halaman login
  static Function(BuildContext)? navigateToLogin;

  // Metode untuk melakukan HTTP request dengan auto refresh token
  static Future<http.Response> _requestWithAuth({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
    bool retried = false,
    BuildContext? context,
  }) async {
    final accessToken = await _getAccessToken();

    if (accessToken == null) {
      throw Exception('Not logged in');
    }

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    http.Response response;
    final uri = Uri.parse('$baseUrl$endpoint');

    print('Making $method request to: $uri');
    print('Headers: $headers');
    if (body != null) {
      print('Body: $body');
    }

    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(uri,
          headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'PUT') {
      response = await http.put(uri,
          headers: headers, body: body != null ? jsonEncode(body) : null);
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers);
    } else {
      throw Exception('Unsupported HTTP method: $method');
    }

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    // Handle 401 Unauthorized error
    if (response.statusCode == 401) {
      if (!retried) {
        print('Received 401 Unauthorized, attempting to refresh token...');
        final refreshed = await refreshToken();

        if (refreshed) {
          print('Token refreshed successfully, retrying request...');
          // Retry the request with the new token
          return _requestWithAuth(
            method: method,
            endpoint: endpoint,
            body: body,
            additionalHeaders: additionalHeaders,
            retried: true, // Mark as retried to prevent infinite loops
            context: context,
          );
        } else {
          print('Token refresh failed, performing automatic logout');
          // Jika refresh token gagal, lakukan logout otomatis
          await logout(context!);

          // Navigasi ke halaman login jika context tersedia
          if (navigateToLogin != null) {
            print('Navigating to login screen');
            navigateToLogin!(context);
          } else {
            print(
                'Cannot navigate to login: context or navigateToLogin is null');
          }

          throw Exception('Session expired. Please login again.');
        }
      } else {
        print(
            'Still receiving 401 after token refresh, performing automatic logout');
        // Jika masih 401 setelah refresh token, lakukan logout otomatis
        await logout(context!);

        // Navigasi ke halaman login jika context tersedia
        if (navigateToLogin != null) {
          print('Navigating to login screen');
          navigateToLogin!(context);
        } else {
          print('Cannot navigate to login: context or navigateToLogin is null');
        }

        throw Exception('Session expired. Please login again.');
      }
    }

    return response;
  }

  static void logNetworkRequest(
      String method, String url, Map<String, dynamic>? body) {
    developer.log(
      '-------- NETWORK REQUEST --------',
      name: 'API_REQUEST',
    );
    developer.log('Method: $method', name: 'API_REQUEST');
    developer.log('URL: $url', name: 'API_REQUEST');
    if (body != null) {
      developer.log('Body: ${jsonEncode(body)}', name: 'API_REQUEST');
    }
    developer.log('-------------------------------', name: 'API_REQUEST');
  }

  static void logNetworkResponse(int statusCode, String body, String url) {
    developer.log(
      '-------- NETWORK RESPONSE --------',
      name: 'API_RESPONSE',
    );
    developer.log('URL: $url', name: 'API_RESPONSE');
    developer.log('Status Code: $statusCode', name: 'API_RESPONSE');

    try {
      // Coba format JSON untuk readability
      final jsonData = jsonDecode(body);
      final formattedJson =
          const JsonEncoder.withIndent('  ').convert(jsonData);
      developer.log('Response Body:\n$formattedJson', name: 'API_RESPONSE');
    } catch (e) {
      // Jika gagal format, tampilkan sebagai string biasa
      developer.log('Response Body: $body', name: 'API_RESPONSE');
    }

    developer.log('--------------------------------', name: 'API_RESPONSE');
  }

  static Future<void> login(String employee_number, String password) async {
    if (employee_number.isEmpty || password.isEmpty) {
      throw ApiException(
          message: 'employee_number dan password tidak boleh kosong',
          code: 'VALIDATION_ERROR');
    }

    try {
      final url = '$baseUrl/auth/login';
      print('Attempting login to: $url');
      print('employee_number: $employee_number');

      final requestBody = {
        'employee_number': employee_number,
        'password': password,
      };

      print('Sending login request...');
      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Login request timed out after 15 seconds');
          throw ApiException(
              message: 'Koneksi timeout',
              code: 'TIMEOUT',
              details: 'Login request timeout');
        },
      );

      print('Login response received. Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          print('Response decoded: $jsonResponse');

          if (jsonResponse['status'] == true) {
            print('Login success flag found in response');
            // Cek keberadaan data
            if (jsonResponse['data'] == null) {
              print('Data not found in response');
              throw ApiException(
                  message: 'Data tidak ditemukan dalam respon',
                  code: 'INVALID_RESPONSE',
                  statusCode: 200);
            }

            final accessToken = jsonResponse['data']['accessToken'];
            final refreshToken = jsonResponse['data']['refreshToken'];

            if (accessToken == null || refreshToken == null) {
              print('Tokens not found in response data');
              throw ApiException(
                  message: 'Token tidak ditemukan dalam respon',
                  code: 'MISSING_TOKEN',
                  statusCode: 200);
            }

            print('Tokens found, storing credentials...');
            // Simpan token
            try {
              await _secureStorage.write(
                  key: 'accessToken', value: accessToken);
              await _secureStorage.write(
                  key: 'refreshToken', value: refreshToken);
              await _secureStorage.write(
                  key: 'employee_number', value: employee_number);
              await _secureStorage.write(key: 'password', value: password);
              print('Credentials stored successfully');
            } catch (e) {
              print('Failed to store credentials in secure storage: $e');
              // Backup ke variabel memori jika gagal
              _tempAccessToken = accessToken;
              _tempRefreshToken = refreshToken;
              _tempemployee_number = employee_number;
              _tempPassword = password;
              print('Credentials stored in temporary variables');
            }
            print('Login completed successfully');
            return;
          } else {
            // API mengembalikan status: false
            final message = jsonResponse['message'] ?? 'Login gagal';
            throw ApiException(
                message: message,
                code: 'LOGIN_FAILED',
                statusCode: response.statusCode);
          }
        } catch (e) {
          if (e is ApiException) rethrow;

          throw ApiException(
              message: 'Format respons tidak valid',
              code: 'PARSE_ERROR',
              statusCode: response.statusCode);
        }
      } else if (response.statusCode == 400) {
        try {
          final jsonResponse = jsonDecode(response.body);
          throw ApiException(
              message:
                  jsonResponse['message'] ?? 'Data yang dimasukkan tidak valid',
              code: 'VALIDATION_ERROR',
              statusCode: 400);
        } catch (e) {
          if (e is ApiException) rethrow;
          throw ApiException(
              message: 'Data yang dimasukkan tidak valid',
              code: 'VALIDATION_ERROR',
              statusCode: 400);
        }
      } else if (response.statusCode == 401) {
        throw ApiException(
            message: 'Tidak diizinkan mengakses sistem',
            code: 'UNAUTHORIZED',
            statusCode: 401);
      } else if (response.statusCode == 403) {
        try {
          final jsonResponse = jsonDecode(response.body);
          throw ApiException(
              message: jsonResponse['message'] ??
                  'employee_number atau password salah',
              code: 'FORBIDDEN',
              statusCode: 403);
        } catch (e) {
          if (e is ApiException) rethrow;
          throw ApiException(
              message: 'employee_number atau password salah',
              code: 'FORBIDDEN',
              statusCode: 403);
        }
      } else {
        throw ApiException(
            message: 'Terjadi kesalahan saat login',
            code: 'UNKNOWN_ERROR',
            statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is ApiException) rethrow;

      throw _processError(e, endpoint: '/auth/login');
    }
  }

  static Future<bool> refreshToken() async {
    String? employee_number;
    String? password;

    print('Attempting to refresh token...');

    try {
      employee_number = await _secureStorage.read(key: 'employee_number');
      password = await _secureStorage.read(key: 'password');
      print('Retrieved credentials from Secure Storage');
    } catch (e) {
      // Jika gagal mengakses Secure Storage, gunakan variabel sementara
      employee_number = _tempemployee_number;
      password = _tempPassword;
      print('Retrieved credentials from temporary variables');
    }

    if (employee_number == null || password == null) {
      print('No credentials found for token refresh');
      return false;
    }

    try {
      print('Sending refresh token request for user: $employee_number');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'employee_number': employee_number,
          'password': password,
        }),
      );

      print('Refresh token response status code: ${response.statusCode}');
      print('Refresh token response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == true) {
          final newAccessToken = jsonResponse['data']['accessToken'];

          print('======================================');
          print('TOKEN REFRESH SUCCESS');
          print('New Access Token: $newAccessToken');
          print('======================================');

          try {
            // Coba update token di secure storage
            await _secureStorage.write(
                key: 'accessToken', value: newAccessToken);
            print('New token saved to Secure Storage');
          } catch (e) {
            // Jika gagal, update variabel sementara
            print('Warning: Failed to update token in Secure Storage: $e');
            _tempAccessToken = newAccessToken;
            print('New token saved to temporary variable');
          }
          return true;
        } else {
          print('Token refresh failed: ${jsonResponse['message']}');
        }
      } else {
        print('Token refresh failed with status code: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final accessToken = await _secureStorage.read(key: 'accessToken');
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      // Jika gagal mengakses Secure Storage, periksa variabel sementara
      return _tempAccessToken != null && _tempAccessToken!.isNotEmpty;
    }
  }

  static Future<Map<String, dynamic>> logout(BuildContext context) async {
    try {
      // Get access token
      final accessToken = await _getAccessToken();

      if (accessToken == null) {
        throw Exception('No access token available for logout');
      }

      // Decode token to get user information
      final decodedToken = _decodeJwt(accessToken);
      print('Decoded token: $decodedToken');

      // Extract user ID from token if needed for the logout API
      final userId = decodedToken?['sub'] ?? decodedToken?['userId'];

      print('Attempting to logout user with ID: $userId');

      // Call logout API
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'userId': userId,
          // Add any other required fields for your logout API
        }),
      );

      print('Logout response status: ${response.statusCode}');

      // Clear local storage regardless of API response
      await _clearStoredData();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        print('LOGOUT SUCCESS: ${response.body}');
        return data;
      } else {
        print('Logout API failed with status code: ${response.statusCode}');
        // Even if API fails, we still want to clear local data
        return {'success': true, 'message': 'Logged out locally'};
      }
    } catch (e) {
      print('Logout error: $e');
      // Even on error, clear local data
      await _clearStoredData();
      return {
        'success': true,
        'message': 'Logged out locally due to error: $e'
      };
    }
  }

  // Helper method to decode JWT token
  static Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Get payload part (second part of JWT)
      final payload = parts[1];
      // Apply base64 padding if needed
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      String padded = normalized.padRight(
          normalized.length + (4 - normalized.length % 4) % 4, '=');

      // Decode base64
      final decoded = base64Url.decode(padded);
      final payloadMap = jsonDecode(utf8.decode(decoded));

      return payloadMap;
    } catch (e) {
      print('Error decoding JWT: $e');
      return null;
    }
  }

  // Helper method to clear all stored data
  static Future<void> _clearStoredData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('Error clearing Secure Storage: $e');
    }

    // Clear memory variables as well
    _tempAccessToken = null;
    _tempRefreshToken = null;
    _tempemployee_number = null;
    _tempPassword = null;
  }

  static Future<String?> _getAccessToken() async {
    try {
      return await _secureStorage.read(key: 'accessToken') ?? _tempAccessToken;
    } catch (e) {
      print('Error getting access token from Secure Storage: $e');
      return _tempAccessToken;
    }
  }

  // Metode-metode HTTP yang menggunakan _requestWithAuth

  static Future<http.Response> get(String endpoint,
      {Map<String, String>? headers, BuildContext? context}) async {
    return _requestWithAuth(
      method: 'GET',
      endpoint: endpoint,
      additionalHeaders: headers,
      context: context,
    );
  }

  static Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      BuildContext? context}) async {
    return _requestWithAuth(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      additionalHeaders: headers,
      context: context,
    );
  }

  static Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      BuildContext? context}) async {
    return _requestWithAuth(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      additionalHeaders: headers,
      context: context,
    );
  }

  static Future<http.Response> delete(String endpoint,
      {Map<String, String>? headers, BuildContext? context}) async {
    return _requestWithAuth(
      method: 'DELETE',
      endpoint: endpoint,
      additionalHeaders: headers,
      context: context,
    );
  }

  // Metode untuk mendapatkan profil pengguna
  static Future<Map<String, dynamic>> getProfile(BuildContext context) async {
    try {
      final response = await get('/users/profile', context: context);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          return responseData['data'];
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load profile');
        }
      } else {
        throw Exception('Gagal mengambil profil: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      throw Exception('Gagal melakukan koneksi ke server');
    }
  }

  // Metode untuk mendapatkan user berdasarkan ID
  static Future<Map<String, dynamic>> getUserById(
      String userId, BuildContext context) async {
    try {
      final response = await get('/users/$userId', context: context);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          return responseData['data'];
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to load user data');
        }
      } else {
        throw Exception('Gagal mengambil data user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user by ID: $e');
      throw Exception('Gagal melakukan koneksi ke server');
    }
  }

  static ApiException _processError(dynamic error,
      {int? statusCode, String? endpoint}) {
    print(
        'Error processing error: $error, statusCode: $statusCode, endpoint: $endpoint');

    if (error is ApiException) {
      return error;
    }

    if (error is http.ClientException) {
      return ApiException(
        message: 'Kesalahan koneksi: ${error.message}',
        statusCode: statusCode,
        details: 'Endpoint: $endpoint',
      );
    }

    if (error is FormatException) {
      return ApiException(
        message: 'Format respons tidak valid',
        code: 'FORMAT_ERROR',
        statusCode: statusCode,
        details: error.toString(),
      );
    }

    if (error is SocketException) {
      return ApiException(
        message: 'Tidak dapat terhubung ke server',
        code: 'NETWORK_ERROR',
        details: error.toString(),
      );
    }

    if (error is TimeoutException) {
      return ApiException(
        message: 'Koneksi timeout',
        code: 'TIMEOUT',
        details: 'Request timeout at $endpoint',
      );
    }

    return ApiException(
      message: error.toString(),
      statusCode: statusCode,
      details: 'Unhandled exception',
    );
  }

  // Helper method untuk navigasi ke dashboard
  static void navigateToDashboard(BuildContext context) {
    try {
      print("Attempting to navigate to dashboard (ApiService method)");

      // Coba dengan named route
      try {
        print("Using named route");
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
        return;
      } catch (e) {
        print("Named route failed: $e");
      }

      // Jika gagal, coba dengan import langsung
      try {
        print("Using direct import");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
          (route) => false,
        );
        return;
      } catch (e) {
        print("Direct import failed: $e");
      }

      // Jika masih gagal, coba cara lain
      print("All navigation methods failed");
    } catch (e, s) {
      print("Navigation error in ApiService: $e");
      print("Stack trace: $s");
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: 'accessToken') ?? _tempAccessToken;
    } catch (e) {
      print('Error getting access token from Secure Storage: $e');
      return _tempAccessToken;
    }
  }
}
