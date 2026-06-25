import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class MultiplayerScreen extends ConsumerStatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  ConsumerState<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends ConsumerState<MultiplayerScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _roomCode;
  String? _error;

  Future<void> _createRoom() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null && !user.hasSubscription) {
      setState(() => _error = 'Multiplayer requires an active subscription');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final room = await api.createRoom();
      setState(() => _roomCode = room['roomCode'] as String);
    } catch (e) {
      setState(() => _error = e.toString().contains('402') ? 'Subscription required' : 'Failed to create room');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.length != 6) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final room = await api.joinRoom(_codeCtrl.text.trim());
      setState(() => _roomCode = room['roomCode'] as String);
    } catch (e) {
      setState(() => _error = 'Failed to join room');
    } finally {
      setState(() => _loading = false);
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
      appBar: AppBar(title: const Text('Multiplayer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.groups, size: 64),
            const SizedBox(height: 16),
            Text('1v1 Duels', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Challenge a friend or join matchmaking',
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            if (_roomCode != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text('Room Code'),
                      const SizedBox(height: 8),
                      Text(_roomCode!, style: Theme.of(context).textTheme.headlineLarge?.copyWith(letterSpacing: 4)),
                      const SizedBox(height: 16),
                      const Text('Share this code with your opponent'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: _loading ? null : _createRoom,
                icon: const Icon(Icons.add),
                label: const Text('Create Room'),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Room Code',
                  border: OutlineInputBorder(),
                  hintText: 'ABCDEF',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _loading ? null : _joinRoom, child: const Text('Join Room')),
            ],
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
