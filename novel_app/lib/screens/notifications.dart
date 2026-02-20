import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/notifications_api.dart';
import 'novel_reader_page.dart';
import 'profile_page.dart';
import '../settings/settings_controller.dart';
import '../l10n/app_localizations.dart';
import '../config/api_config.dart';

class NotificationsPage extends StatefulWidget {
  final SettingsController settings;

  const NotificationsPage({
    super.key,
    required this.settings,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const String _base = '${ApiConfig.baseUrl}';

  bool unreadOnly = true;
  bool loading = true;
  String? error;

  List<dynamic> _all = [];
  List<dynamic> _view = [];
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isRead(Map n) {
    final r = n['isRead'];
    if (r is bool) return r == true;
    if (n['read'] is bool) return n['read'] == true;
    if (n['status'] is String) {
      return (n['status'] as String).toUpperCase() == 'READ';
    }
    return false;
  }

  void _recompute() {
    unreadCount = _all.where((n) => !_isRead(n as Map)).length;
    if (unreadOnly) {
      _view = _all.where((n) => !_isRead(n as Map)).toList();
    } else {
      _view = List.of(_all);
    }
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final all = await NotificationsApi.list(unreadOnly: false);
      _all = all;
      _recompute();
      setState(() {});
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _markRead(String id) async {
    final s = AppLocalizations.of(context)!;

    try {
      await NotificationsApi.markRead(id);
      final idx = _all.indexWhere((n) => n['id'] == id);
      if (idx != -1) _all[idx]['isRead'] = true;
      _recompute();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.failedPrefix}: $e')),
      );
    }
  }

  Future<void> _markAll() async {
    final s = AppLocalizations.of(context)!;

    if (unreadCount == 0) return;
    try {
      await NotificationsApi.markAllRead();
      for (final n in _all) {
        n['isRead'] = true;
      }
      _recompute();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.failedPrefix}: $e')),
      );
    }
  }

  String _coverFromPayload(Map payload) {
    final candidates = <String>['novelCoverUrl', 'coverUrl', 'image', 'thumbnail'];
    for (final k in candidates) {
      final v = payload[k];
      if (v is String && v.trim().isNotEmpty) {
        final val = v.trim();
        if (val.startsWith('http')) return val;
        final fixed = val.startsWith('/') ? val : '/$val';
        return '$_base$fixed';
      }
    }
    return '';
  }

  Widget _buildLeading(BuildContext context, Map payload, String type) {
    final cs = Theme.of(context).colorScheme;

    if (type == 'CHAPTER_PUBLISHED') {
      final image = _coverFromPayload(payload);
      return SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: image.isNotEmpty
              ? Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.secondaryContainer,
                    child: const Center(child: Icon(Icons.menu_book)),
                  ),
                )
              : Container(
                  color: cs.secondaryContainer,
                  child: const Center(child: Icon(Icons.menu_book)),
                ),
        ),
      );
    }

    if (type == 'COMMENT_REPLY') {
      final avatar = (() {
        final v = payload['authorAvatar'];
        if (v is String && v.trim().isNotEmpty) {
          final val = v.trim();
          if (val.startsWith('http')) return val;
          final fixed = val.startsWith('/') ? val : '/$val';
          return '$_base$fixed';
        }
        return '';
      })();

      return CircleAvatar(
        radius: 24,
        backgroundColor: cs.secondaryContainer,
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        onBackgroundImageError: (_, __) {},
        child: avatar.isEmpty ? const Icon(Icons.person) : null,
      );
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Icon(Icons.notifications, color: cs.primary),
      ),
    );
  }

  Future<void> _openNotification(Map<String, dynamic> n) async {
    final s = AppLocalizations.of(context)!;

    final type = (n['type'] ?? '').toString();
    final payload = (n['payload'] as Map?) ?? {};

    if (type == 'CHAPTER_PUBLISHED') {
      final novelId = payload['novelId']?.toString();
      final chapterId = payload['chapterId']?.toString();
      if (novelId == null || chapterId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.notificationMissingIds)),
        );
        return;
      }

      try {
        final uri = Uri.parse('$_base/novels/$novelId');
        final res = await http.get(uri);
        if (res.statusCode != 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${s.notificationFailedLoadNovel}: ${res.statusCode}',
              ),
            ),
          );
          return;
        }
        final novel = jsonDecode(res.body) as Map<String, dynamic>;
        final chapters = (novel['chapters'] as List?) ?? [];

        final target = chapters.cast<Map>().firstWhere(
              (c) => c['id'] == chapterId,
              orElse: () => {},
            );

        if (target.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.notificationChapterNotFound)),
          );
          return;
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NovelReaderPage(
              novel: novel,
              initialChapter: target as Map<String, dynamic>,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.openErrorPrefix}: $e')),
        );
      }
      return;
    }

    if (type == 'ACHIEVEMENT_UNLOCKED') {
      if (!mounted) return;
      try {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              initialTab: 2,
              settings: widget.settings,
            ),
          ),
        );
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(
              settings: widget.settings,
            ),
          ),
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final title =
        unreadOnly ? s.notificationsTitleUnread : s.notificationsTitleAll;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                unreadOnly = !unreadOnly;
                _recompute();
              });
            },
            child: Text(
              unreadOnly
                  ? s.notificationsFilterUnread
                  : s.notificationsFilterAll,
              style: TextStyle(color: cs.primary),
            ),
          ),
          IconButton(
            tooltip: unreadCount > 0
                ? s.notificationsMarkAllTooltip
                : s.notificationsAllReadTooltip,
            onPressed: unreadCount > 0 ? _markAll : null,
            icon: Icon(
              unreadCount > 0
                  ? Icons.mark_email_unread
                  : Icons.mark_email_read,
              color: cs.primary,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('${s.errorPrefix}: $error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _view.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(child: Text(s.noNotifications)),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _view.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final n = _view[i] as Map<String, dynamic>;
                            final type = (n['type'] ?? '').toString();
                            final isRead = _isRead(n);
                            final payload = (n['payload'] as Map?) ?? {};
                            final created = (n['createdAt']?.toString() ?? '')
                                .split('T')
                                .first;

                            late String cardTitle;
                            late String subtitle;

                            if (type == 'CHAPTER_PUBLISHED') {
                              final novelTitle =
                                  payload['novelTitle'] ??
                                      s.notificationDefaultNovelTitle;
                              final chapterTitle =
                                  payload['chapterTitle'] ??
                                      s.notificationDefaultChapterTitle;
                              cardTitle =
                                  '${s.notificationNewChapterPrefix}: $chapterTitle';
                              subtitle = '$novelTitle • $created';
                            } else if (type == 'COMMENT_REPLY') {
                              final authorName =
                                  payload['authorName'] ?? 'User';
                              final text = payload['text'] ??
                                  s.notificationReplyDefaultText;
                              cardTitle =
                                  '$authorName ${s.notificationReplySuffix}';
                              subtitle = '$text • $created';
                            } else if (type == 'ACHIEVEMENT_UNLOCKED') {
                              final aTitle =
                                  payload['title'] ??
                                      s.notificationAchievementUnlockedTitle;
                              final desc = payload['description'] ?? '';
                              cardTitle = aTitle;
                              subtitle = '$desc • $created';
                            } else {
                              cardTitle = s.notificationDefaultTitle;
                              subtitle = created;
                            }

                            return Card(
                              elevation: isRead ? 0 : 1.5,
                              child: ListTile(
                                onTap: () => _openNotification(n),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                leading: _buildLeading(context, payload, type),
                                title: Text(
                                  cardTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                trailing: isRead
                                    ? Icon(
                                        Icons.done,
                                        size: 20,
                                        color: cs.outline,
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.mark_email_read,
                                          size: 20,
                                        ),
                                        color: cs.primary,
                                        tooltip:
                                            s.notificationMarkAsReadButton,
                                        onPressed: () =>
                                            _markRead(n['id'] as String),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
