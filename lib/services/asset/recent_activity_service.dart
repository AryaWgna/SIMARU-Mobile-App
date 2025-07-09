import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/dashboard/recent_activity.dart';

class RecentActivityService {
  static const String baseUrl =
      'https://12d9aa80-068d-4c47-a664-b62f5cad5ec5.mock.pstmn.io';

  Future<List<RecentActivity>> getRecentActivities() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final List<dynamic> activitiesJson =
              jsonResponse['data']['recent_activities'];
          return activitiesJson
              .map((json) => RecentActivity.fromJson(json))
              .toList();
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Failed to load recent activities');
        }
      } else {
        throw Exception('Failed to load recent activities');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
