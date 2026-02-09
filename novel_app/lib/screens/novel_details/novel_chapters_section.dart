import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../novel_reader_page.dart';
import '../../l10n/app_localizations.dart';

class NovelChaptersSection extends StatefulWidget {
  final Map<String, dynamic> novel;

  const NovelChaptersSection({super.key, required this.novel});

  @override
  State<NovelChaptersSection> createState() => _NovelChaptersSectionState();
}

class _NovelChaptersSectionState extends State<NovelChaptersSection> {
  List<dynamic> _chapters = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    setState(() => _loading = true);
    final novelId = widget.novel['id'];
    try {
      final uri = Uri.http('10.0.2.2:3000', '/novels/$novelId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _chapters = data['chapters'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching chapters: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_chapters.isEmpty) {
      return Center(child: Text(s.noChapters));
    }

    return ListView.separated(
      itemCount: _chapters.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ch = _chapters[index];
        final title =
            ch['title'] ?? '${s.chapterWord} ${index + 1}';
        return ListTile(
          leading: Text(
            '${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          title: Text(title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NovelReaderPage(
                  novel: widget.novel,
                  initialChapter: ch,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
