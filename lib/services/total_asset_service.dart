import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/total_asset.dart';

class TotalAssetService {
  static const String baseUrl =
      'https://12d9aa80-068d-4c47-a664-b62f5cad5ec5.mock.pstmn.io';

  Future<TotalAsset> getTotalAsset() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/total-aset'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          return TotalAsset.fromJson(jsonResponse);
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Failed to load total asset');
        }
      } else {
        throw Exception('Failed to load total asset');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
