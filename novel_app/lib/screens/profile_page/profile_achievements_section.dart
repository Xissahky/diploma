import 'package:flutter/material.dart';
import '../../api/achievements_api.dart';
import '../../l10n/app_localizations.dart';

class ProfileAchievementsSection extends StatefulWidget {
  const ProfileAchievementsSection({super.key});

  @override
  State<ProfileAchievementsSection> createState() =>
      _ProfileAchievementsSectionState();
}

class _ProfileAchievementsSectionState
    extends State<ProfileAchievementsSection> {
  bool loading = true;
  String? error;
  List<dynamic> all = [];
  Set<String> unlockedCodes = {};

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
      final allList = await AchievementsApi.allAchievements();
      final mine = await AchievementsApi.myAchievements();
      all = allList;
      unlockedCodes = mine
          .map((ua) => ua['achievement']?['code'] as String?)
          .whereType<String>()
          .toSet();
      setState(() {});
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    if (all.isEmpty) {
      return Center(child: Text(s.noAchievementsDefined));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = all[i];
        final code = a['code'] as String? ?? '';
        final title = a['title'] ?? s.achievementDefaultTitle;
        final desc = a['description'] ?? '';
        final pts = a['points']?.toString() ?? '0';
        final unlocked = unlockedCodes.contains(code);

        final color = unlocked ? null : Colors.grey.shade400;
        final iconColor = unlocked ? Colors.amber : Colors.grey;

        return Opacity(
          opacity: unlocked ? 1.0 : 0.6,
          child: Card(
            color: color,
            child: ListTile(
              leading: Icon(Icons.emoji_events, color: iconColor),
              title: Text(title),
              subtitle: Text(desc),
              trailing: Text('$pts ${s.pointsShort}'),
            ),
          ),
        );
      },
    );
  }
}
