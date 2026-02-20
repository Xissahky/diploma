import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../widgets/report_dialog.dart';
import '../../api/report_api.dart';
import '../../l10n/app_localizations.dart';
import '../../config/api_config.dart';

class NovelCommentsSection extends StatefulWidget {
  final String novelId;
  final String? authToken;

  const NovelCommentsSection({
    super.key,
    required this.novelId,
    this.authToken,
  });

  @override
  State<NovelCommentsSection> createState() => _NovelCommentsSectionState();
}

class _NovelCommentsSectionState extends State<NovelCommentsSection> {
  List<dynamic> _comments = [];
  bool _loading = false;
  final TextEditingController _controller = TextEditingController();

  String _unknownUserLabel = 'Unknown user';

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/comments/novel/${widget.novelId}',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _comments = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendComment({String? parentId}) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/comments');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (widget.authToken != null)
            'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'content': text,
          'novelId': widget.novelId,
          if (parentId != null) 'parentId': parentId,
        }),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        _controller.clear();
        _fetchComments();
      } else {
        debugPrint(
          'Failed to send comment: ${res.statusCode} ${res.body}',
        );
      }
    } catch (e) {
      debugPrint('Error sending comment: $e');
    }
  }

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
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first.toString() +
            parts.last.characters.first.toString())
        .toUpperCase();
  }

  Widget _avatarWidget(Map<String, dynamic>? author,
      {double radius = 18}) {
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

  void _openReportDialogForComment(String commentId) {
    final s = AppLocalizations.of(context)!;

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
              SnackBar(
                content: Text('${s.failedPrefix}: $e'),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    _unknownUserLabel = s.unknownUser;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: _comments.isEmpty
              ? Center(child: Text(s.noCommentsYet))
              : ListView.builder(
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final c =
                        _comments[index] as Map<String, dynamic>;
                    final author =
                        c['author'] as Map<String, dynamic>?;
                    final name = _displayName(author);
                    final content =
                        (c['content'] ?? '') as String;
                    final replies =
                        (c['replies'] as List<dynamic>?) ??
                            const [];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _avatarWidget(author, radius: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(content),
                                    Align(
                                      alignment:
                                          Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed:
                                            widget.authToken ==
                                                    null
                                                ? null
                                                : () {
                                                    _showReplyDialog(
                                                      parentId:
                                                          c['id'],
                                                    );
                                                  },
                                        child:
                                            Text(s.replyButton),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(
                                  Icons.report,
                                  color: Colors.red,
                                ),
                                tooltip: s.reportCommentTooltip,
                                onPressed: widget.authToken == null
                                    ? null
                                    : () {
                                        _openReportDialogForComment(
                                          c['id'],
                                        );
                                      },
                              ),
                            ],
                          ),

                          if (replies.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 28,
                                top: 4,
                              ),
                              child: Column(
                                children: replies.map((r) {
                                  final rr =
                                      r as Map<String, dynamic>;
                                  final rauthor = rr['author']
                                      as Map<String, dynamic>?;
                                  final rname =
                                      _displayName(rauthor);
                                  final rcontent =
                                      (rr['content'] ?? '')
                                          as String;

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(
                                      top: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        _avatarWidget(
                                          rauthor,
                                          radius: 14,
                                        ),
                                        const SizedBox(
                                            width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                rname,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(
                                                  height: 2),
                                              Text(
                                                rcontent,
                                                style:
                                                    const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.report,
                                            color: Colors.red,
                                          ),
                                          tooltip: s
                                              .reportCommentTooltip,
                                          onPressed: widget
                                                      .authToken ==
                                                  null
                                              ? null
                                              : () {
                                                  _openReportDialogForComment(
                                                    c['id'],
                                                  );
                                                },
                                        )
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const Divider(),
                        ],
                      ),
                    );
                  },
                ),
        ),
        if (widget.authToken != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: s.writeCommentHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendComment(),
                )
              ],
            ),
          ),
      ],
    );
  }

  void _showReplyDialog({required String parentId}) {
    final s = AppLocalizations.of(context)!;

    final replyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(s.replyDialogTitle),
          content: TextField(
            controller: replyCtrl,
            decoration: InputDecoration(
              hintText: s.replyDialogHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancelButton),
            ),
            TextButton(
              onPressed: () async {
                final text = replyCtrl.text.trim();
                if (text.isNotEmpty) {
                  await _sendReply(
                    parentId: parentId,
                    text: text,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: Text(s.sendButton),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendReply({
    required String parentId,
    required String text,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/comments');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (widget.authToken != null)
            'Authorization': 'Bearer ${widget.authToken}',
        },
        body: jsonEncode({
          'content': text,
          'novelId': widget.novelId,
          'parentId': parentId,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _fetchComments();
      } else {
        debugPrint(
          'Failed to send reply: ${res.statusCode} ${res.body}',
        );
      }
    } catch (e) {
      debugPrint('Error replying: $e');
    }
  }
}
