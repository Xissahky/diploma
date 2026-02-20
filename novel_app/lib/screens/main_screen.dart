import 'package:flutter/material.dart';
import '../api/novels_api.dart';
import '../api/auth_api.dart';
import './novel_details.dart';
import 'sign_in_page.dart';
import '../l10n/app_localizations.dart';
import '../../config/api_config.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _HomeData {
  final Map<String, dynamic> sections;
  final bool isAuthed;
  _HomeData(this.sections, this.isAuthed);
}

class _MainScreenState extends State<MainScreen> {
  late Future<_HomeData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_HomeData> _load() async {
    final sections = await NovelsApi.fetchSections();
    final isAuthed = await AuthApi.isLoggedIn();
    return _HomeData(sections, isAuthed);
  }

  Future<void> _reloadHome() async {
  setState(() {
    _dataFuture = _load(); 
  });
  }


  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return FutureBuilder<_HomeData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text('${s.errorPrefix}: ${snapshot.error}'),
          );
        } else if (!snapshot.hasData) {
          return Center(child: Text(s.noData));
        }

        final data = snapshot.data!;
        final popular = (data.sections['popular'] as List?) ?? [];
        final topRated = (data.sections['topRated'] as List?) ?? [];
        final recommended = (data.sections['recommended'] as List?) ?? [];

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (popular.isNotEmpty)
              _SectionRow(
                title: s.homePopularNowTitle,
                subtitle: s.homePopularNowSubtitle,
                items: popular,
              ),
            if (topRated.isNotEmpty)
              _SectionRow(
                title: s.homeTopRatedTitle,
                subtitle: s.homeTopRatedSubtitle,
                items: topRated,
              ),
            if (data.isAuthed && recommended.isNotEmpty)
              _SectionRow(
                title: s.homeRecommendedTitle,
                subtitle: s.homeRecommendedSubtitle,
                items: recommended,
              ),
            if (!data.isAuthed)
              _LoginCta(
                onLoggedIn: _reloadHome,
              ),

          ],
        );
      },
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<dynamic> items;

  const _SectionRow({
    required this.title,
    required this.items,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              subtitle!,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          height: 290,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final n = items[i] as Map<String, dynamic>;
              return _NovelCard(novel: n);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NovelCard extends StatelessWidget {
  final Map<String, dynamic> novel;
  const _NovelCard({required this.novel});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final title = novel['title'] ?? s.untitledNovel;
    final rating = (novel['rating'] as num?)?.toDouble() ?? 0.0;
    final recentViews = (novel['recentViews'] as num?)?.toInt();
    final cover = (() {
      final u = (novel['coverUrl'] ?? '') as String;
      if (u.isEmpty) {
        return 'https://placehold.co/400x600?text=No+Image';
      }
      return u.startsWith('http')
        ? u
        : '${ApiConfig.baseUrl}$u';

    })();

    return GestureDetector(
      onTap: () async {
        await NovelsApi.recordView(novel['id']);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NovelDetailsPage(novel: novel),
            ),
          );
        }
      },
      child: SizedBox(
        width: 150,
        child: Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (recentViews != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.trending_up,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$recentViews',
                            style:
                                const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginCta extends StatelessWidget {
  final VoidCallback onLoggedIn;

  const _LoginCta({
    required this.onLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.lock_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.loginCtaText,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignInPage(),
                    ),
                  );

                  if (result == true) {
                    onLoggedIn();
                  }

                },
                child: Text(s.loginCtaButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
