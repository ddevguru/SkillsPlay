import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: lbAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No rankings yet. Be the first!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: i < 3 ? Colors.amber : null,
                    child: Text('#${e.rank}'),
                  ),
                  title: Text(e.name),
                  subtitle: Text('${e.xp} XP'),
                  trailing: Text('${e.score} pts', style: Theme.of(context).textTheme.titleMedium),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
