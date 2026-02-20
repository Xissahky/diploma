import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../config/api_config.dart';

class AchievementsApi {
  static const base = '${ApiConfig.baseUrl}';

  static Future<List<dynamic>> myAchievements() async {
    final token = await AuthStorage.getToken();
    final res = await http.get(
      Uri.parse('$base/achievements/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List);
    }
    throw Exception('Failed to load my achievements: ${res.statusCode}');
  }

  static Future<List<dynamic>> allAchievements() async {
    final token = await AuthStorage.getToken();
    final res = await http.get(
      Uri.parse('$base/achievements/all'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List);
    }
    throw Exception('Failed to load all achievements: ${res.statusCode}');
  }

}
