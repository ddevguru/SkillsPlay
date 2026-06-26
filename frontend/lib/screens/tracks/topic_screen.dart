import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/clay/clay_widgets.dart';

class TopicScreen extends ConsumerWidget {
  final String trackId;
  const TopicScreen({super.key, required this.trackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider(trackId));

    return ClayScaffold(
      appBar: ClayAppBar(title: 'Topics & Games'),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SkillPlayTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (topics) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: topics.length,
          itemBuilder: (_, i) {
            final topic = topics[i];
            final accent = _difficultyColor(topic.difficulty);
            return ClayBox(
              margin: const EdgeInsets.only(bottom: 16),
              color: accent.withValues(alpha: 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(topic.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text('${topic.lessonCount} games', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                      ),
                    ],
                  ),
                  if (topic.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(topic.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SkillPlayTheme.clayTextMuted)),
                  ],
                  const SizedBox(height: 12),
                  _LessonList(trackId: trackId, topicId: topic.id),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _difficultyColor(String difficulty) => switch (difficulty) {
        'BASICS' => const Color(0xFF6BCB77),
        'INTERMEDIATE' => const Color(0xFFFFB347),
        'ADVANCED' => const Color(0xFFFF6B6B),
        _ => SkillPlayTheme.primary,
      };
}

class _LessonList extends ConsumerWidget {
  final String trackId;
  final String topicId;

  const _LessonList({required this.trackId, required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(apiServiceProvider).getTopicLessons(trackId, topicId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator(color: SkillPlayTheme.primary));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Padding(padding: EdgeInsets.all(8), child: Text('Failed to load games'));
        }
        final lessons = snapshot.data!;
        if (lessons.isEmpty) {
          return const Padding(padding: EdgeInsets.all(8), child: Text('No games yet — admin can add from panel'));
        }
        return Column(
          children: lessons.map((l) {
            final gameType = l['gameType'] as String;
            final accent = SkillPlayTheme.gameColors[gameType] ?? SkillPlayTheme.primary;
            return ClayGameCard(
              title: l['title'] as String,
              subtitle: '${_gameLabel(gameType)} · ${l['points']} pts',
              icon: _gameIcon(gameType),
              accent: accent,
              badge: _gameBadge(gameType),
              onTap: () => context.push('/play/${l['id']}'),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _gameIcon(String type) => switch (type) {
        'MICRO_LESSON' => Icons.auto_stories,
        'PUZZLE_DRAG_DROP' => Icons.extension,
        'PUZZLE_REORDER' => Icons.sort,
        'CODE_COMPLETION' => Icons.terminal,
        'TIMED_CHALLENGE' => Icons.bolt,
        'SCENARIO_SIMULATION' => Icons.psychology_alt,
        _ => Icons.videogame_asset,
      };

  String _gameLabel(String type) => switch (type) {
        'MICRO_LESSON' => 'Concept Quest',
        'PUZZLE_DRAG_DROP' => 'Match Maker',
        'PUZZLE_REORDER' => 'Step Master',
        'CODE_COMPLETION' => 'Code Quest',
        'TIMED_CHALLENGE' => 'Speed Code',
        'SCENARIO_SIMULATION' => 'Real World',
        _ => type,
      };

  String? _gameBadge(String type) => switch (type) {
        'TIMED_CHALLENGE' => '⚡ FAST',
        'SCENARIO_SIMULATION' => '🧠 THINK',
        'CODE_COMPLETION' => '💻 CODE',
        _ => null,
      };
}
