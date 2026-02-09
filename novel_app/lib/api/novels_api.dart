import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import 'dart:io';


class NovelsApi {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<List<dynamic>> fetchNovels() async {
    final res = await http.get(Uri.parse('$baseUrl/novels'));
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return [];
      return jsonDecode(res.body);
    } else {
      throw Exception('Failed to load novels: ${res.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> fetchSections() async {
    final token = await AuthStorage.getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final res = await http.get(Uri.parse('$baseUrl/novels/sections'), headers: headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load sections: ${res.statusCode}');
  }

  static Future<void> recordView(String novelId) async {
    final token = await AuthStorage.getToken();
    final url = token != null
        ? '$baseUrl/novels/$novelId/view'
        : '$baseUrl/novels/$novelId/view_public';

    await http.post(
      Uri.parse(url),
      headers: token != null ? {'Authorization': 'Bearer $token'} : null,
    );
  }
  static Future<List<String>> fetchAllTags() async {
    final res = await http.get(Uri.parse('$baseUrl/novels/tags'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.cast<String>();
    }
    throw Exception('Failed to load tags: ${res.statusCode}');
  }


  static Future<List<dynamic>> searchNovelsSimple(String query) async {
    final uri = Uri.parse('$baseUrl/novels/search?query=${Uri.encodeQueryComponent(query)}');
    final res = await http.get(uri);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Failed to search novels: ${res.statusCode}');
  }

  static Future<String> uploadImage(File file) async {
    final token = await AuthStorage.getToken();
    final uri = Uri.parse('$baseUrl/uploads');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final resp = await request.send();
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final body = await http.Response.fromStream(resp);
      final data = jsonDecode(body.body) as Map<String, dynamic>;
      return data['url'] as String; 
    }
    throw Exception('Upload failed: ${resp.statusCode}');
    }

  static Future<Map<String, dynamic>> createNovel({
    required String title,
    required String description,
    String? coverUrl,
    List<String>? tags,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('No token');
    final res = await http.post(
      Uri.parse('$baseUrl/novels'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'coverUrl': coverUrl,
        'tags': tags ?? [],
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Create novel failed: ${res.statusCode} ${res.body}');
  }

  static Future<Map<String, dynamic>> addChapter({
    required String novelId,
    required String title,
    required String content,
  }) async {
    final token = await AuthStorage.getToken();
    if (token == null) throw Exception('No token');
    final res = await http.post(
      Uri.parse('$baseUrl/novels/$novelId/chapters'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Add chapter failed: ${res.statusCode} ${res.body}');
  }
  static Future<Map<String, dynamic>> fetchNovelById(String id) async {
  final uri = Uri.parse('$baseUrl/novels/$id');
  final res = await http.get(uri);

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load novel: ${res.statusCode} ${res.body}');
  }
}

}
