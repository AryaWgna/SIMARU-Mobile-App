import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../controllers/auth_controller.dart';

class NotificationService {
  // Mendapatkan semua notifikasi
  static Future<Map<String, dynamic>> getNotifications(
      {BuildContext? context,
      int page = 1,
      int limit = 10,
      String? search,
      String sortBy = 'created_at',
      String sortOrder = 'desc'}) async {
    try {
      // Buat query parameter sesuai spesifikasi API
      String endpoint = '/notifications?page=$page&limit=$limit';

      if (search != null && search.isNotEmpty) {
        endpoint += '&search=$search';
      }

      endpoint += '&sort_by=$sortBy&sort_order=$sortOrder';

      final response = await ApiService.get(endpoint, context: context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Ambil data notifikasi
          List<NotificationModel> notifications = [];
          if (data['data'] is List) {
            notifications = (data['data'] as List)
                .map((item) => NotificationModel.fromJson(item))
                .toList();
          }

          // Ambil data pagination
          Map<String, dynamic> pagination = {};
          if (data['pagination'] != null) {
            pagination = data['pagination'];
          } else {
            pagination = {
              'total_items': notifications.length,
              'total_pages': 1,
              'current_page': page,
              'limit': limit,
              'has_next': false,
              'has_prev': false,
            };
          }

          // Kembalikan hasil dalam format Map
          return {
            'notifications': notifications,
            'pagination': pagination,
          };
        } else {
          debugPrint('Data tidak valid: ${data['message']}');
          return _createEmptyResponse(page, limit);
        }
      } else if (response.statusCode == 401) {
        // Token tidak valid/kadaluarsa
        debugPrint('Tidak diizinkan: Token tidak disediakan atau tidak valid');
        return _createEmptyResponse(page, limit);
      } else if (response.statusCode == 403) {
        // Akses ditolak
        debugPrint('Dilarang: Akses ditolak');
        return _createEmptyResponse(page, limit);
      } else {
        debugPrint('Error status code: ${response.statusCode}');
        return _createEmptyResponse(page, limit);
      }
    } catch (e) {
      debugPrint('Error mengambil notifikasi: $e');
      return _createEmptyResponse(page, limit);
    }
  }

  // Helper untuk membuat respons kosong
  static Map<String, dynamic> _createEmptyResponse(int page, int limit) {
    return {
      'notifications': <NotificationModel>[],
      'pagination': {
        'total_items': 0,
        'total_pages': 0,
        'current_page': page,
        'limit': limit,
        'has_next': false,
        'has_prev': false,
      },
    };
  }

  // Tandai notifikasi sebagai telah dibaca
  static Future<Map<String, dynamic>?> markAsRead(int notificationId,
      {BuildContext? context}) async {
    try {
      final endpoint = '/notifications/$notificationId/read';

      // Menggunakan metode POST sesuai implementasi server
      final token = await ApiService.getAccessToken();
      final url = Uri.parse('${ApiService.baseUrl}$endpoint');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: '{}', // Body kosong tapi tetap kirim untuk POST request
      );

      debugPrint(
          'Mark as read response: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Kembalikan data lengkap dari API
        return {
          'success': data['success'] == true,
          'message': data['message'],
          // Gunakan waktu dari API jika tersedia, jika tidak gunakan waktu sekarang
          'read_at': data['data'] != null && data['data']['read_at'] != null
              ? data['data']['read_at']
              : DateTime.now().toIso8601String(),
        };
      } else if (response.statusCode == 400) {
        debugPrint('ID Notifikasi tidak valid');
        return null;
      } else if (response.statusCode == 401) {
        debugPrint('Tidak diizinkan. Token tidak disediakan.');
        return null;
      } else if (response.statusCode == 403) {
        debugPrint('Dilarang: Akses ditolak');
        return null;
      } else if (response.statusCode == 500) {
        debugPrint('Gagal menandai notifikasi sebagai telah dibaca');
        return null;
      } else {
        debugPrint('Error status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error menandai notifikasi dibaca: $e');
      return null;
    }
  }

  // Tandai semua notifikasi sebagai telah dibaca
  static Future<bool> markAllAsRead({BuildContext? context}) async {
    try {
      // Endpoint '/notifications/read-all' tidak tersedia di server
      // Sebagai alternatif, bisa dibuat catatan untuk backend team untuk membuat endpoint ini
      debugPrint('Endpoint /notifications/read-all tidak tersedia di server');

      // Sementara, kembalikan false karena fitur tidak tersedia
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Fitur menandai semua notifikasi belum tersedia di server'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error menandai semua notifikasi dibaca: $e');
      return false;
    }
  }

  // Update FCM Token - ini tidak akan diimplementasi sesuai permintaan

  // Hitung notifikasi yang belum dibaca
  static Future<int> getUnreadCount({BuildContext? context}) async {
    try {
      // Dapatkan semua notifikasi dan hitung yang belum dibaca
      final result = await getNotifications(
        context: context,
        page: 1,
        limit: 100, // Ambil banyak notifikasi untuk dihitung
      );

      final notifications = result['notifications'] as List<NotificationModel>;
      return notifications.where((notification) => !notification.isRead).length;
    } catch (e) {
      debugPrint('Error mendapatkan jumlah notifikasi belum dibaca: $e');
      return 0;
    }
  }
}
