import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'dart:convert';
import '../models/procurement_model.dart';
import 'dart:convert';

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
      print('Debug - Submit request: ${json.encode(requestData)}');
      
      final response = await ApiService.post(
        '/procurements',
        body: requestData,
        context: context,
      );

      final jsonResponse = jsonDecode(response.body);
      print('Debug - Response received: ${json.encode(jsonResponse)}');
      
      if ((response.statusCode == 201 || response.statusCode == 200) && 
          jsonResponse['status'] == true) {
        return jsonResponse['data'];
      } else {
        print('Failed with status code: ${response.statusCode}');
        print('Response: ${response.body}');
        
        if (jsonResponse['errors'] != null && jsonResponse['errors'] is List) {
          final errors = jsonResponse['errors'] as List;
          if (errors.isNotEmpty) {
            final firstError = errors.first;
            final errorMessage = firstError['message'] ?? 'Validation error';
            throw Exception(errorMessage);
          }
        }
        
        throw Exception(jsonResponse['message'] ?? 'Failed to submit procurement request');
      }
    } catch (e) {
      print('Error submitting procurement request: $e');
      throw Exception('$e');
    }
  }
}
