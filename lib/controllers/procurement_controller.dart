import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'dart:convert';
import '../models/procurement_model.dart';

class ProcurementController {
  // Mendapatkan daftar procurement
  static Future<ProcurementResponse> getProcurementList(BuildContext context) async {
    try {
      final response = await ApiService.get(
        '/procurements', // Endpoint
        context: context,
      );

      // Decode response
      final jsonResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ProcurementResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to get procurement list');
      }
    } catch (e) {
      print('Error getting procurement list: $e');
      throw Exception('Failed to get procurement list: $e');
    }
  }

  // Mendapatkan detail procurement
  static Future<Procurement> getProcurementDetail(
      BuildContext context, int id) async {
    try {
      final response = await ApiService.get(
        '/procurements/$id', // Endpoint relatif
        context: context,
      );

      // Decode response
      final jsonResponse = jsonDecode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['status'] == true) {
        return Procurement.fromJson(jsonResponse['data']);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to get procurement detail');
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
      final response = await ApiService.post(
        '/procurements', // Endpoint relatif
        body: requestData,
        context: context,
      );

      // Decode response
      final jsonResponse = jsonDecode(response.body);
      
      if (response.statusCode == 201 && jsonResponse['status'] == true) {
        return jsonResponse;
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to submit procurement request');
      }
    } catch (e) {
      print('Error submitting procurement request: $e');
      throw Exception('Failed to submit procurement request: $e');
    }
  }
}
