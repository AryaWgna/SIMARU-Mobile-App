import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';

class ApiService {
  static const String baseUrl =
      'https://12d9aa80-068d-4c47-a664-b62f5cad5ec5.mock.pstmn.io';

  // Variabel untuk menyimpan token sementara jika SharedPreferences gagal
  static String? _tempAccessToken;
  static String? _tempRefreshToken;
  static String? _tempUserId;
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

  static Future<void> login(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) {
      throw Exception('User ID and password cannot be empty');
    }

    try {
      print('Attempting to login with userId: $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'password': password,
        }),
      );

      print('Login response status code: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          // Simpan token dan credentials
          final accessToken = jsonResponse['data']['accessToken'];
          final refreshToken = jsonResponse['data']['refreshToken'];

          print('======================================');
          print('LOGIN SUCCESS');
          print('Access Token: $accessToken');
          print('Refresh Token: $refreshToken');
          print('======================================');

          try {
            // Coba simpan ke SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', accessToken);
            await prefs.setString('refreshToken', refreshToken);
            await prefs.setString('userId', userId);
            await prefs.setString('password', password);
            print('Tokens successfully saved to SharedPreferences');
          } catch (e) {
            // Jika gagal, simpan ke variabel sementara
            print('Warning: Failed to save to SharedPreferences: $e');
            _tempAccessToken = accessToken;
            _tempRefreshToken = refreshToken;
            _tempUserId = userId;
            _tempPassword = password;
            print('Tokens saved to temporary variables instead');
          }
          return;
        } else {
          print('Login failed: ${jsonResponse['message']}');
          throw Exception(jsonResponse['message'] ?? 'Login failed');
        }
      } else {
        print('Login failed with status code: ${response.statusCode}');
        throw Exception('Failed to login. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during login: $e');
      throw Exception('Error during login: $e');
    }
  }

  static Future<bool> refreshToken() async {
    String? userId;
    String? password;

    print('Attempting to refresh token...');

    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');
      password = prefs.getString('password');
      print('Retrieved credentials from SharedPreferences');
    } catch (e) {
      // Jika gagal mengakses SharedPreferences, gunakan variabel sementara
      userId = _tempUserId;
      password = _tempPassword;
      print('Retrieved credentials from temporary variables');
    }

    if (userId == null || password == null) {
      print('No credentials found for token refresh');
      return false;
    }

    try {
      print('Sending refresh token request for user: $userId');

    final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
      headers: {
        'Content-Type': 'application/json',
      },
        body: jsonEncode({
          'userId': userId,
          'password': password,
        }),
      );

      print('Refresh token response status code: ${response.statusCode}');
      print('Refresh token response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['success'] == true) {
          final newAccessToken = jsonResponse['data']['accessToken'];

          print('======================================');
          print('TOKEN REFRESH SUCCESS');
          print('New Access Token: $newAccessToken');
          print('======================================');

          try {
            // Coba update token di SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', newAccessToken);
            print('New token saved to SharedPreferences');
          } catch (e) {
            // Jika gagal, update variabel sementara
            print('Warning: Failed to update token in SharedPreferences: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      // Jika gagal mengakses SharedPreferences, periksa variabel sementara
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      await prefs.remove('password');
    } catch (e) {
      print('Error clearing SharedPreferences: $e');
    }

    // Clear memory variables as well
    _tempAccessToken = null;
    _tempRefreshToken = null;
    _tempUserId = null;
    _tempPassword = null;
  }

  static Future<String?> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('accessToken') ?? _tempAccessToken;
    } catch (e) {
      print('Error getting access token from SharedPreferences: $e');
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
      final response = await get('/api/profiles', context: context);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'name': responseData['data']['name'],
          'email': responseData['data']['email'],
          'phone': responseData['data']['phone_number'],
          'image': responseData['data']['image_path'],
        };
      } else {
        throw Exception('Gagal mengambil profil: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      throw Exception('Gagal melakukan koneksi ke server');
    }
  }
}
