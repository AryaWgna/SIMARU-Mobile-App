import 'dart:convert';
import 'notification_types.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String type;
  final String? assetCode;
  final int? assetId;
  final String? imageUrl;
  final String? employeeNumber;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.readAt,
    required this.type,
    this.assetCode,
    this.assetId,
    this.imageUrl,
    this.employeeNumber,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Handle different formats of isRead from the API
    bool isRead = false;
    if (json['is_read'] != null) {
      if (json['is_read'] is bool) {
        isRead = json['is_read'];
      } else if (json['is_read'] is String) {
        isRead =
            json['is_read'].toLowerCase() == 'true' || json['is_read'] == '1';
      } else if (json['is_read'] is int) {
        isRead = json['is_read'] == 1;
      }
    }

    // Ensure we have a readAt timestamp if the notification is marked as read
    DateTime? readAt;
    if (json['read_at'] != null) {
      try {
        readAt = DateTime.parse(json['read_at']);
      } catch (e) {
        // If parsing fails, use null
        readAt = null;
      }
    } else if (isRead) {
      // If notification is read but no read_at timestamp, use created_at as fallback
      try {
        readAt = DateTime.parse(json['created_at']);
      } catch (e) {
        readAt = null;
      }
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['detail'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: isRead,
      readAt: readAt,
      type: json['type'] ?? 'system',
      assetCode: json['asset_code'],
      assetId: json['asset_id'],
      imageUrl: json['image_url'],
      employeeNumber: json['employee_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'detail': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead.toString(),
      'read_at': readAt?.toIso8601String(),
      'type': type,
      'asset_code': assetCode,
      'asset_id': assetId,
      'image_url': imageUrl,
      'employee_number': employeeNumber,
    };
  }

  NotificationType getNotificationType() {
    return NotificationTypeExtension.fromString(type);
  }

  static List<NotificationModel> parseNotifications(String responseBody) {
    final parsed = jsonDecode(responseBody);

    if (parsed['success'] == true && parsed['data'] != null) {
      final data = parsed['data'] as List;
      return data
          .map<NotificationModel>((json) => NotificationModel.fromJson(json))
          .toList();
    }

    return [];
  }

  static Map<String, dynamic> parsePagination(String responseBody) {
    final parsed = jsonDecode(responseBody);

    if (parsed['success'] == true && parsed['pagination'] != null) {
      return parsed['pagination'] as Map<String, dynamic>;
    }

    return {
      'total_items': 0,
      'total_pages': 0,
      'current_page': 1,
      'limit': 10,
      'has_next': false,
      'has_prev': false
    };
  }
}
