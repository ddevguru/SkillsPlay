import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/clay/clay_widgets.dart';
import '../../widgets/xp_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final tracksAsync = ref.watch(tracksProvider);

    return ClayScaffold(
      appBar: ClayAppBar(
        title: 'SkillPlay',
        actions: [
          if (user != null) Padding(padding: const EdgeInsets.only(right: 8), child: XpBadge(xp: user.xp)),
          IconButton(
            icon: const Icon(Icons.person_outline, color: SkillPlayTheme.clayText),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tracksProvider);
          await ref.read(authStateProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (user != null)
              ClayBox(
                color: SkillPlayTheme.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [SkillPlayTheme.primary, SkillPlayTheme.accent]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: SkillPlayTheme.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hey, ${user.name}! 👋', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          Text('${user.subscriptionStatus} plan · Keep the streak alive!', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SkillPlayTheme.clayTextMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text('Quick Play', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ClayChip(icon: Icons.add_road, label: 'Add Tracks', color: SkillPlayTheme.primary, onTap: () => context.push('/tracks/select')),
                ClayChip(icon: Icons.leaderboard, label: 'Leaderboard', color: SkillPlayTheme.secondary, onTap: () => context.push('/leaderboard')),
                ClayChip(icon: Icons.groups, label: 'Multiplayer', color: SkillPlayTheme.accent, onTap: () => context.push('/multiplayer')),
                if (user != null && !user.hasSubscription)
                  ClayChip(icon: Icons.star, label: 'Go Pro', color: const Color(0xFFFFB347), onTap: () => context.push('/subscription')),
              ],
            ),
            const SizedBox(height: 28),
            Text('Your Tracks', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            tracksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: SkillPlayTheme.primary)),
              error: (e, _) => ClayBox(child: Text('Failed to load tracks: $e')),
              data: (tracks) => Column(
                children: tracks.map((track) {
                  final colors = [SkillPlayTheme.primary, SkillPlayTheme.secondary, SkillPlayTheme.accent, const Color(0xFF6BCB77)];
                  final accent = colors[tracks.indexOf(track) % colors.length];
                  return ClayBox(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: accent.withValues(alpha: 0.08),
                    onTap: () => context.push('/tracks/${track.id}'),
                    child: Row(
                      children: [
                        Text(track.icon ?? '📚', style: const TextStyle(fontSize: 36)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(track.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              Text('${track.topicCount} topics · Tap to play', style: TextStyle(color: SkillPlayTheme.clayTextMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                        if (track.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFFB347).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                            child: const Text('PRO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFE67E22))),
                          ),
                        const Icon(Icons.chevron_right, color: SkillPlayTheme.clayTextMuted),
                      ],
                    ),
                  );
                }).toList(),
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
