import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/clay/clay_widgets.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(leaderboardProvider);

    return ClayScaffold(
      appBar: const ClayAppBar(title: 'Leaderboard'),
      body: lbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SkillPlayTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No rankings yet. Be the first! 🏆'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '#${e.rank}';
              final accent = i < 3 ? const Color(0xFFFFB347) : SkillPlayTheme.primary;
              return ClayBox(
                margin: const EdgeInsets.only(bottom: 10),
                color: accent.withValues(alpha: i < 3 ? 0.1 : 0.05),
                child: Row(
                  children: [
                    SizedBox(width: 40, child: Text(medal, style: TextStyle(fontSize: i < 3 ? 24 : 14, fontWeight: FontWeight.w800))),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          Text('${e.xp} XP', style: TextStyle(color: SkillPlayTheme.clayTextMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${e.score} pts', style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
