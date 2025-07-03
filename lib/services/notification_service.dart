import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../controllers/auth_controller.dart';
import '../utils/logger_util.dart';

class NotificationService {
  // Mendapatkan semua notifikasi
  static Future<Map<String, dynamic>> getNotifications({
    BuildContext? context,
    int page = 1,
    int limit = 10,
    String? search,
    String sort = 'date_desc',
    bool? isRead,
  }) async {
    try {
      // Log request parameters for debugging
      LoggerUtil.d('Fetching notifications with parameters:');
      LoggerUtil.d('- page: $page');
      LoggerUtil.d('- limit: $limit');
      LoggerUtil.d('- sort: $sort');
      LoggerUtil.d('- isRead: $isRead');
      LoggerUtil.d('- search: $search');

      // Buat query parameter sesuai spesifikasi API Laravel
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      // Tambahkan employee_number dari user yang sedang login
      final employeeNumber = await ApiService.getEmployeeNumber();
      if (employeeNumber != null && employeeNumber.isNotEmpty) {
        queryParams['employee_number'] = employeeNumber;
        LoggerUtil.d(
            'Adding employee_number: $employeeNumber to notifications request');
      }

      // Tambahkan parameter search jika ada
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // Tambahkan parameter is_read jika ada
      if (isRead != null) {
        // Match Laravel API format: true/false string instead of 1/0
        queryParams['is_read'] = isRead.toString();
        LoggerUtil.d(
            'Filtering notifications by read status: ${isRead ? 'true (Read)' : 'false (Unread)'}');
      }

      // Buat URL dengan query parameters
      final Uri uri = Uri.parse('${ApiService.baseUrl}/notifications').replace(
        queryParameters: queryParams,
      );

      LoggerUtil.d('Fetching notifications with URL: $uri');

      // Gunakan token untuk otorisasi
      final token = await ApiService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Kirim request ke API
      final response = await http.get(uri, headers: headers);
      LoggerUtil.d('API response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerUtil.d('API Response data: $data');

        if (data['success'] == true && data['data'] != null) {
          // Ambil data notifikasi
          List<NotificationModel> notifications = [];
          if (data['data'] is List) {
            notifications = (data['data'] as List)
                .map((item) => NotificationModel.fromJson(item))
                .toList();

            // Log read status of each notification for debugging
            for (var i = 0; i < notifications.length; i++) {
              LoggerUtil.d(
                  'Notification ${i + 1}: id = ${notifications[i].id}, isRead = ${notifications[i].isRead}, readAt = ${notifications[i].readAt}');
            }

            // Verify that returned notifications match our filter criteria
            if (isRead != null && notifications.isNotEmpty) {
              // Double-check filtering on client side if needed
              notifications =
                  notifications.where((n) => n.isRead == isRead).toList();
              LoggerUtil.d(
                  'After client-side filtering: ${notifications.length} notifications');
            }

            // Ambil data pagination dari format Laravel
            Map<String, dynamic> pagination = {};
            if (data['pagination'] != null) {
              final paginationData = data['pagination'];
              pagination = {
                'total_items':
                    paginationData['total_items'] ?? notifications.length,
                'total_pages': paginationData['total_pages'] ?? 1,
                'current_page': paginationData['current_page'] ?? page,
                'limit': paginationData['limit'] ?? limit,
                'has_next': paginationData['has_next'] ?? false,
                'has_prev': paginationData['has_prev'] ?? false,
                // Tambahkan field format Laravel
                'from': ((paginationData['current_page'] ?? page) - 1) *
                        (paginationData['limit'] ?? limit) +
                    1,
                'to': ((paginationData['current_page'] ?? page) *
                            (paginationData['limit'] ?? limit) >
                        (paginationData['total_items'] ?? notifications.length))
                    ? (paginationData['total_items'] ?? notifications.length)
                    : ((paginationData['current_page'] ?? page) *
                        (paginationData['limit'] ?? limit)),
                'last_page': paginationData['total_pages'] ?? 1,
                'per_page': paginationData['limit'] ?? limit,
                'total': paginationData['total_items'] ?? notifications.length,
              };
            } else {
              pagination =
                  _createDefaultPagination(page, limit, notifications.length);
            }

            // Kembalikan hasil dalam format Map
            return {
              'notifications': notifications,
              'pagination': pagination,
              'message': data['message'] ?? 'Notifikasi berhasil diambil',
            };
          } else {
            LoggerUtil.w('Data tidak valid: ${data['message']}');
            return _createEmptyResponse(page, limit);
          }
        } else {
          LoggerUtil.w('Data tidak valid: ${data['message']}');
          return _createEmptyResponse(page, limit);
        }
      } else if (response.statusCode == 401) {
        // Token tidak valid/kadaluarsa
        LoggerUtil.w(
            'Tidak diizinkan: Token tidak disediakan atau tidak valid');
        return _createEmptyResponse(page, limit);
      } else if (response.statusCode == 403) {
        // Akses ditolak
        LoggerUtil.w('Dilarang: Akses ditolak');
        return _createEmptyResponse(page, limit);
      } else {
        LoggerUtil.w('Error status code: ${response.statusCode}');
        return _createEmptyResponse(page, limit);
      }
    } catch (e) {
      LoggerUtil.e('Error mengambil notifikasi', e, StackTrace.current);
      return _createEmptyResponse(page, limit);
    }
  }

