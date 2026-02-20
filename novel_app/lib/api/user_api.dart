import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../config/api_config.dart';

class UserApi {
  static const String baseUrl = '${ApiConfig.baseUrl}';

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('No token found');

    final res = await http.get(
      Uri.parse('$baseUrl/users/me'), 
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load profile: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? avatarUrl,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('No token found');

    final body = <String, dynamic>{};
    if (name != null) body['displayName'] = name; 
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (bio != null) body['bio'] = bio;
    if (preferences != null) body['preferences'] = preferences;

    final res = await http.patch(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update profile: ${res.statusCode} ${res.body}');
    }
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('No token found');

    final res = await http.patch(
      Uri.parse('$baseUrl/users/me/password'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to change password: ${res.statusCode} ${res.body}');
    }
  }
}
