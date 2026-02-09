import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';

class RatingsApi {
  static const base = 'http://10.0.2.2:3000';

  static Future<Map<String, dynamic>?> getMyRating(String novelId) async {
    final token = await AuthStorage.getToken();
    if (token == null) return null;
    final res = await http.get(
      Uri.parse('$base/ratings/me?novelId=$novelId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body == null) return null;
      return body as Map<String, dynamic>;
    }
    return null;
  }

  static Future<double> getAverage(String novelId) async {
    final res = await http.get(Uri.parse('$base/novels/$novelId/rating'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['average'] as num?)?.toDouble() ?? 0.0;
    }
    throw Exception('Failed to load average rating');
  }

  static Future<Map<String, dynamic>> setMyRating(String novelId, int value) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.patch(
      Uri.parse('$base/novels/$novelId/rate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'value': value}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to set rating: ${res.statusCode} ${res.body}');
  }
}
