import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';

class LibraryApi {
  static const base = 'http://10.0.2.2:3000';

  static Future<List<dynamic>> myLibrary({String? status}) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse(
      status == null ? '$base/library/me' : '$base/library/me?status=$status',
    );
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode == 200) return (jsonDecode(res.body) as List);
    throw Exception('Failed to load library: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> upsert(
    String novelId, {
    required String status, 
    bool favorite = false,
    int? progress,
  }) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$base/library/$novelId');
    final body = <String, dynamic>{'status': status, 'favorite': favorite};
    if (progress != null) body['progress'] = progress;

    final res = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to add/update library entry: ${res.statusCode} ${res.body}');
  }
}
