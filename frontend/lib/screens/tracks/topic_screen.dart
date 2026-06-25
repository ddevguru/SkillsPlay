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
      appBar: AppBar(title: const Text('Topics')),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (topics) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: topics.length,
          itemBuilder: (_, i) {
            final topic = topics[i];
            return Card(
              child: ExpansionTile(
                leading: _difficultyIcon(topic.difficulty),
                title: Text(topic.title),
                subtitle: Text('${topic.lessonCount} lessons · ${topic.difficulty}'),
                children: [
                  _LessonList(trackId: trackId, topicId: topic.id),
                ],
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
          return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Padding(padding: EdgeInsets.all(16), child: Text('Failed to load lessons'));
        }
        final lessons = snapshot.data!;
        return Column(
          children: lessons.map((l) => ListTile(
            title: Text(l['title'] as String),
            subtitle: Text('${l['gameType']} · ${l['points']} pts'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () => context.push('/play/${l['id']}'),
          )).toList(),
        );
      },
    );
  }
}
