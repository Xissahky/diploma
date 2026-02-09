import 'package:flutter/material.dart';

import 'novel_details/novel_info_section.dart';
import 'novel_details/novel_chapters_section.dart';
import 'novel_details/novel_comments_section.dart';
import '../storage/auth_storage.dart';
import '../l10n/app_localizations.dart';

class NovelDetailsPage extends StatefulWidget {
  final Map<String, dynamic> novel;

  const NovelDetailsPage({super.key, required this.novel});

  @override
  State<NovelDetailsPage> createState() => _NovelDetailsPageState();
}

class _NovelDetailsPageState extends State<NovelDetailsPage> {
  int _selectedTab = 0;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await AuthStorage.getToken();
    if (!mounted) return;
    setState(() => _authToken = token);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final title = widget.novel['title'] ?? s.unknownNovel;
    final cover = (widget.novel['coverUrl'] != null)
        ? (widget.novel['coverUrl'].toString().startsWith('http')
            ? widget.novel['coverUrl']
            : 'http://10.0.2.2:3000${widget.novel['coverUrl']}')
        : 'https://placehold.co/300x400';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: s.backTooltip,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  cover,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton(s.novelTabInfo, 0),
                _buildTabButton(s.novelTabChapters, 1),
                _buildTabButton(s.novelTabComments, 2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final bool selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.blueAccent : Colors.grey.shade300,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.blueAccent : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (_selectedTab) {
      case 0:
        return NovelInfoSection(
          key: const ValueKey(0),
          novel: widget.novel,
        );
      case 1:
        return NovelChaptersSection(
          key: const ValueKey(1),
          novel: widget.novel,
        );
      case 2:
      default:
        return NovelCommentsSection(
          key: const ValueKey(2),
          novelId: widget.novel['id'],
          authToken: _authToken,
        );
    }
  }
}
