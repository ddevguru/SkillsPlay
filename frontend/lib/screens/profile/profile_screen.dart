import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../widgets/xp_badge.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(radius: 48, child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 36))),
                      const SizedBox(height: 12),
                      Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                      Text(user.email),
                      const SizedBox(height: 8),
                      XpBadge(xp: user.xp),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Subscription'),
                  subtitle: Text(user.subscriptionStatus),
                  trailing: user.hasSubscription ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.chevron_right),
                  onTap: () => context.push('/subscription'),
                ),
                ListTile(
                  leading: const Icon(Icons.leaderboard),
                  title: const Text('Leaderboard'),
                  onTap: () => context.push('/leaderboard'),
                ),
                ListTile(
                  leading: const Icon(Icons.groups),
                  title: const Text('Multiplayer'),
                  onTap: () => context.push('/multiplayer'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
    );
  }
}
