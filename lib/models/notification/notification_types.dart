import 'package:flutter/material.dart';

/// Enum untuk tipe notifikasi
enum NotificationType {
  asset,
  complaint,
  maintenance,
  reminder,
  system,
}

/// Extension untuk tipe notifikasi
extension NotificationTypeExtension on NotificationType {
  /// Mendapatkan judul berdasarkan tipe
  String get title {
    switch (this) {
      case NotificationType.asset:
        return 'Aset';
      case NotificationType.complaint:
        return 'Pengaduan';
      case NotificationType.maintenance:
        return 'Pemeliharaan';
      case NotificationType.reminder:
        return 'Pengingat';
      case NotificationType.system:
        return 'Sistem';
    }
  }

  /// Mendapatkan warna berdasarkan tipe
  Color get color {
    switch (this) {
      case NotificationType.asset:
        return const Color(0xFF25B1FF); // Biru
      case NotificationType.complaint:
        return const Color(0xFFFF6B6B); // Merah
      case NotificationType.maintenance:
        return const Color(0xFFFFB86C); // Oranye
      case NotificationType.reminder:
        return const Color(0xFF63C132); // Hijau
      case NotificationType.system:
        return const Color(0xFF8E8E93); // Abu-abu
    }
  }

  /// Mendapatkan ikon berdasarkan tipe
  IconData get icon {
    switch (this) {
      case NotificationType.asset:
        return Icons.inventory;
      case NotificationType.complaint:
        return Icons.warning_amber_rounded;
      case NotificationType.maintenance:
        return Icons.build;
      case NotificationType.reminder:
        return Icons.notifications_active;
      case NotificationType.system:
        return Icons.system_update;
    }
  }

  /// Mendapatkan tipe dari string
  static NotificationType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'asset':
        return NotificationType.asset;
      case 'complaint':
        return NotificationType.complaint;
      case 'maintenance':
        return NotificationType.maintenance;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}
