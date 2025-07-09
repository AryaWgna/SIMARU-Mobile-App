import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_config.dart';
import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import '../../views/dashboard/dashboard.dart'; // Import for DashboardScreen
import '../../auth/login.dart'; // Import for LoginScreen
import '../../utils/logger_util.dart'; // Import LoggerUtil

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
    // Langsung kembalikan pesan asli dari server
    return message;
  }
}

class ApiService {
  // Use the base URL from ApiConfig to ensure consistency
  static String get baseUrl => ApiConfig.baseUrl;

  // Membuat instance untuk flutter_secure_storage
  static const _secureStorage = FlutterSecureStorage();

  // Variabel untuk menyimpan token sementara jika flutter_secure_storage gagal
  static String? _tempAccessToken;
  static String? _tempRefreshToken;
  static String? _tempemployee_number;
  static String? _tempPassword;

  // Callback untuk navigasi ke halaman login
  static Function(BuildContext)? navigateToLogin;

  // Global navigator key untuk akses Navigator tanpa context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Helper method untuk redirect ke login dengan berbagai cara
  static void _redirectToLogin(BuildContext? context) {
    LoggerUtil.i('Redirecting to login screen...');

    // Cara 1: Gunakan navigateToLogin callback jika tersedia dan context ada
    if (navigateToLogin != null && context != null) {
      LoggerUtil.i('Using navigateToLogin callback');
      navigateToLogin!(context);
      return;
    }

    // Cara 2: Gunakan navigatorKey jika tersedia
    if (navigatorKey.currentState != null) {
      LoggerUtil.i('Using navigatorKey to navigate');
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    // Cara 3: Jika context tersedia tapi callback tidak
    if (context != null) {
      LoggerUtil.i('Using provided context to navigate');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (c) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    LoggerUtil.w(
        'WARNING: Could not navigate to login screen - no valid navigation method available');
  }

  // Metode untuk memeriksa validitas sesi secara berkala
  static Future<bool> checkSessionValidity() async {
    try {
      LoggerUtil.d('Checking session validity...');

      // Cek apakah token ada
      final hasToken = await isLoggedIn();
      if (!hasToken) {
        LoggerUtil.i('No active session found');
        return false;
      }

      // Check if token is expired based on JWT expiration time
      final isExpired = await isTokenExpired();
      if (isExpired) {
        LoggerUtil.i(
            'Token is expired based on JWT expiration time, attempting refresh');
      } else {
        LoggerUtil.i('Token is not expired based on JWT expiration time');
        // If token is not expired, we can consider the session valid
        // But we'll still try a refresh to extend the session
      }

      // Coba refresh token untuk memastikan masih valid
      final refreshSuccess = await refreshToken();
      if (!refreshSuccess) {
        LoggerUtil.w('Token refresh failed, session is invalid');
        // Bersihkan data penyimpanan
        await _clearStoredData();
        // Redirect ke login jika navigatorKey tersedia
        if (navigatorKey.currentState != null) {
          _redirectToLogin(null);
        }
        return false;
      }

      LoggerUtil.i('Session is valid');
      return true;
    } catch (e) {
      LoggerUtil.e('Error checking session validity', e, StackTrace.current);
      return false;
    }
  }

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
      // Jika tidak ada token, langsung arahkan ke login
      _redirectToLogin(context);

      throw ApiException(
        message: 'Tidak ada sesi login yang aktif',
        code: 'NOT_LOGGED_IN',
        statusCode: 401,
      );
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

    LoggerUtil.d('Making $method request to: $uri');
    LoggerUtil.d('Headers: $headers');
    if (body != null) {
      LoggerUtil.d('Body: $body');
    }

    try {
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

      LoggerUtil.d('Response status code: ${response.statusCode}');
      LoggerUtil.d('Response body: ${response.body}');

      // Handle 401 Unauthorized error
      if (response.statusCode == 401) {
        // Try to parse the response to get the error message
        String errorMessage =
            'Sesi Anda telah berakhir. Silakan login kembali.';
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['errors'] != null) {
            errorMessage = responseData['errors'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        } catch (e) {
          LoggerUtil.e('Failed to parse error response', e, StackTrace.current);
        }

        if (!retried) {
          LoggerUtil.w(
              'Received 401 Unauthorized, attempting to refresh token...');
          final refreshed = await refreshToken();

          if (refreshed) {
            LoggerUtil.i('Token refreshed successfully, retrying request...');
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
            LoggerUtil.w('Token refresh failed, performing automatic logout');
            // If refresh token fails, perform automatic logout
            await _clearStoredData();

            // Redirect to login screen regardless of context
            _redirectToLogin(context);

            throw ApiException(
              message: errorMessage,
              code: 'SESSION_EXPIRED',
              statusCode: 401,
            );
          }
        } else {
          LoggerUtil.w(
              'Still receiving 401 after token refresh, performing automatic logout');

          // If still 401 after token refresh, perform automatic logout
          await _clearStoredData();

          // Redirect to login screen regardless of context
          _redirectToLogin(context);

          throw ApiException(
            message: errorMessage,
            code: 'SESSION_EXPIRED',
            statusCode: 401,
          );
        }
      }

      return response;
    } catch (e) {
      if (e is ApiException) {
        // If it's a session expired error, ensure we redirect to login
        if (e.code == 'SESSION_EXPIRED' || e.statusCode == 401) {
          _redirectToLogin(context);
        }
        rethrow;
      }

      if (e is SocketException) {
        throw ApiException(
          message:
              'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          code: 'CONNECTION_ERROR',
          details: e.toString(),
        );
      }

      if (e is TimeoutException) {
        throw ApiException(
          message: 'Koneksi timeout. Coba lagi nanti.',
          code: 'TIMEOUT',
          details: e.toString(),
        );
      }

      throw ApiException(
        message: 'Terjadi kesalahan: ${e.toString()}',
        code: 'REQUEST_ERROR',
        details: e.toString(),
      );
    }
  }

  static void logNetworkRequest(
      String method, String url, Map<String, dynamic>? body) {
    LoggerUtil.i('-------- NETWORK REQUEST --------');
    LoggerUtil.i('Method: $method');
    LoggerUtil.i('URL: $url');
    if (body != null) {
      LoggerUtil.i('Body: ${jsonEncode(body)}');
    }
    LoggerUtil.i('-------------------------------');
  }

  static void logNetworkResponse(int statusCode, String body, String url) {
    LoggerUtil.i('-------- NETWORK RESPONSE --------');
    LoggerUtil.i('URL: $url');
    LoggerUtil.i('Status Code: $statusCode');

    try {
      // Coba format JSON untuk readability
      final jsonData = jsonDecode(body);
      final formattedJson =
          const JsonEncoder.withIndent('  ').convert(jsonData);
      LoggerUtil.i('Response Body:\n$formattedJson');
    } catch (e) {
      // Jika gagal format, tampilkan sebagai string biasa
      LoggerUtil.i('Response Body: $body');
    }

    LoggerUtil.i('--------------------------------');
  }

  static Future<void> login(String employeeNumber, String password) async {
    if (employeeNumber.isEmpty || password.isEmpty) {
      throw ApiException(
          message: 'employee_number dan password tidak boleh kosong',
          code: 'VALIDATION_ERROR');
    }

    try {
      final url = ApiConfig.loginUrl;
      LoggerUtil.i('Attempting login to: $url');

      final requestBody = {
        'employee_number': employeeNumber,
        'password': password,
      };

      logNetworkRequest('POST', url, requestBody);

      LoggerUtil.d('Sending login request...');
      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          LoggerUtil.e('Login request timed out after 10 seconds');
          throw ApiException(
              message: 'Koneksi timeout, silakan coba lagi',
              code: 'TIMEOUT',
              details: 'Login request timeout');
        },
      );

      LoggerUtil.i('Login response received. Status: ${response.statusCode}');
      logNetworkResponse(response.statusCode, response.body, url);

      // Parse response according to auth.md documentation
      final jsonResponse = jsonDecode(response.body);

      // Check if login was successful based on the 'success' field
      if (jsonResponse['success'] != true) {
        String errorMessage = 'Login gagal';

        // Try to extract error message from various possible locations
        if (jsonResponse.containsKey('errors')) {
          var errors = jsonResponse['errors'];
          if (errors is String) {
            errorMessage = errors;
          } else if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.first.toString();
          } else if (errors is Map && errors.isNotEmpty) {
            errorMessage = errors.values.first.toString();
          }
        } else if (jsonResponse.containsKey('message')) {
          errorMessage = jsonResponse['message'].toString();
        }

        LoggerUtil.w('Extracted error message: $errorMessage');

        throw ApiException(
          message: errorMessage,
          code: jsonResponse['code'] ?? 'LOGIN_FAILED',
          statusCode: response.statusCode,
        );
      }

