import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../config/api_config.dart';

class NotificationsApi {
  static const base = '${ApiConfig.baseUrl}';

  static Future<List<dynamic>> list({bool unreadOnly = false}) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$base/notifications/me${unreadOnly ? '?unread=1' : ''}');
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200) return (jsonDecode(res.body) as List);
    throw Exception('Failed to load notifications: ${res.statusCode}');
  }

  static Future<void> markRead(String id) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$base/notifications/$id/read');
    final res = await http.patch(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      throw Exception('Failed to mark as read: ${res.statusCode}');
    }
  }

  static Future<void> markAllRead() async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$base/notifications/read-all');
    final res = await http.patch(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      throw Exception('Failed to mark all as read: ${res.statusCode}');
    }
  }
}
