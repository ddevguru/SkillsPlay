import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/providers.dart';
import '../../providers/socket_provider.dart';

class MultiplayerRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const MultiplayerRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends ConsumerState<MultiplayerRoomScreen> {
  Map<String, dynamic>? _room;
  bool _loading = true;
  bool _ready = false;
  final Map<String, bool> _playerReady = {};
  final Map<String, int> _playerProgress = {};
  final Map<String, int> _playerScores = {};
  String? _error;
  String? _statusMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadRoom();
    await _connectSocket();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadRoom(silent: true));
  }

  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    final socket = ref.read(socketServiceProvider);
    await socket.connect(token);
    socket.joinRoom(widget.roomId);

    socket.on('player:joined', (data) {
      if (mounted) {
        setState(() => _statusMessage = 'Player joined the room');
        _loadRoom(silent: true);
      }
    });
    socket.on('player:ready', (data) {
      final map = data as Map;
      if (mounted) {
        setState(() => _playerReady[map['userId']] = map['ready'] == true);
      }
    });
    socket.on('player:progress', (data) {
      final map = data as Map;
      if (mounted) {
        setState(() => _playerProgress[map['userId']] = (map['progress'] as num?)?.toInt() ?? 0);
      }
    });
    socket.on('player:submitted', (data) {
      final map = data as Map;
      if (mounted) {
        setState(() {
          _playerScores[map['userId']] = (map['score'] as num?)?.toInt() ?? 0;
          _statusMessage = 'Opponent submitted!';
        });
      }
    });
    socket.on('room:started', (_) {
      if (mounted) {
        setState(() => _statusMessage = 'Match started!');
        _loadRoom(silent: true);
      }
    });
    socket.on('room:finished', (data) {
      if (mounted) {
        final winners = (data as Map)['winners'] as List? ?? [];
        setState(() => _statusMessage = winners.isEmpty ? 'Match ended in a tie' : 'Winner decided!');
        _loadRoom(silent: true);
      }
    });
  }

  Future<void> _loadRoom({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final room = await ref.read(apiServiceProvider).getRoom(widget.roomId);
      if (mounted) setState(() => _room = room);
    } catch (e) {
      if (mounted && !silent) setState(() => _error = 'Failed to load room');
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _toggleReady() async {
    setState(() => _ready = !_ready);
    ref.read(socketServiceProvider).setReady(widget.roomId, _ready);
  }

  Future<void> _startMatch() async {
    try {
      await ref.read(apiServiceProvider).startRoom(widget.roomId);
      await _loadRoom(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot start: $e')));
      }
    }
  }

  Future<void> _submitDemoScore() async {
    const score = 85;
    ref.read(socketServiceProvider).submitScore(widget.roomId, score);
    setState(() => _playerScores[_myUserId ?? ''] = score);
    try {
      await ref.read(apiServiceProvider).finishRoom(widget.roomId, {_myUserId!: score});
      await _loadRoom(silent: true);
    } catch (_) {}
  }

  String? get _myUserId => ref.read(authStateProvider).valueOrNull?.id;

  bool get _isHost {
    if (_room == null || _myUserId == null) return false;
    return _room!['hostId'] == _myUserId;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    ref.read(socketServiceProvider).leaveRoom(widget.roomId);
    ref.read(socketServiceProvider).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Room not found')),
      );
    }

    final participants = (_room!['participants'] as List?) ?? [];
    final status = _room!['status'] as String? ?? 'WAITING';
    final roomCode = _room!['roomCode'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('Room $roomCode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(status == 'IN_PROGRESS' ? Icons.play_circle : Icons.hourglass_empty),
              title: Text('Status: $status'),
              subtitle: Text(_statusMessage ?? 'Waiting for players...'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Players (${participants.length}/${_room!['maxPlayers'] ?? 2})',
              style: Theme.of(context).textTheme.titleMedium),
          ...participants.map((p) {
            final user = p['user'] as Map?;
            final uid = user?['id'] as String? ?? p['userId'] as String;
            final name = user?['name'] as String? ?? 'Player';
            final isMe = uid == _myUserId;
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                title: Text(isMe ? '$name (you)' : name),
                subtitle: Text(
                  'Ready: ${_playerReady[uid] == true ? 'Yes' : 'No'} · '
                  'Progress: ${_playerProgress[uid] ?? 0}% · '
                  'Score: ${_playerScores[uid] ?? p['score'] ?? 0}',
                ),
                trailing: p['isWinner'] == true ? const Icon(Icons.emoji_events, color: Colors.amber) : null,
              ),
            );
          }),
          const SizedBox(height: 24),
          if (status == 'WAITING') ...[
            if (_isHost && participants.length >= 2)
              FilledButton(onPressed: _startMatch, child: const Text('Start Match'))
            else if (_isHost)
              const Text('Waiting for opponent to join...', textAlign: TextAlign.center),
            OutlinedButton(
              onPressed: _toggleReady,
              child: Text(_ready ? 'Not Ready' : 'Ready Up'),
            ),
          ],
          if (status == 'IN_PROGRESS') ...[
            FilledButton(
              onPressed: () {
                ref.read(socketServiceProvider).sendProgress(widget.roomId, 50);
                _submitDemoScore();
              },
              child: const Text('Submit Score (Demo)'),
            ),
          ],
          if (status == 'COMPLETED')
            FilledButton(onPressed: () => context.go('/leaderboard'), child: const Text('View Leaderboard')),
        ],
      ),
    );
  }
}