      // Process successful login data
      if (jsonResponse['data'] == null) {
        throw ApiException(
          message: 'Data tidak ditemukan dalam respon',
          code: 'INVALID_RESPONSE',
          statusCode: response.statusCode,
        );
      }

      final accessToken = jsonResponse['data']['accessToken'];
      final refreshToken = jsonResponse['data']['refreshToken'];

      if (accessToken == null || refreshToken == null) {
        throw ApiException(
          message: 'Token tidak ditemukan dalam respon',
          code: 'MISSING_TOKEN',
          statusCode: response.statusCode,
        );
      }

      LoggerUtil.i('Tokens found, storing credentials...');
      try {
        await _secureStorage.write(key: 'accessToken', value: accessToken);
        await _secureStorage.write(key: 'refreshToken', value: refreshToken);
        await _secureStorage.write(
            key: 'employee_number', value: employeeNumber);
        // Store password only if needed for automatic re-login
        await _secureStorage.write(key: 'password', value: password);
        LoggerUtil.i('Credentials stored successfully');

        // Set up the navigation callback for session expiry
        navigateToLogin = (BuildContext ctx) {
          LoggerUtil.i('Session expired, redirecting to login screen');
          Navigator.of(ctx).pushAndRemoveUntil(
            MaterialPageRoute(builder: (c) => const LoginScreen()),
            (route) => false,
          );
        };

        LoggerUtil.i('Login completed successfully');
      } catch (e) {
        LoggerUtil.e('Failed to store credentials', e, StackTrace.current);
        // Backup to memory variables if secure storage fails
        _tempAccessToken = accessToken;
        _tempRefreshToken = refreshToken;
        _tempemployee_number = employeeNumber;
        _tempPassword = password;
        LoggerUtil.i('Credentials stored in temporary variables');
        rethrow;
      }
      return;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw _processError(e, endpoint: '/auth/login');
    }
  }

  static Future<bool> refreshToken() async {
    String? refreshToken;

    LoggerUtil.d('Attempting to refresh token...');

    try {
      refreshToken =
          await _secureStorage.read(key: 'refreshToken') ?? _tempRefreshToken;
      LoggerUtil.d('Retrieved refresh token from secure storage');
    } catch (e) {
      LoggerUtil.e('Failed to get refresh token from secure storage', e,
          StackTrace.current);
      refreshToken = _tempRefreshToken;
      LoggerUtil.d('Using temporary refresh token');
    }

    if (refreshToken == null) {
      LoggerUtil.w('No refresh token found for token refresh');
      return false;
    }

    try {
      LoggerUtil.d('Sending refresh token request');

      // Using the endpoint from API documentation (auth.md)
      final response = await http
          .post(
        Uri.parse(ApiConfig.refreshTokenUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      )
          .timeout(
        const Duration(
            seconds:
                10), // Increased timeout to 10 seconds for better reliability
        onTimeout: () {
          LoggerUtil.e('Refresh token request timed out');
          throw TimeoutException('Refresh token request timed out');
        },
      );

      LoggerUtil.d(
          'Refresh token response status code: ${response.statusCode}');
      LoggerUtil.d('Refresh token response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Check for success based on the API documentation
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final newAccessToken = jsonResponse['data']['accessToken'];
          // The refresh token might be updated too, or we keep using the old one
          final newRefreshToken =
              jsonResponse['data']['refreshToken'] ?? refreshToken;

          LoggerUtil.i('======================================');
          LoggerUtil.i('TOKEN REFRESH SUCCESS');
          LoggerUtil.d('New Access Token: $newAccessToken');
          LoggerUtil.i('======================================');

          try {
            // Update tokens in secure storage
            await _secureStorage.write(
                key: 'accessToken', value: newAccessToken);
            await _secureStorage.write(
                key: 'refreshToken', value: newRefreshToken);
            LoggerUtil.i('New tokens saved to Secure Storage');
          } catch (e) {
            // Update memory variables if secure storage fails
            LoggerUtil.w('Warning: Failed to update token in Secure Storage', e,
                StackTrace.current);
            _tempAccessToken = newAccessToken;
            _tempRefreshToken = newRefreshToken;
            LoggerUtil.i('New tokens saved to temporary variables');
          }
          return true;
        } else {
          // Handle specific error messages from API
          String errorMessage =
              jsonResponse['message'] ?? 'Token refresh failed';
          if (jsonResponse['errors'] != null) {
            if (jsonResponse['errors'] is String) {
              errorMessage = jsonResponse['errors'];
            } else if (jsonResponse['errors'] is List &&
                jsonResponse['errors'].isNotEmpty) {
              errorMessage = jsonResponse['errors'][0];
            }
          }
          LoggerUtil.w('Token refresh failed: $errorMessage');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        LoggerUtil.w('Token refresh failed: Refresh token invalid or expired');
        // Clear stored tokens on 401/403 as they are no longer valid
        await _clearStoredData();
      } else {
        LoggerUtil.w(
            'Token refresh failed with status code: ${response.statusCode}');

        // For other status codes, try to parse the error message
        try {
          final jsonResponse = jsonDecode(response.body);
          final errorMessage = jsonResponse['message'] ??
              jsonResponse['errors'] ??
              'Unknown error';
          LoggerUtil.w('Error message: $errorMessage');
        } catch (e) {
          LoggerUtil.e('Failed to parse error response', e, StackTrace.current);
        }
      }
      return false;
    } catch (e) {
      LoggerUtil.e('Error refreshing token', e, StackTrace.current);
      if (e is SocketException) {
        LoggerUtil.w(
            'Network error during token refresh. Will try again later.');
        // Don't clear tokens on network errors
        return false;
      } else {
        // For other errors, clear stored data as a precaution
        await _clearStoredData();
        return false;
      }
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      // Check for access token
      final accessToken = await _secureStorage.read(key: 'accessToken');
      final refreshToken = await _secureStorage.read(key: 'refreshToken');

      // Check if we have both tokens
      final hasAccessToken = accessToken != null && accessToken.isNotEmpty;
      final hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;

      LoggerUtil.d(
          'Token check: Access token exists: $hasAccessToken, Refresh token exists: $hasRefreshToken');

      // We consider the user logged in if at least the refresh token exists
      // The access token can be refreshed if needed
      return hasRefreshToken;
    } catch (e) {
      // Jika gagal mengakses Secure Storage, periksa variabel sementara
      final hasAccessToken =
          _tempAccessToken != null && _tempAccessToken!.isNotEmpty;
      final hasRefreshToken =
          _tempRefreshToken != null && _tempRefreshToken!.isNotEmpty;

      LoggerUtil.d(
          'Token check (from memory): Access token exists: $hasAccessToken, Refresh token exists: $hasRefreshToken');

      return hasRefreshToken;
    }
  }

  // Method to get the auth token for external use
  static Future<String?> getAuthToken() async {
    try {
      // First try to get it from secure storage
      final accessToken = await _secureStorage.read(key: 'accessToken');

      // If not found in secure storage, return the temporary one
      if (accessToken == null || accessToken.isEmpty) {
        return _tempAccessToken;
      }

      return accessToken;
    } catch (e) {
      LoggerUtil.e('Error retrieving auth token', e, StackTrace.current);
      // Return the temporary token as fallback
      return _tempAccessToken;
    }
  }

  static Future<Map<String, dynamic>> logout(BuildContext context) async {
    try {
      // Get access token and refresh token
      final accessToken = await _getAccessToken();
      final refreshToken =
          await _secureStorage.read(key: 'refreshToken') ?? _tempRefreshToken;

      if (accessToken == null) {
        throw Exception('No access token available for logout');
      }

      LoggerUtil.i('Attempting to logout with token');

      // Call logout API
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      LoggerUtil.d('Logout response status: ${response.statusCode}');
      LoggerUtil.d('Logout response body: ${response.body}');

      // Clear local storage regardless of API response
      await _clearStoredData();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        LoggerUtil.i('LOGOUT SUCCESS: ${response.body}');
        return data;
      } else {
        LoggerUtil.w(
            'Logout API failed with status code: ${response.statusCode}');
        // Even if API fails, we still want to clear local data
        return {'success': true, 'message': 'Logged out locally'};
      }
    } catch (e) {
      LoggerUtil.e('Logout error', e, StackTrace.current);
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
      LoggerUtil.e('Error decoding JWT', e, StackTrace.current);
      return null;
    }
  }

  // Helper method to clear all stored data
  static Future<void> _clearStoredData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      LoggerUtil.e('Error clearing Secure Storage', e, StackTrace.current);
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
      LoggerUtil.e('Error getting access token from Secure Storage', e,
          StackTrace.current);
      return _tempAccessToken;
    }
  }

  // Helper method to get employee number
  static Future<String?> getEmployeeNumber() async {
    try {
      // Try to get the employee number from secure storage
      final employeeNumber =
          await _secureStorage.read(key: 'employee_number') ??
              _tempemployee_number;
      return employeeNumber;
    } catch (e) {
      LoggerUtil.e('Error getting employee number from Secure Storage', e,
          StackTrace.current);
      return _tempemployee_number;
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
      final response = await get('/users/profile', context: context).timeout(
        const Duration(seconds: 5), // Menambahkan timeout untuk getProfile
        onTimeout: () {
          LoggerUtil.e('Profile request timed out after 5 seconds');
          throw TimeoutException('Profile request timed out');
        },
      );

      LoggerUtil.d('Profile response status: ${response.statusCode}');
      LoggerUtil.d('Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Simpan data profil ke secure storage
          try {
            await _secureStorage.write(
              key: 'user_id',
              value: responseData['data']['user_id'].toString(),
            );
            await _secureStorage.write(
              key: 'employee_number',
              value: responseData['data']['employee_number'],
            );
            await _secureStorage.write(
              key: 'roles',
              value: json.encode(responseData['data']['roles']),
            );
            LoggerUtil.i('Profile data saved to secure storage');
          } catch (e) {
            LoggerUtil.e('Error saving profile data', e, StackTrace.current);
          }
          return responseData['data'];
        } else {
          throw ApiException(
            message: responseData['message'] ?? 'Gagal mengambil profil',
            code: 'PROFILE_ERROR',
          );
        }
      } else {
        throw ApiException(
          message: 'Gagal mengambil profil: ${response.statusCode}',
          code: 'HTTP_ERROR',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LoggerUtil.e('Error getting profile', e, StackTrace.current);
      rethrow;
    }
  }

  // Metode untuk mendapatkan user berdasarkan ID
  static Future<Map<String, dynamic>> getUserById(
      String userId, BuildContext context) async {
    try {
      final response = await get('/users/$userId', context: context);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception(
              responseData['message'] ?? 'Failed to load user data');
        }
      } else {
        throw Exception('Gagal mengambil data user: ${response.statusCode}');
      }
    } catch (e) {
      LoggerUtil.e('Error getting user by ID', e, StackTrace.current);
      throw Exception('Gagal melakukan koneksi ke server');
    }
  }

  static ApiException _processError(dynamic error,
      {int? statusCode, String? endpoint}) {
    LoggerUtil.e(
        'Error processing error: $error, statusCode: $statusCode, endpoint: $endpoint',
        error,
        StackTrace.current);

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
      LoggerUtil.i("Attempting to navigate to dashboard (ApiService method)");

      // Coba dengan named route
      try {
        LoggerUtil.d("Using named route");
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
        return;
      } catch (e) {
        LoggerUtil.w("Named route failed", e, StackTrace.current);
      }

      // Jika gagal, coba dengan import langsung
      try {
        LoggerUtil.d("Using direct import");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
          (route) => false,
        );
        return;
      } catch (e) {
        LoggerUtil.w("Direct import failed", e, StackTrace.current);
      }

      // Jika masih gagal, coba cara lain
      LoggerUtil.w("All navigation methods failed");
    } catch (e, s) {
      LoggerUtil.e("Navigation error in ApiService", e, s);
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: 'accessToken') ?? _tempAccessToken;
    } catch (e) {
      LoggerUtil.e('Error getting access token from Secure Storage', e,
          StackTrace.current);
      return _tempAccessToken;
    }
  }

  // Check if the token is expired based on JWT expiration
  static Future<bool> isTokenExpired() async {
    try {
      final accessToken = await _getAccessToken();

      if (accessToken == null) {
        LoggerUtil.w('No access token found to check expiration');
        return true; // Consider expired if no token
      }

      // Decode token to check expiration
      final decodedToken = _decodeJwt(accessToken);
      if (decodedToken == null) {
        LoggerUtil.w('Failed to decode access token');
        return true; // Consider expired if can't decode
      }

      // Check if token has expiration claim
      if (!decodedToken.containsKey('exp')) {
        LoggerUtil.w('Token does not contain expiration claim');
        return false; // Can't determine expiration, assume valid
      }

      // Get expiration timestamp and current time
      final expTimestamp = decodedToken['exp'] as int;
      final currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Add buffer time (30 seconds) to avoid edge cases
      final isExpired = currentTimestamp + 30 >= expTimestamp;

      LoggerUtil.d(
          'Token expiration check: ${isExpired ? "EXPIRED" : "VALID"} (Expires at: ${DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000)})');

      return isExpired;
    } catch (e) {
      LoggerUtil.e('Error checking token expiration', e, StackTrace.current);
      return true; // Consider expired on error to be safe
    }
  }
}
