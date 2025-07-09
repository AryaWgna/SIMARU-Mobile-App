import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/asset/asset_under_repair.dart';

class AssetUnderRepairService {
  static const String baseUrl =
      'https://12d9aa80-068d-4c47-a664-b62f5cad5ec5.mock.pstmn.io';

  Future<AssetUnderRepair> getAssetUnderRepair() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/total-aset-under-repair'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          return AssetUnderRepair.fromJson(jsonResponse);
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Failed to load asset under repair');
        }
      } else {
        throw Exception('Failed to load asset under repair');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
