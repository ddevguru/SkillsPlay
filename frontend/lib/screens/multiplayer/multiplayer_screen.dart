import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class MultiplayerScreen extends ConsumerStatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  ConsumerState<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends ConsumerState<MultiplayerScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _lessons = [];
  String? _selectedLessonId;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final data = await ref.read(apiServiceProvider).getPlayableLessons();
      if (mounted) {
        setState(() {
          _lessons = data.cast<Map<String, dynamic>>();
          if (_lessons.isNotEmpty) _selectedLessonId = _lessons.first['id'] as String;
        });
      }
    } catch (_) {}
  }

  Future<void> _createRoom() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null && !user.hasSubscription) {
      setState(() => _error = 'Play with Friends requires Basic plan (demo account has it)');
      return;
    }
    if (_selectedLessonId == null) {
      setState(() => _error = 'Select a game challenge first');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final room = await api.createRoom(lessonId: _selectedLessonId);
      if (mounted) context.push('/multiplayer/room/${room['id']}');
    } catch (e) {
      setState(() => _error = e.toString().contains('402') ? 'Subscription required' : 'Failed to create room');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.length != 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final room = await api.joinRoom(_codeCtrl.text.trim());
      if (mounted) context.push('/multiplayer/room/${room['id']}');
    } catch (e) {
      setState(() => _error = 'Failed to join room — check code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Play with Friends')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.groups_2, size: 64),
            const SizedBox(height: 16),
            Text('Challenge a Friend', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Like Ludo — create a room, share the code, both play the same game. Highest score wins!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (_lessons.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _selectedLessonId,
                decoration: const InputDecoration(
                  labelText: 'Choose Game Challenge',
                  border: OutlineInputBorder(),
                ),
                items: _lessons.map((l) {
                  final topic = l['topic'] as Map?;
                  final track = topic?['track'] as Map?;
                  final label = '${track?['title'] ?? ''} · ${topic?['title'] ?? ''} · ${l['title']}';
                  return DropdownMenuItem(value: l['id'] as String, child: Text(label, overflow: TextOverflow.ellipsis));
                }).toList(),
                onChanged: (v) => setState(() => _selectedLessonId = v),
              ),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: _loading ? null : _createRoom,
              icon: const Icon(Icons.add),
              label: const Text('Create Room & Get Code'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Friend\'s Room Code',
                border: OutlineInputBorder(),
                hintText: 'ABCDEF',
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(6)],
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _loading ? null : _joinRoom, child: const Text('Join Friend\'s Room')),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
            ],
            if (_loading) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}
