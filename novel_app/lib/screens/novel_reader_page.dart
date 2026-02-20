import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'novel_details.dart';
import '../theme/reader_themes.dart';
import '../storage/auth_storage.dart';
import '../widgets/report_dialog.dart';
import '../api/report_api.dart';
import '../l10n/app_localizations.dart';
import '../config/api_config.dart';


class NovelReaderPage extends StatefulWidget {
  final Map<String, dynamic> novel;
  final Map<String, dynamic>? initialChapter;

  const NovelReaderPage({
    super.key,
    required this.novel,
    this.initialChapter,
  });

  @override
  State<NovelReaderPage> createState() => _NovelReaderPageState();
}

class _NovelReaderPageState extends State<NovelReaderPage> {
  Map<String, dynamic>? _currentChapter;
  List<dynamic> _chapters = [];
  bool _loading = true;
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  late ReaderTheme _currentTheme;



  List<dynamic> _comments = [];
  bool _loadingComments = false;
  String? _authToken;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();


  String _unknownUserLabel = 'Unknown user';
  String _noContentLabel = 'No content available';

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'label': 'English'},
    {'code': 'pl', 'label': 'Polski'},
    {'code': 'uk', 'label': 'Українська'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'zh', 'label': '中文'},
  ];
  String _targetLang = 'en';
  bool _showTranslated = false;
  bool _translating = false;
  final Map<String, String> _translationCache = {};

  @override
  void initState() {
    super.initState();
    _currentTheme = ReaderThemes.themes.first;
    _initPage();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }


  Future<void> _initPage() async {
    final token = await AuthStorage.getToken();
    setState(() {
      _authToken = token;
    });
    await _fetchChapters();
  }

  Future<void> _fetchChapters() async {
    final novelId = widget.novel['id'];
    final uri = Uri.parse('${ApiConfig.baseUrl}/novels/$novelId');

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final novelData = jsonDecode(res.body);
        final chapters = novelData['chapters'] as List<dynamic>? ?? [];

        setState(() {
          _chapters = chapters;

          if (chapters.isEmpty) {
            _currentChapter = null;
            _loading = false;
            return;
          }

          if (widget.initialChapter != null) {
            final match = chapters.firstWhere(
              (c) => c['id'] == widget.initialChapter!['id'],
              orElse: () => chapters.first,
            );
            _currentChapter = match;
          } else {
            _currentChapter = chapters.first;
          }

          _loading = false;
        });

        if (_currentChapter != null) {
          _fetchCommentsForChapter(_currentChapter!['id']);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error fetching chapters: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchCommentsForChapter(String chapterId) async {
    setState(() => _loadingComments = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/comments/chapter/$chapterId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _comments = data is List ? data : [];
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      setState(() => _loadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final s = AppLocalizations.of(context)!;

    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.mustBeLoggedInToComment)),
      );
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final chapterId = _currentChapter?['id'];
    if (chapterId == null) return;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/comments');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'content': text,
          'chapterId': chapterId,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _commentController.clear();
        _fetchCommentsForChapter(chapterId);
      } else {
        debugPrint('Failed to send comment: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Error sending comment: $e');
    }
  }

  int get _currentIndex {
    if (_currentChapter == null) return -1;
    final id = _currentChapter!['id'];
    return _chapters.indexWhere((c) => c['id'] == id);
  }

  bool get _hasPrev => _currentIndex > 0;
  bool get _hasNext =>
      _currentIndex >= 0 && _currentIndex < _chapters.length - 1;

  void _goToPrevChapter() {
    if (!_hasPrev) return;
    setState(() {
      _currentChapter = _chapters[_currentIndex - 1];
    });
    _scrollToTop();
    _fetchCommentsForChapter(_currentChapter!['id']);
    _maybePrefetchTranslation();
  }

  void _goToNextChapter() {
    if (_hasNext) {
      setState(() {
        _currentChapter = _chapters[_currentIndex + 1];
      });
      _scrollToTop();
      _fetchCommentsForChapter(_currentChapter!['id']);
      _maybePrefetchTranslation();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NovelDetailsPage(novel: widget.novel),
        ),
      );
    }
  }

  void _maybePrefetchTranslation() {
    if (!_showTranslated || _currentChapter == null) return;
    final chapterId = _currentChapter!['id'] as String;
    final key = '$chapterId:$_targetLang';
    if (_translationCache.containsKey(key)) return;
    _translateCurrentChapter(showSnackbars: false);
  }

  // === Translation helpers ===

  String _getDisplayedContent() {
    final original = _currentChapter?['content'] ?? _noContentLabel;
    if (!_showTranslated || _currentChapter == null) return original;
    final chapterId = _currentChapter!['id'] as String;
    final key = '$chapterId:$_targetLang';
    final translated = _translationCache[key];
    return translated ?? original;
  }

  Future<void> _translateCurrentChapter({bool showSnackbars = true}) async {
    final s = AppLocalizations.of(context)!;

    if (_currentChapter == null) return;
    final chapterId = _currentChapter!['id'] as String;
    final key = '$chapterId:$_targetLang';
    if (_translationCache.containsKey(key)) {
      setState(() {}); // already in cashe
      return;
    }

    setState(() => _translating = true);
    try {
      Uri uri = Uri.parse('${ApiConfig.baseUrl}/translate/chapter');
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };
      String body =
          jsonEncode({'chapterId': chapterId, 'targetLang': _targetLang});

      http.Response res = await http.post(uri, headers: headers, body: body);

      if (res.statusCode == 404) {
        final original = _currentChapter?['content'] ?? '';
        uri = Uri.parse('${ApiConfig.baseUrl}/translate/text');
        body = jsonEncode({'text': original, 'targetLang': _targetLang});
        res = await http.post(uri, headers: headers, body: body);
      }

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final text = (data is Map && data['text'] is String)
            ? data['text'] as String
            : null;
        if (text != null && text.trim().isNotEmpty) {
          _translationCache[key] = text;
          setState(() {});
          if (showSnackbars) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${s.translatedToPrefix} ${_langLabel(_targetLang)}',
                ),
              ),
            );
          }
        } else {
          if (showSnackbars) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.emptyTranslation)),
            );
          }
        }
      } else {
        if (showSnackbars) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${s.translationFailedPrefix}: ${res.statusCode}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (showSnackbars) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.translationErrorPrefix}: $e')),
        );
      }
    } finally {
      setState(() => _translating = false);
    }
  }

  String _langLabel(String code) =>
      _languages
          .firstWhere(
            (l) => l['code'] == code,
            orElse: () => const {'label': 'Unknown'},
          )['label'] ??
      code;

  void _openChapterSelector() {
    final s = AppLocalizations.of(context)!;

    if (_chapters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    s.chapterListTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _chapters.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ch = _chapters[index];
                      final title =
                          ch['title'] ?? '${s.chapterWord} ${index + 1}';
                      final isCurrent = _currentChapter?['id'] == ch['id'];
                      return ListTile(
                        leading: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent
                                ? Colors.blueAccent
                                : Colors.grey.shade700,
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color:
                                isCurrent ? Colors.blueAccent : Colors.black,
                          ),
                        ),
                        onTap: () {
                          setState(() => _currentChapter = ch);
                          Navigator.pop(context);
                          _fetchCommentsForChapter(ch['id']);
                          _maybePrefetchTranslation();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSettingsMenu() {
    final s = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        double tempFontSize = _fontSize;
        String tempLang = _targetLang;
        bool tempShowTranslated = _showTranslated;
        double tempLineHeight = _lineHeight;


        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottom = MediaQuery.of(context).viewInsets.bottom;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            s.readingSettingsTitle,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Font size
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.fontSizeLabel,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setModalState(() {
                                      tempFontSize =
                                          (tempFontSize - 1).clamp(12.0, 28.0);
                                    });
                                    setState(() => _fontSize = tempFontSize);
                                  },
                                ),
                                Text(
                                  '${tempFontSize.toInt()}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setModalState(() {
                                      tempFontSize =
                                          (tempFontSize + 1).clamp(12.0, 28.0);
                                    });
                                    setState(() => _fontSize = tempFontSize);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Line height
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.lineHeightLabel,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    setModalState(() {
                                      tempLineHeight =
                                          (tempLineHeight - 0.1).clamp(1.2, 2.4);
                                    });
                                    setState(() => _lineHeight = tempLineHeight);
                                  },
                                ),
                                Text(
                                  tempLineHeight.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    setModalState(() {
                                      tempLineHeight =
                                          (tempLineHeight + 0.1).clamp(1.2, 2.4);
                                    });
                                    setState(() => _lineHeight = tempLineHeight);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        Text(
                          s.translationSectionTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<String>(
                          value: tempLang,
                          items: _languages
                              .map((l) => DropdownMenuItem(
                                    value: l['code'],
                                    child: Text(l['label']!),
                                  ))
                              .toList(),
                          decoration: InputDecoration(
                            labelText: s.targetLanguageLabel,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => tempLang = v);
                            setState(() => _targetLang = v);
                          },
                        ),
                        const SizedBox(height: 8),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.showTranslatedText),
                          value: tempShowTranslated,
                          onChanged: (v) async {
                            setModalState(() => tempShowTranslated = v);
                            setState(() => _showTranslated = v);
                            if (v) {
                              await _translateCurrentChapter();
                            }
                          },
                        ),

                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: _translating
                                  ? null
                                  : () async {
                                      await _translateCurrentChapter();
                                      setModalState(
                                          () => tempShowTranslated = true);
                                      setState(
                                          () => _showTranslated = true);
                                    },
                              icon: _translating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.translate),
                              label: Text(s.translateNowButton),
                            ),
                            const SizedBox(width: 12),
                            if (_showTranslated)
                              Text(
                                '${s.showingPrefix} ${_langLabel(_targetLang)}',
                                style:
                                    const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),

                        const Divider(height: 24),

                        Text(
                          s.themeLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        DropdownButtonFormField<ReaderTheme>(
                          value: _currentTheme,
                          items: ReaderThemes.themes
                              .map(
                                (theme) => DropdownMenuItem(
                                  value: theme,
                                  child: Text(theme.name),
                                ),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (theme) {
                            if (theme == null) return;
                            setState(() => _currentTheme = theme);
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(s.closeButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openReportDialogForChapter(String? chapterId) {
    final s = AppLocalizations.of(context)!;

    if (chapterId == null) return;

    showDialog(
      context: context,
      builder: (_) => ReportDialog(
        onSubmit: (reason, description) async {
          try {
            await ReportApi.sendReport(
              targetType: "CHAPTER",
              targetId: chapterId,
              reason: reason,
              description: description,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.chapterReported)),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${s.errorPrefix}: $e')),
            );
          }
        },
      ),
    );
  }

  void _openReportDialogForComment(String commentId) {
    final s = AppLocalizations.of(context)!;

    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.mustBeLoggedInToReport)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ReportDialog(
        onSubmit: (reason, description) async {
          try {
            await ReportApi.sendReport(
              targetType: "COMMENT",
              targetId: commentId,
              reason: reason,
              description: description,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.commentReported)),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${s.errorPrefix}: $e')),
            );
          }
        },
      ),
    );
  }

  // ====== helpers for comments: name/initials/avatar ======
  String _displayName(Map<String, dynamic>? author) {
    if (author == null) return _unknownUserLabel;
    final displayName =
        author['displayName'] ?? author['username'] ?? author['name'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }

    final email = author['email'] as String?;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first;
      if (local.isNotEmpty) return local;
    }
    return _unknownUserLabel;
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return (s.characters.take(2).toString()).toUpperCase();
    }
    return (parts.first.characters.first.toString() +
            parts.last.characters.first.toString())
        .toUpperCase();
  }

  Widget _avatarWidget(Map<String, dynamic>? author,
      {double radius = 16}) {
    final name = _displayName(author);
    final avatarUrl =
        (author?['avatarUrl'] ?? author?['avatar'] ?? author?['imageUrl'])
            as String?;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: Container(),
      );
    }
    return CircleAvatar(
      radius: radius,
      child: Text(_initials(name)),
    );
  }
  // ========================================================
  
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }


  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    _unknownUserLabel = s.unknownUser;
    _noContentLabel = s.noContentAvailable;

    final novelTitle = widget.novel['title'] ?? s.unknownNovel;
    final chapterTitle = _currentChapter?['title'] ?? s.noChapters;
    final displayedContent = _getDisplayedContent();

    return Scaffold(
      backgroundColor: _currentTheme.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    color: _currentTheme.headerColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                novelTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                chapterTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.list_alt_outlined),
                          tooltip: s.chaptersTooltip,
                          onPressed: _openChapterSelector,
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          tooltip: s.textSettingsTooltip,
                          onPressed: _openSettingsMenu,
                        ),
                        IconButton(
                          icon: const Icon(Icons.report, color: Colors.red),
                          tooltip: s.reportChapterTooltip,
                          onPressed: _authToken == null
                              ? null
                              : () {
                                  _openReportDialogForChapter(
                                      _currentChapter?['id']);
                                },
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: _currentTheme.dividerColor,
                  ),

                  // Content + badges
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showTranslated)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.translate, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _translating
                                        ? '${s.translatingToPrefix} ${_langLabel(_targetLang)}…'
                                        : '${s.translatedToPrefix} ${_langLabel(_targetLang)}',
                                    style: TextStyle(
                                      color: _translating
                                          ? Colors.orange
                                          : Colors.green,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            displayedContent,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: _lineHeight,
                              color: _currentTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Prev / Next
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed:
                                      _hasPrev ? _goToPrevChapter : null,
                                  child: Text(
                                    _hasPrev
                                        ? s.previousChapter
                                        : s.noPreviousChapter,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _chapters.isEmpty
                                      ? null
                                      : _goToNextChapter,
                                  child: Text(
                                    _hasNext
                                        ? s.nextChapter
                                        : s.backToNovel,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Comments
                          Text(
                            s.commentsTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _currentTheme.secondaryTextColor,

                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_loadingComments)
                            const Center(child: CircularProgressIndicator())
                          else if (_comments.isEmpty)
                            Text(
                              s.noCommentsYet,
                              style: TextStyle(color: _currentTheme.textColor),
                            )
                          else
                            ListView.builder(
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final c =
                                    _comments[index] as Map<String, dynamic>;
                                final author =
                                    c['author'] as Map<String, dynamic>?;
                                final name = _displayName(author);
                                final content =
                                    (c['content'] ?? '') as String;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _avatarWidget(author, radius: 16),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style:
                                                        const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(content),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.report,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints(),
                                        tooltip:
                                            s.reportCommentTooltip,
                                        onPressed: _authToken == null
                                            ? null
                                            : () =>
                                                _openReportDialogForComment(
                                                    c['id'] as String),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 12),

                          if (_authToken != null)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: s.writeCommentHint,
                                      isDense: true,
                                      border:
                                          const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: _sendComment,
                                ),
                              ],
                            )
                          else
                            Text(
                              s.loginToComment,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
