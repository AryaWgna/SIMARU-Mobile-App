import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl =
      'https://12d9aa80-068d-4c47-a664-b62f5cad5ec5.mock.pstmn.io';
  static const storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> login(
      String userId, String password) async {
    try {
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

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: 'token', value: data['token']);
        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal login');
      }
    } catch (e) {
      print('Error during login: $e');
      throw Exception('Gagal melakukan koneksi ke server');
    }
  }

  static Future<void> logout() async {
    final token = await storage.read(key: 'token');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    await storage.delete(key: 'token');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await storage.read(key: 'token');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profiles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'name': responseData['data']['name'],
          'email': responseData['data']['email'],
          'phone': responseData['data']['phone_number'],
          'image': responseData['data']['image_path'],
        };
      } else {
        throw Exception('Gagal mengambil profil');
      }
    } catch (e) {
      print('Error getting profile: $e');
      throw Exception('Gagal melakukan koneksi ke server');
    }
  }
}
