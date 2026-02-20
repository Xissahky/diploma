import 'package:flutter/material.dart';
import '../../api/library_api.dart';
import '../../screens/novel_reader_page.dart';
import '../../l10n/app_localizations.dart';
import '../../config/api_config.dart';

class ProfileLibrarySection extends StatefulWidget {
  const ProfileLibrarySection({super.key});

  @override
  State<ProfileLibrarySection> createState() =>
      _ProfileLibrarySectionState();
}

class _ProfileLibrarySectionState extends State<ProfileLibrarySection> {
  final List<String> categories = const [
    'ALL',
    'READING',
    'PLANNED',
    'ON_HOLD',
    'DROPPED',
    'COMPLETED',
    'FAVORITES',
  ];

  String selected = 'ALL';
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (selected == 'ALL') {
        final statuses = ['READING', 'PLANNED', 'ON_HOLD', 'DROPPED', 'COMPLETED'];
        final futures = statuses.map((s) => LibraryApi.myLibrary(status: s));
        final lists = await Future.wait(futures);
        items = lists.expand((e) => e).toList();
      } else if (selected == 'FAVORITES') {
        final all = await LibraryApi.myLibrary();
        items = all.where((e) => (e['favorite'] == true)).toList();
      } else {
        items = await LibraryApi.myLibrary(status: selected);
      }
      setState(() {});
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  String _statusLabel(AppLocalizations s, String code) {
    switch (code) {
      case 'READING':
        return s.libStatusReading;
      case 'PLANNED':
        return s.libStatusPlanned;
      case 'ON_HOLD':
        return s.libStatusOnHold;
      case 'DROPPED':
        return s.libStatusDropped;
      case 'COMPLETED':
        return s.libStatusCompleted;
      case 'FAVORITES':
        return s.libStatusFavorites;
      case 'ALL':
      default:
        return s.libStatusAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = categories[i];
              final sel = c == selected;
              final label = _statusLabel(s, c);
              return ChoiceChip(
                label: Text(label),
                selected: sel,
                onSelected: (_) {
                  setState(() => selected = c);
                  _load();
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text('Error: $error'))
                  : items.isEmpty
                      ? Center(child: Text(s.noNovelsInCategory))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final e = items[i];
                            final novel = e['novel'] ?? {};
                            final title =
                                novel['title'] ?? s.untitledNovel;
                            final author = novel['author']?['name'] ??
                                s.unknownAuthor;
                            final coverUrl = novel['coverUrl'] ?? '';
                            final image =
                                coverUrl.toString().startsWith('http')
                                    ? coverUrl
                                    : '${ApiConfig.baseUrl}$coverUrl';
                            final statusCode = e['status'] ?? '';
                            final fav = e['favorite'] == true;

                            final statusLabel =
                                _statusLabel(s, statusCode.toString());

                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image,
                                  width: 48,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(title),
                              subtitle: Text('$author • $statusLabel'),
                              trailing: fav
                                  ? const Icon(Icons.favorite,
                                      color: Colors.pink)
                                  : null,
                              onTap: () {
                                final novel = e['novel'] ?? {};
                                if (novel.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          NovelReaderPage(novel: novel),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
