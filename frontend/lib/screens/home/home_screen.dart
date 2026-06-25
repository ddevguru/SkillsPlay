import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/xp_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final tracksAsync = ref.watch(tracksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillPlay'),
        actions: [
          if (user != null) XpBadge(xp: user.xp),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/profile')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tracksProvider);
          await ref.read(authStateProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hey, ${user.name}!', style: Theme.of(context).textTheme.titleLarge),
                            Text('${user.subscriptionStatus} plan', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(icon: Icons.add_road, label: 'Add Tracks', onTap: () => context.push('/tracks/select')),
                _ActionChip(icon: Icons.leaderboard, label: 'Leaderboard', onTap: () => context.push('/leaderboard')),
                _ActionChip(icon: Icons.groups, label: 'Multiplayer', onTap: () => context.push('/multiplayer')),
                if (user != null && !user.hasSubscription)
                  _ActionChip(icon: Icons.star, label: 'Subscribe', onTap: () => context.push('/subscription')),
              ],
            ),
            const SizedBox(height: 24),
            Text('Your Tracks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            tracksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Failed to load tracks: $e'),
              data: (tracks) => Column(
                children: tracks.map((track) => Card(
                  child: ListTile(
                    leading: Text(track.icon ?? '📚', style: const TextStyle(fontSize: 28)),
                    title: Text(track.title),
                    subtitle: Text('${track.topicCount} topics'),
                    trailing: track.isPremium ? const Chip(label: Text('PRO')) : null,
                    onTap: () => context.push('/tracks/${track.id}'),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Tracks'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard), label: 'Ranks'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.push('/tracks/select');
            case 2: context.push('/leaderboard');
            case 3: context.push('/profile');
          }
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
