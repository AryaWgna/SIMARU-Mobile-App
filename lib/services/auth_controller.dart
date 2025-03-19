import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';

class ApiService {
  static String? _tempAccessToken;
  static String? _tempRefreshToken;
  static String? _tempUserId;
  static String? _tempPassword;
  
  // Callback function to navigate to login screen
  static Function(BuildContext)? navigateToLogin;

  static Future<String?> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('accessToken') ?? _tempAccessToken;
    } catch (e) {
      print('Error getting access token from SharedPreferences: $e');
      return _tempAccessToken;
    }
  }

  static Future<String?> _getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refreshToken') ?? _tempRefreshToken;
    } catch (e) {
      print('Error getting refresh token from SharedPreferences: $e');
      return _tempRefreshToken;
    }
  }

  static Future<void> _saveTokens(String accessToken, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
    } catch (e) {
      print('Error saving tokens to SharedPreferences: $e');
      // Fallback to memory storage
      _tempAccessToken = accessToken;
      _tempRefreshToken = refreshToken;
    }
  }

  static Future<void> _saveCredentials(String userId, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('password', password);
    } catch (e) {
      print('Error saving credentials to SharedPreferences: $e');
      // Fallback to memory storage
      _tempUserId = userId;
      _tempPassword = password;
    }
  }

  static Future<Map<String, dynamic>> login(String userId, String password) async {
    if (userId.isEmpty || password.isEmpty) {
      throw Exception('User ID and password cannot be empty');
    }

    try {
      print('Attempting login with userId: $userId');
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('LOGIN SUCCESS: ${response.body}');
        
        if (data['success'] == true) {
          final accessToken = data['data']['accessToken'];
          final refreshToken = data['data']['refreshToken'];
          
          await _saveTokens(accessToken, refreshToken);
          await _saveCredentials(userId, password);
          
          return data;
        } else {
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        throw Exception('Login failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      String? userId;
      String? password;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('userId') ?? _tempUserId;
        password = prefs.getString('password') ?? _tempPassword;
      } catch (e) {
        print('Error getting credentials from SharedPreferences: $e');
        userId = _tempUserId;
        password = _tempPassword;
      }
      
      if (userId == null || password == null) {
        throw Exception('No stored credentials for token refresh');
      }
      
      print('Attempting to refresh token for user: $userId');
      final response = await http.post(
        Uri.parse(ApiConfig.refreshTokenUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'password': password,
        }),
      );

      print('Refresh token response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('REFRESH TOKEN SUCCESS: ${response.body}');
        
        if (data['success'] == true) {
          final accessToken = data['data']['accessToken'];
          
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('accessToken', accessToken);
          } catch (e) {
            print('Error saving new access token to SharedPreferences: $e');
            _tempAccessToken = accessToken;
          }
          
          return data;
        } else {
          throw Exception(data['message'] ?? 'Token refresh failed');
        }
      } else {
        throw Exception('Token refresh failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Token refresh error: $e');
      throw Exception('Token refresh failed: $e');
    }
  }

  static Future<void> logout() async {
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

  static Future<Map<String, dynamic>> getProfile(BuildContext context) async {
    try {
      return await _requestWithAuth(
        context,
        'GET',
        ApiConfig.profileUrl,
      );
    } catch (e) {
      print('Get profile error: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  static Future<Map<String, dynamic>> _requestWithAuth(
    BuildContext context,
    String method,
    String url, {
    Map<String, dynamic>? body,
    bool hasRetried = false,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      
      if (accessToken == null) {
        throw Exception('No access token available');
      }
      
      print('Making $method request to $url');
      
      http.Response response;
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };
      
      switch (method) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      print('Response status code: ${response.statusCode}');
      
      if (response.statusCode == 401 && !hasRetried) {
        // Token might be expired, attempt to refresh
        print('Received 401, attempting to refresh token and retry request');
        try {
          await refreshToken();
          // Retry the request with new token
          return _requestWithAuth(
            context,
            method,
            url,
            body: body,
            hasRetried: true,
          );
        } catch (e) {
          print('Token refresh failed: $e');
          // If refresh fails, logout and redirect to login
          await logout();
          
          if (navigateToLogin != null && context.mounted) {
            navigateToLogin!(context);
          }
          
          throw Exception('Authentication failed after token refresh attempt');
        }
      } else if (response.statusCode == 401 && hasRetried) {
        // Still getting 401 after token refresh, logout
        print('Still receiving 401 after token refresh, logging out');
        await logout();
        
        if (navigateToLogin != null && context.mounted) {
          navigateToLogin!(context);
        }
        
        throw Exception('Authentication failed after token refresh');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
      throw Exception('Request failed: $e');
    }
  }
  
  // Helper methods for different HTTP methods
  
  static Future<Map<String, dynamic>> getWithAuth(
    BuildContext context, 
    String endpoint
  ) async {
    return _requestWithAuth(
      context,
      'GET',
      endpoint.startsWith('http') ? endpoint : ApiConfig.getEndpointUrl(endpoint),
    );
  }
  
  static Future<Map<String, dynamic>> postWithAuth(
    BuildContext context, 
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _requestWithAuth(
      context,
      'POST',
      endpoint.startsWith('http') ? endpoint : ApiConfig.getEndpointUrl(endpoint),
      body: body,
    );
  }
  
  static Future<Map<String, dynamic>> putWithAuth(
    BuildContext context, 
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _requestWithAuth(
      context,
      'PUT',
      endpoint.startsWith('http') ? endpoint : ApiConfig.getEndpointUrl(endpoint),
      body: body,
    );
  }
  
  static Future<Map<String, dynamic>> deleteWithAuth(
    BuildContext context, 
    String endpoint
  ) async {
    return _requestWithAuth(
      context,
      'DELETE',
      endpoint.startsWith('http') ? endpoint : ApiConfig.getEndpointUrl(endpoint),
    );
  }
}
