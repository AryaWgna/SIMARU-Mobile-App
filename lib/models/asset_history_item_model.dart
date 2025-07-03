import 'package:flutter/material.dart';

class AssetHistoryItem {
  final int historyId;
  final String actionType;
  final String oldStatus;
  final String newStatus;
  final String message;
  final DateTime actionDate;
  final String userName;
  final String employeeId;
  final Map<String, dynamic>? document;
  final Map<String, dynamic>? maintenance;
  final Map<String, dynamic>? calibration;
  final Map<String, dynamic>? user;

  AssetHistoryItem({
    required this.historyId,
    required this.actionType,
    required this.oldStatus,
    required this.newStatus,
    required this.message,
    required this.actionDate,
    required this.userName,
    required this.employeeId,
    this.document,
    this.maintenance,
    this.calibration,
    this.user,
  });

  factory AssetHistoryItem.fromJson(Map<String, dynamic> json) {
    // Ekstrak tanggal dari berbagai kemungkinan field
    DateTime? actionDate;
    if (json['action_date'] != null) {
      try {
        actionDate = DateTime.parse(json['action_date']);
      } catch (e) {
        print('Error parsing action_date: $e');
      }
    } else if (json['timestamp'] != null) {
      try {
        actionDate = DateTime.parse(json['timestamp']);
      } catch (e) {
        print('Error parsing timestamp: $e');
      }
    } else if (json['created_at'] != null) {
      try {
        actionDate = DateTime.parse(json['created_at']);
      } catch (e) {
        print('Error parsing created_at: $e');
      }
    } else if (json['date'] != null) {
      try {
        actionDate = DateTime.parse(json['date']);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    // Jika semua parsing gagal, gunakan waktu saat ini
    actionDate ??= DateTime.now();

    // Ekstrak employee_id dari user jika tersedia
    String employeeId = '';
    if (json['user'] != null && json['user']['employee_number'] != null) {
      employeeId = json['user']['employee_number'].toString();
    } else if (json['employee_id'] != null) {
      employeeId = json['employee_id'].toString();
    } else if (json['employee_number'] != null) {
      employeeId = json['employee_number'].toString();
    }

    // Ekstrak username dari berbagai kemungkinan field
    String userName = 'Unknown';
    if (json['user'] != null && json['user']['name'] != null) {
      userName = json['user']['name'].toString();
    } else if (json['user_name'] != null) {
      userName = json['user_name'].toString();
    } else if (json['username'] != null) {
      userName = json['username'].toString();
    } else if (json['name'] != null) {
      userName = json['name'].toString();
    }

    return AssetHistoryItem(
      historyId: json['history_id'] ?? json['id'] ?? 0,
      actionType: json['action_type'] ?? '',
      oldStatus: json['old_status'] ?? '',
      newStatus: json['new_status'] ?? '',
      message: json['message'] ?? '',
      actionDate: actionDate,
      userName: userName,
      employeeId: employeeId,
      document: json['document'],
      maintenance: json['maintenance'],
      calibration: json['calibration'],
      user: json['user'],
    );
  }

  // Fungsi untuk mendapatkan jenis ikon berdasarkan tipe aksi
  IconData getActionIcon() {
    switch (actionType.toUpperCase()) {
      case 'DOCUMENT_UPLOAD':
        return Icons.description;
      case 'ASSET_STATUS_CHANGE':
        return Icons.swap_horiz;
      case 'MAINTENANCE_SCHEDULE':
        return Icons.build;
      case 'CALIBRATION':
        return Icons.settings;
      case 'CHECKIN':
        return Icons.check_circle;
      case 'CHECKOUT':
        return Icons.exit_to_app;
      case 'REPAIR':
        return Icons.build;
      case 'TRANSFER':
      case 'MUTATION':
        return Icons.swap_calls;
      case 'COMPLAINT':
        return Icons.warning;
      default:
        return Icons.history;
    }
  }

  // Fungsi untuk mendapatkan warna berdasarkan tipe aksi
  Color getActionColor() {
    switch (actionType.toUpperCase()) {
      case 'DOCUMENT_UPLOAD':
        return const Color(0xFF2196F3); // Biru
      case 'ASSET_STATUS_CHANGE':
        return const Color(0xFF9C27B0); // Ungu
      case 'MAINTENANCE_SCHEDULE':
        return const Color(0xFFFF9800); // Oranye
      case 'CALIBRATION':
        return const Color(0xFF4CAF50); // Hijau
      case 'CHECKIN':
        return const Color(0xFF4CAF50); // Hijau
      case 'CHECKOUT':
        return const Color(0xFFFF9800); // Oranye
      case 'REPAIR':
        return const Color(0xFFFFC107); // Kuning
      case 'COMPLAINT':
        return const Color(0xFFF44336); // Merah
      default:
        return const Color(0xFF757575); // Abu-abu
    }
  }

  // Fungsi untuk menerjemahkan status
  String translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'available':
      case 'returned':
        return 'Tersedia';
      case 'inactive':
        return 'Tidak aktif';
      case 'under_repair':
      case 'under repair':
        return 'Dalam perbaikan';
      case 'broken':
        return 'Rusak';
      case 'disposed':
      case 'dispose':
        return 'Dihapuskan';
      case 'checked_out':
      case 'checked out':
        return 'Dipinjam';
      case 'checked_in':
      case 'checked in':
        return 'Dikembalikan';
      case 'lost':
        return 'Hilang';
      default:
        return status;
    }
  }
}
