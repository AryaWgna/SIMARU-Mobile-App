import 'package:flutter/material.dart';
import '../services/auth_controller.dart';

class MaintenanceController {
  // Mendapatkan daftar maintenance
  static Future<List<dynamic>> getMaintenanceList(BuildContext context) async {
    try {
      final response = await ApiService.getWithAuth(
        context,
        'maintenance/list', // Endpoint relatif
      );

      if (response['success'] == true) {
        return response['data'] ?? [];
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get maintenance list');
      }
    } catch (e) {
      print('Error getting maintenance list: $e');
      throw Exception('Failed to get maintenance list: $e');
    }
  }

  // Mendapatkan detail maintenance
  static Future<Map<String, dynamic>> getMaintenanceDetail(
      BuildContext context, String id) async {
    try {
      final response = await ApiService.getWithAuth(
        context,
        'maintenance/detail/$id', // Endpoint relatif
      );

      if (response['success'] == true) {
        return response['data'] ?? {};
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get maintenance detail');
      }
    } catch (e) {
      print('Error getting maintenance detail: $e');
      throw Exception('Failed to get maintenance detail: $e');
    }
  }

  // Submit maintenance form
  static Future<Map<String, dynamic>> submitMaintenanceForm(
      BuildContext context, Map<String, dynamic> formData) async {
    try {
      final response = await ApiService.postWithAuth(
        context,
        'maintenance/submit', // Endpoint relatif
        body: formData,
      );

      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(
            response['message'] ?? 'Failed to submit maintenance form');
      }
    } catch (e) {
      print('Error submitting maintenance form: $e');
      throw Exception('Failed to submit maintenance form: $e');
    }
  }
}
