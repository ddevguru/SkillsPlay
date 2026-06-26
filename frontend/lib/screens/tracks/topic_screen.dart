import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class TopicScreen extends ConsumerWidget {
  final String trackId;
  const TopicScreen({super.key, required this.trackId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider(trackId));

    return Scaffold(
      appBar: AppBar(title: const Text('Topics & Games')),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (topics) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topics.length,
          itemBuilder: (_, i) {
            final topic = topics[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _difficultyIcon(topic.difficulty),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(topic.title, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Chip(
                          label: Text('${topic.lessonCount} games'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (topic.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(topic.description, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 8),
                    const Text('Tap a game to play:', style: TextStyle(fontWeight: FontWeight.w600)),
                    _LessonList(trackId: trackId, topicId: topic.id),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _difficultyIcon(String difficulty) {
    final color = switch (difficulty) {
      'BASICS' => Colors.green,
      'INTERMEDIATE' => Colors.orange,
      'ADVANCED' => Colors.red,
      _ => Colors.grey,
    };
    return Icon(Icons.circle, color: color, size: 12);
  }
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
          return const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator());
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
            return Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(_gameIcon(gameType), color: Theme.of(context).colorScheme.primary),
                title: Text(l['title'] as String),
                subtitle: Text('${_gameLabel(gameType)} · ${l['points']} pts'),
                trailing: const Icon(Icons.play_circle_fill),
                onTap: () => context.push('/play/${l['id']}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _gameIcon(String type) => switch (type) {
        'MICRO_LESSON' => Icons.quiz,
        'PUZZLE_DRAG_DROP' => Icons.drag_indicator,
        'PUZZLE_REORDER' => Icons.reorder,
        'CODE_COMPLETION' => Icons.code,
        'TIMED_CHALLENGE' => Icons.timer,
        'SCENARIO_SIMULATION' => Icons.psychology,
        _ => Icons.videogame_asset,
      };

  String _gameLabel(String type) => switch (type) {
        'MICRO_LESSON' => 'Quiz',
        'PUZZLE_DRAG_DROP' => 'Drag & Drop',
        'PUZZLE_REORDER' => 'Reorder',
        'CODE_COMPLETION' => 'Code',
        'TIMED_CHALLENGE' => 'Timed Code',
        'SCENARIO_SIMULATION' => 'Scenario',
        _ => type,
      };
}
