import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/offline_cache.dart';
import '../../widgets/clay/clay_widgets.dart';

class TrackSelectionScreen extends ConsumerStatefulWidget {
  const TrackSelectionScreen({super.key});

  @override
  ConsumerState<TrackSelectionScreen> createState() => _TrackSelectionScreenState();
}

class _TrackSelectionScreenState extends ConsumerState<TrackSelectionScreen> {
  final Set<String> _selected = {};
  bool _saving = false;

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.selectTracks(_selected.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracks selected! 10 free plays per track. 🎮')),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);

    return ClayScaffold(
      appBar: const ClayAppBar(title: 'Choose Your Tracks'),
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SkillPlayTheme.primary)),
        error: (e, _) {
          final cached = OfflineCache.getCachedTracks();
          if (cached != null) {
            return _buildList(cached.map((t) => Track.fromJson(t)).toList());
          }
          return Center(child: Text('Error: $e'));
        },
        data: (tracks) {
          OfflineCache.cacheTracks(tracks.map((t) => {
            'id': t.id, 'slug': t.slug, 'title': t.title,
            'description': t.description, 'icon': t.icon,
            '_count': {'topics': t.topicCount},
          }).toList());
          return _buildList(tracks);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ClayButton(
            label: _saving ? 'Saving...' : 'Continue (${_selected.length} selected)',
            icon: Icons.rocket_launch,
            loading: _saving,
            onPressed: _selected.isEmpty || _saving ? null : _save,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Track> tracks) {
    final colors = [SkillPlayTheme.primary, SkillPlayTheme.secondary, SkillPlayTheme.accent, const Color(0xFF6BCB77)];
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tracks.length,
      itemBuilder: (_, i) {
        final track = tracks[i];
        final selected = _selected.contains(track.id);
        final accent = colors[i % colors.length];
        return ClayBox(
          margin: const EdgeInsets.only(bottom: 12),
          color: selected ? accent.withValues(alpha: 0.15) : accent.withValues(alpha: 0.06),
          onTap: () => setState(() {
            if (selected) {
              _selected.remove(track.id);
            } else {
              _selected.add(track.id);
            }
          }),
          child: Row(
            children: [
              Text(track.icon ?? '📚', style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(track.description, style: TextStyle(color: SkillPlayTheme.clayTextMuted, fontSize: 13)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? accent : SkillPlayTheme.clayTextMuted,
                size: 28,
              ),
            ],
          ),
        );
      },
    );
  }
}
