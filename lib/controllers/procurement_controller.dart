import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth_controller.dart';
import '../core/config/api_config.dart';

class ProcurementController {
  // Mendapatkan daftar procurement
  static Future<List<dynamic>> getProcurementList(BuildContext context) async {
    try {
      final response = await ApiService.getWithAuth(
        context,
        'procurement/list', // Endpoint relatif
      );

      if (response['success'] == true) {
        return response['data'] ?? [];
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get procurement list');
      }
    } catch (e) {
      print('Error getting procurement list: $e');
      throw Exception('Failed to get procurement list: $e');
    }
  }

  // Mendapatkan detail procurement
  static Future<Map<String, dynamic>> getProcurementDetail(
      BuildContext context, String id) async {
    try {
      final response = await ApiService.getWithAuth(
        context,
        'procurement/detail/$id', // Endpoint relatif
      );

      if (response['success'] == true) {
        return response['data'] ?? {};
      } else {
        throw Exception(
            response['message'] ?? 'Failed to get procurement detail');
      }
    } catch (e) {
      print('Error getting procurement detail: $e');
      throw Exception('Failed to get procurement detail: $e');
    }
  }

  // Submit procurement request
  static Future<Map<String, dynamic>> submitProcurementRequest(
      BuildContext context, Map<String, dynamic> requestData) async {
    try {
      final response = await ApiService.postWithAuth(
        context,
        'procurement/submit', // Endpoint relatif
        body: requestData,
      );

      if (response['success'] == true) {
        return response;
      } else {
        throw Exception(
            response['message'] ?? 'Failed to submit procurement request');
      }
    } catch (e) {
      print('Error submitting procurement request: $e');
      throw Exception('Failed to submit procurement request: $e');
    }
  }
}
