import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/novels_api.dart';
import './novel_details.dart';
import '../l10n/app_localizations.dart';
import '../config/api_config.dart';

enum CreateMode { novel, chapter }

class NewContentPage extends StatefulWidget {
  const NewContentPage({
    super.key,
    this.initialMode = CreateMode.novel,
    this.preselectedNovel,
  });

  final CreateMode initialMode;
  final Map<String, dynamic>? preselectedNovel;

  @override
  State<NewContentPage> createState() => _NewContentPageState();
}

class _NewContentPageState extends State<NewContentPage> {
  CreateMode _mode = CreateMode.novel;

  // --- Novel form ---
  final _novelTitleCtrl = TextEditingController();
  final _novelDescCtrl = TextEditingController();
  List<String> _allTags = [];
  final Set<String> _selectedTags = {};
  File? _coverLocalFile;
  String? _coverUrlRemote;
  bool _loadingTags = false;

  // --- Chapter form ---
  final _chapterTitleCtrl = TextEditingController();
  final _chapterContentCtrl = TextEditingController();
  final _novelSearchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  Map<String, dynamic>? _selectedNovel;
  bool _searching = false;

  bool _submitting = false;
  bool _tagsLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_tagsLoadedOnce) {
      _tagsLoadedOnce = true;
      _loadTags();
    }
  }

  @override
  void dispose() {
    _novelTitleCtrl.dispose();
    _novelDescCtrl.dispose();
    _chapterTitleCtrl.dispose();
    _chapterContentCtrl.dispose();
    _novelSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    setState(() => _loadingTags = true);
    try {
      final tags = await NovelsApi.fetchAllTags();
      if (!mounted) return;
      setState(() => _allTags = tags);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tags: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingTags = false);
    }
  }


  Future<void> _pickCover() async {
    final s = AppLocalizations.of(context)!;

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _coverLocalFile = File(picked.path));
    try {
      final url = await NovelsApi.uploadImage(_coverLocalFile!);
      setState(() => _coverUrlRemote = url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.coverUploaded)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.uploadFailedPrefix}: $e')),
      );
    }
  }

  Future<void> _searchNovels() async {
    final s = AppLocalizations.of(context)!;

    final q = _novelSearchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final items = await NovelsApi.searchNovelsSimple(q);
      setState(() => _searchResults = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.searchFailedPrefix}: $e')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submitNovel() async {
    final s = AppLocalizations.of(context)!;

    final title = _novelTitleCtrl.text.trim();
    final desc = _novelDescCtrl.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.novelFillTitleAndDescription)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final created = await NovelsApi.createNovel(
        title: title,
        description: desc,
        coverUrl: _coverUrlRemote,
        tags: _selectedTags.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.novelCreated)),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NovelDetailsPage(novel: created)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.createNovelFailedPrefix}: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitChapter() async {
    final s = AppLocalizations.of(context)!;

    if (_selectedNovel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pickNovelFirst)),
      );
      return;
    }
    final title = _chapterTitleCtrl.text.trim();
    final content = _chapterContentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.chapterFillTitleAndContent)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await NovelsApi.addChapter(
        novelId: _selectedNovel!['id'],
        title: title,
        content: content,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.chapterAdded)),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NovelDetailsPage(novel: _selectedNovel!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.addChapterFailedPrefix}: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final submitEnabled = !_submitting;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.createTitle),
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<CreateMode>(
              segments: [
                ButtonSegment(
                  value: CreateMode.novel,
                  icon: const Icon(Icons.menu_book),
                  label: Text(s.createModeNovel),
                ),
                ButtonSegment(
                  value: CreateMode.chapter,
                  icon: const Icon(Icons.article),
                  label: Text(s.createModeChapter),
                ),
              ],
              selected: <CreateMode>{_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _mode == CreateMode.novel
                    ? _buildNovelForm(context)
                    : _buildChapterForm(context),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: !submitEnabled
                ? null
                : (_mode == CreateMode.novel
                    ? _submitNovel
                    : _submitChapter),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_mode == CreateMode.novel
                    ? s.createNovelButton
                    : s.addChapterButton),
          ),
        ),
      ),
    );
  }

  // ----------------- Novel form -----------------
  Widget _buildNovelForm(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final coverPreview = _coverUrlRemote != null
        ? (_coverUrlRemote!.startsWith('http')
            ? _coverUrlRemote!
            : '${ApiConfig.baseUrl}$_coverUrlRemote')
        : null;

    return Column(
      key: const ValueKey('novel_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _novelTitleCtrl,
          decoration: InputDecoration(
            labelText: s.novelTitleLabel,
            hintText: s.novelTitleHint,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _novelDescCtrl,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: s.novelDescriptionLabel,
            hintText: s.novelDescriptionHint,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickCover,
              icon: const Icon(Icons.photo),
              label: Text(s.uploadCoverButton),
            ),
            const SizedBox(width: 12),
            if (coverPreview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  coverPreview,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          s.tagsLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_loadingTags)
          const LinearProgressIndicator()
        else if (_allTags.isEmpty)
          Text(s.noTags)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allTags.map((t) {
              final selected = _selectedTags.contains(t);
              return FilterChip(
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedTags.add(t);
                    } else {
                      _selectedTags.remove(t);
                    }
                  });
                },
                label: Text(t),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        Text(
          _selectedTags.isEmpty
              ? s.noTagsSelected
              : '${s.tagsSelectedPrefix} ${_selectedTags.join(', ')}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // ----------------- Chapter form -----------------
  Widget _buildChapterForm(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final selectedTitle = _selectedNovel?['title'] as String?;
    final selectedCover = (() {
      final u = _selectedNovel?['coverUrl'] as String?;
      if (u == null || u.isEmpty) return null;
      return u.startsWith('http') ? u : '${ApiConfig.baseUrl}$u';
    })();

    return Column(
      key: const ValueKey('chapter_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.selectNovelTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _novelSearchCtrl,
                decoration: InputDecoration(
                  hintText: s.searchNovelHint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchNovels,
                  ),
                ),
                onSubmitted: (_) => _searchNovels(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_searching) const LinearProgressIndicator(),
        if (_selectedNovel != null) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: selectedCover != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      selectedCover,
                      height: 48,
                      width: 36,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.book_outlined),
            title: Text(selectedTitle ?? ''),
            subtitle: Text(s.selectedNovelSubtitle),
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedNovel = null),
            ),
          ),
          const Divider(),
        ],
        if (_searchResults.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.resultsTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ..._searchResults.map((n) {
                final t = (n['title'] ?? '') as String;
                final cover = (() {
                  final u = (n['coverUrl'] ?? '') as String;
                  if (u.isEmpty) return null;
                  return u.startsWith('http')
                      ? u
                      : '${ApiConfig.baseUrl}$u';
                })();
                return ListTile(
                  dense: true,
                  leading: cover != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            cover,
                            height: 44,
                            width: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.menu_book),
                  title: Text(
                    t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedNovel = n as Map<String, dynamic>;
                      _searchResults = [];
                      _novelSearchCtrl.clear();
                    });
                  },
                );
              }),
              const Divider(),
            ],
          ),
        TextField(
          controller: _chapterTitleCtrl,
          decoration: InputDecoration(
            labelText: s.chapterTitleLabel,
            hintText: s.chapterTitleHint,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chapterContentCtrl,
          maxLines: 12,
          decoration: InputDecoration(
            labelText: s.chapterContentLabel,
            hintText: s.chapterContentHint,
          ),
        ),
      ],
    );
  }
}
