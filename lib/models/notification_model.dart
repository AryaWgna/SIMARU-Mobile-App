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
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['detail'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      type: json['type'] ?? 'system',
      assetCode: json['asset_code'],
      assetId: json['asset_id'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'detail': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'type': type,
      'asset_code': assetCode,
      'asset_id': assetId,
      'image_url': imageUrl,
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
