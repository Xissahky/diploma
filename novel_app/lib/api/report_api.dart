import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../config/api_config.dart';

class ReportApi {
  static const baseUrl = "${ApiConfig.baseUrl}";

  static Future<void> sendReport({
    required String targetType, 
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception("Not logged in");

    final uri = Uri.http(baseUrl, "/reports");
    final res = await http.post(uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "targetType": targetType,
          "targetId": targetId,
          "reason": reason,
          "description": description,
        }));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Report failed: ${res.body}");
    }
  }
}
