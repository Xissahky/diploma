import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'novel_details.dart';
import '../config/api_config.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;

  List<String> _allTags = [];
  final Set<String> _selectedTags = {};
  String _matchMode = 'any';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _fetchTags(); 
  }

  Future<void> _fetchTags() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/novels/tags');
      final res = await http.get(uri);

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        if (data is List) {
          setState(() {
            _allTags = data.map((e) => e.toString()).toList();
          });
        }
      } else {
        debugPrint('Failed to load tags: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching tags: $e');
    }
  }

  Future<void> _searchNovels(String query) async {
    if (query.isEmpty && _selectedTags.isEmpty) return;

    setState(() => _loading = true);
    try {
      final params = <String, String>{
        if (query.isNotEmpty) 'query': query,
        if (_selectedTags.isNotEmpty) 'tags': _selectedTags.join(','),
        'mode': _matchMode,
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/novels/search',
      ).replace(queryParameters: params);
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        setState(() {
          _results = res.body.trim().isEmpty ? [] : jsonDecode(res.body);
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Novels'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            tooltip: _showFilters ? 'Hide filters' : 'Show filters',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter novel title...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchNovels(_controller.text.trim()),
                ),
              ),
              onSubmitted: _searchNovels,
            ),
            const SizedBox(height: 8),

            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _allTags.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Match:'),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Any'),
                              selected: _matchMode == 'any',
                              onSelected: (_) =>
                                  setState(() => _matchMode = 'any'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('All'),
                              selected: _matchMode == 'all',
                              onSelected: (_) =>
                                  setState(() => _matchMode = 'all'),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              icon: const Icon(Icons.search),
                              label: const Text('Apply'),
                              onPressed: () =>
                                  _searchNovels(_controller.text.trim()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: -8,
                          children: _allTags.map((t) {
                            final sel = _selectedTags.contains(t);
                            return FilterChip(
                              label: Text(t),
                              selected: sel,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedTags.add(t);
                                  } else {
                                    _selectedTags.remove(t);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
              crossFadeState: _showFilters
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 12),

            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),

            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results yet'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final novel = _results[index];
                        final image = (novel['coverUrl'] != null)
                            ? (novel['coverUrl'].toString().startsWith('http')
                                ? novel['coverUrl']
                                : '${ApiConfig.baseUrl}${novel['coverUrl']}')
                            : 'https://placehold.co/200x300';
                        final tags =
                            (novel['tags'] as List?)?.join(' • ') ?? '';

                        return ListTile(
                          leading: Image.network(image,
                              width: 50, fit: BoxFit.cover),
                          title: Text(novel['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                novel['author']?['name'] ?? 'Unknown Author',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (tags.isNotEmpty)
                                Text(tags,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NovelDetailsPage(novel: novel),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
