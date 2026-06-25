import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/offline_cache.dart';

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
          const SnackBar(content: Text('Tracks selected! 10 free plays per track.')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Tracks')),
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selected.isEmpty || _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Continue (${_selected.length} selected)'),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<Track> tracks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (_, i) {
        final track = tracks[i];
        final selected = _selected.contains(track.id);
        return Card(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
          child: CheckboxListTile(
            value: selected,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selected.add(track.id);
              } else {
                _selected.remove(track.id);
              }
            }),
            secondary: Text(track.icon ?? '📚', style: const TextStyle(fontSize: 32)),
            title: Text(track.title),
            subtitle: Text(track.description),
          ),
        );
      },
    );
  }
}