  // Helper untuk membuat respons kosong dengan format pagination Laravel
  static Map<String, dynamic> _createEmptyResponse(int page, int limit) {
    return {
      'notifications': <NotificationModel>[],
      'pagination': _createDefaultPagination(page, limit, 0),
      'message': 'Tidak ada notifikasi',
    };
  }

  // Helper untuk membuat pagination default dengan format Laravel
  static Map<String, dynamic> _createDefaultPagination(
      int page, int limit, int totalItems) {
    return {
      'total_items': totalItems,
      'total_pages': totalItems > 0 ? ((totalItems - 1) ~/ limit) + 1 : 1,
      'current_page': page,
      'limit': limit,
      'has_next': page < (((totalItems - 1) ~/ limit) + 1),
      'has_prev': page > 1,
      // Format Laravel
      'from': totalItems > 0 ? ((page - 1) * limit) + 1 : 0,
      'to': (page * limit > totalItems) ? totalItems : page * limit,
      'last_page': totalItems > 0 ? ((totalItems - 1) ~/ limit) + 1 : 1,
      'per_page': limit,
      'total': totalItems,
    };
  }

  // Tandai notifikasi sebagai telah dibaca
  static Future<Map<String, dynamic>?> markAsRead(int notificationId,
      {BuildContext? context}) async {
    try {
      final endpoint = '/notifications/$notificationId/read';
      LoggerUtil.d('Marking notification $notificationId as read');

      // Menggunakan metode POST sesuai implementasi server Laravel
      final token = await ApiService.getAccessToken();
      final url = Uri.parse('${ApiService.baseUrl}$endpoint');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Dapatkan employee number dari user yang sedang login
      final employeeNumber = await ApiService.getEmployeeNumber();

      // Buat body request dengan employee number
      final Map<String, dynamic> requestBody = {};
      if (employeeNumber != null && employeeNumber.isNotEmpty) {
        requestBody['employee_number'] = employeeNumber;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      LoggerUtil.d(
          'Mark as read response: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          LoggerUtil.d('Notification marked as read successfully');
          return {
            'success': true,
            'message': data['message'] ?? 'Notifikasi ditandai sebagai dibaca',
            'read_at':
                data['data']?['read_at'] ?? DateTime.now().toIso8601String(),
          };
        } else {
          LoggerUtil.w(
              'Failed to mark notification as read: ${data['message']}');
          return {
            'success': false,
            'message':
                data['message'] ?? 'Gagal menandai notifikasi sebagai dibaca',
          };
        }
      } else {
        LoggerUtil.w(
            'Error marking notification as read: ${response.statusCode}');
        return {
          'success': false,
          'message':
              'Gagal menandai notifikasi sebagai dibaca (${response.statusCode})',
        };
      }
    } catch (e) {
      LoggerUtil.e('Error marking notification as read', e, StackTrace.current);
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Tandai semua notifikasi sebagai telah dibaca
  static Future<Map<String, dynamic>> markAllAsRead(
      {BuildContext? context}) async {
    try {
      // Endpoint sesuai dengan Laravel
      final endpoint = '/notifications/read-all';

      // Dapatkan employee number dari user yang sedang login
      final employeeNumber = await ApiService.getEmployeeNumber();

      // Dapatkan token untuk otorisasi
      final token = await ApiService.getAccessToken();
      final url = Uri.parse('${ApiService.baseUrl}$endpoint');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Buat body request dengan employee number
      final Map<String, dynamic> requestBody = {};
      if (employeeNumber != null && employeeNumber.isNotEmpty) {
        requestBody['employee_number'] = employeeNumber;
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      LoggerUtil.d(
          'Mark all as read response: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ??
              'Semua notifikasi berhasil ditandai sebagai sudah dibaca',
          'data': data['data'],
        };
      } else if (response.statusCode == 401) {
        LoggerUtil.w('Tidak diizinkan. Token tidak disediakan.');
        return {
          'success': false,
          'errors': 'Autentikasi gagal',
        };
      } else {
        final errorMessage = _parseErrorResponse(response);
        LoggerUtil.w(
            'Error status code: ${response.statusCode}, message: $errorMessage');
        return {
          'success': false,
          'errors': errorMessage,
        };
      }
    } catch (e) {
      LoggerUtil.e(
          'Error menandai semua notifikasi dibaca', e, StackTrace.current);
      return {
        'success': false,
        'errors':
            'Gagal menandai semua notifikasi sebagai sudah dibaca: ${e.toString()}',
      };
    }
  }

  // Helper untuk mengurai pesan error dari response
  static String _parseErrorResponse(http.Response response) {
    try {
      final data = json.decode(response.body);

      // Format error message seperti di Laravel controller
      String errorMessage = 'Terjadi kesalahan';

      if (data['errors'] != null) {
        final errorData = data['errors'];
        if (errorData is String) {
          errorMessage = errorData;
        } else if (errorData is List && errorData.isNotEmpty) {
          errorMessage = errorData.join(', ');
        } else if (errorData is Map) {
          final messages = <String>[];
          errorData.forEach((field, msgs) {
            if (msgs is List) {
              messages.add(msgs.join(', '));
            } else if (msgs is String) {
              messages.add(msgs);
            }
          });
          errorMessage = messages.join('; ');
        }
      } else if (data['message'] != null) {
        errorMessage = data['message'];
      }

      return errorMessage;
    } catch (e) {
      return 'Terjadi kesalahan: ${response.statusCode}';
    }
  }

  // Hitung notifikasi yang belum dibaca
  static Future<int> getUnreadCount({BuildContext? context}) async {
    try {
      // Dapatkan employee number dari user yang sedang login
      final employeeNumber = await ApiService.getEmployeeNumber();

      // Gunakan parameter is_read untuk hanya mengambil notifikasi yang belum dibaca
      final result = await getNotifications(
        context: context,
        page: 1,
        limit: 1, // Kita hanya perlu total count, bukan datanya
        isRead: false, // Hanya ambil yang belum dibaca
      );

      // Ambil total dari pagination
      final pagination = result['pagination'] as Map<String, dynamic>;
      return pagination['total'] as int;
    } catch (e) {
      LoggerUtil.e('Error mendapatkan jumlah notifikasi belum dibaca', e,
          StackTrace.current);
      return 0;
    }
  }
}
