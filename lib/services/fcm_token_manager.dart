import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FcmTokenManager {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _fcmTokenKey = 'fcm_token';
  static const String _apiEndpoint =
      'http://192.168.43.221:5000/notifications/fcm-token'; // Ganti dengan API endpoint Anda

  // Mendapatkan token FCM
  static Future<String?> getFcmToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  // Menyimpan FCM token ke secure storage
  static Future<void> saveFcmTokenToStorage(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);
  }

  // Mendapatkan FCM token dari secure storage
  static Future<String?> getFcmTokenFromStorage() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  // Mengirim FCM token ke server
  static Future<bool> sendFcmTokenToServer(String authToken) async {
    final fcmToken = await getFcmToken();

    if (fcmToken == null) {
      print('FCM Token not available');
      return false;
    }

    // Simpan token baru ke storage
    await saveFcmTokenToStorage(fcmToken);

    // Cek apakah token sudah berubah dari yang sebelumnya
    final previousToken = await getFcmTokenFromStorage();
    if (previousToken == fcmToken) {
      // Token belum berubah, tidak perlu update
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        print('FCM Token updated successfully on server');
        return true;
      } else {
        print('Failed to update FCM Token: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  // Hapus FCM token saat logout
  static Future<void> clearFcmToken() async {
    await _storage.delete(key: _fcmTokenKey);
  }
}
