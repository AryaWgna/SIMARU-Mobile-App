import 'package:flutter/material.dart';

class AssetComplaintModel {
  final int id;
  final int assetId;
  final String assetCode;
  final String assetName;
  final String description;
  final String status;
  final String? picturePath;
  final String reporterName;
  final String reporterEmployeeNumber;
  final DateTime reportDate;
  final String? resolvedBy;
  final DateTime? resolvedDate;
  final String? resolution;

  AssetComplaintModel({
    required this.id,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.description,
    required this.status,
    this.picturePath,
    required this.reporterName,
    required this.reporterEmployeeNumber,
    required this.reportDate,
    this.resolvedBy,
    this.resolvedDate,
    this.resolution,
  });

  factory AssetComplaintModel.fromJson(Map<String, dynamic> json) {
    return AssetComplaintModel(
      id: json['id'] ?? 0,
      assetId: json['asset_id'] ?? 0,
      assetCode: json['asset_code'] ?? '',
      assetName: json['asset_name'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      picturePath: json['complaint_picture_path'],
      reporterName: json['reporter_name'] ?? '',
      reporterEmployeeNumber: json['reporter_employee_number'] ?? '',
      reportDate: json['report_date'] != null
          ? DateTime.parse(json['report_date'])
          : DateTime.now(),
      resolvedBy: json['resolved_by'],
      resolvedDate: json['resolved_date'] != null
          ? DateTime.parse(json['resolved_date'])
          : null,
      resolution: json['resolution'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'asset_id': assetId,
      'asset_code': assetCode,
      'asset_name': assetName,
      'description': description,
      'status': status,
      'complaint_picture_path': picturePath,
      'reporter_name': reporterName,
      'reporter_employee_number': reporterEmployeeNumber,
      'report_date': reportDate.toIso8601String(),
      'resolved_by': resolvedBy,
      'resolved_date': resolvedDate?.toIso8601String(),
      'resolution': resolution,
    };
  }

  String getStatusInIndonesian() {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'in_progress':
        return 'Sedang Diproses';
      case 'resolved':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFC107); // Kuning
      case 'in_progress':
        return const Color(0xFF007BFF); // Biru
      case 'resolved':
        return const Color(0xFF28A745); // Hijau
      case 'rejected':
        return const Color(0xFFDC3545); // Merah
      default:
        return const Color(0xFF6C757D); // Abu-abu
    }
  }
}
 