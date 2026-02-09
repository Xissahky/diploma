import 'package:flutter/material.dart';
import '../novel_reader_page.dart';
import '../../api/ratings_api.dart';
import '../../storage/auth_storage.dart';
import '../../widgets/star_rating.dart';
import '../../l10n/app_localizations.dart';
import '../../api/library_api.dart';


class NovelInfoSection extends StatefulWidget {
  final Map<String, dynamic> novel;
  const NovelInfoSection({super.key, required this.novel});

  @override
  State<NovelInfoSection> createState() => _NovelInfoSectionState();
}

class _NovelInfoSectionState extends State<NovelInfoSection> {
  double _average = 0.0;
  int _myValue = 0;
  bool _loadingRating = true;
  bool _setting = false;
  bool _authed = false;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    final id = widget.novel['id'] as String?;
    if (id == null) return;

    final token = await AuthStorage.getToken();
    setState(() => _authed = token != null);

    try {
      final avg = await RatingsApi.getAverage(id);
      int my = 0;
      if (token != null) {
        final mine = await RatingsApi.getMyRating(id);
        my = (mine?['value'] as int?) ?? 0;
      }
      setState(() {
        _average = avg;
        _myValue = my;
        _loadingRating = false;
      });
    } catch (_) {
      setState(() => _loadingRating = false);
    }
  }

  Future<void> _setRating(int v) async {
    final s = AppLocalizations.of(context)!;

    if (!_authed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loginToRate)),
      );
      return;
    }
    final id = widget.novel['id'] as String?;
    if (id == null) return;

    setState(() => _setting = true);
    try {
      final res = await RatingsApi.setMyRating(id, v);
      setState(() {
        _myValue = v;
        _average =
            (res['average'] as num?)?.toDouble() ?? _average;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.ratingSaved)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.failedPrefix}: $e'),
        ),
      );
    } finally {
      setState(() => _setting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final novel = widget.novel;
    final title = novel['title'] ?? s.unknownNovel;
    final description =
        novel['description'] ?? s.noDescriptionAvailable;
    final author =
        novel['author']?['name'] ?? s.unknownAuthor;
    final tags =
        (novel['tags'] as List?)?.join(', ') ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.person,
                size: 18,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                author,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loadingRating)
            const SizedBox(
              height: 36,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Row(
              children: [
                StarRating(
                  value: _myValue,
                  average: _average,
                  readOnly: _setting,
                  onChanged: _setRating,
                ),
                if (!_authed)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '(${s.loginToRate})',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 12),

          if (tags.isNotEmpty) ...[
            Text(
              s.tagsLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .split(',')
                  .map((t) => Chip(label: Text(t.trim())))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          Text(
            s.descriptionLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final token = await AuthStorage.getToken();
                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.addToLibraryInfo)),
                      );
                      return;
                    }

                    final novelId = widget.novel['id'];
                    if (novelId == null) return;

                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (ctx) {
                        return Padding(
                          padding: const EdgeInsets.all(8),
                          child: _StatusPicker(
                            initial: 'PLANNED',
                            onChanged: (status) async {
                              Navigator.pop(ctx);

                              try {
                                await LibraryApi.upsert(
                                  novelId,
                                  status: status,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(s.addToLibraryButton)),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${s.failedPrefix}: $e')),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.library_add),
                  label: Text(s.addToLibraryButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            NovelReaderPage(novel: novel),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book),
                  label: Text(s.readNowButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final String initial;
  final ValueChanged<String> onChanged;

  const _StatusPicker({
    required this.initial,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final statuses = const [
      'PLANNED',
      'READING',
      'ON_HOLD',
      'DROPPED',
      'COMPLETED',
    ];

    String labelFor(String status) {
      switch (status) {
        case 'PLANNED':
          return s.statusPlanned;
        case 'READING':
          return s.statusReading;
        case 'ON_HOLD':
          return s.statusOnHold;
        case 'DROPPED':
          return s.statusDropped;
        case 'COMPLETED':
          return s.statusCompleted;
        default:
          return status;
      }
    }

    return Column(
      children: statuses.map((sCode) {
        return RadioListTile<String>(
          value: sCode,
          groupValue: initial,
          title: Text(labelFor(sCode)),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        );
      }).toList(),
    );
  }
}
