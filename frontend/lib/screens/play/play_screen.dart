import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/socket_provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/offline_cache.dart';
import '../../widgets/games/game_types.dart';
import '../../widgets/games/game_widget_factory.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String? roomId;
  const PlayScreen({super.key, required this.lessonId, this.roomId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  String? _attemptId;
  Lesson? _lesson;
  int? _remainingPlays;
  dynamic _answer;
  String _code = '';
  bool _loading = true;
  bool _submitting = false;
  PlayResult? _result;
  String? _error;
  String? _blockReason;
  final _stopwatch = Stopwatch();
  Timer? _timerTick;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  Future<void> _startGame() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.startPlay(widget.lessonId);
      _attemptId = data['attemptId'] as String;
      _lesson = Lesson.fromJson(data['lesson'] as Map<String, dynamic>);
      _remainingPlays = data['remainingFreePlays'] as int?;
      _code = _lesson!.configJson['starterCode'] as String? ?? '';
      _stopwatch.start();
      if (GameTypeId.fromString(_lesson!.gameType) == GameTypeId.timedChallenge) {
        _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
      await OfflineCache.cacheLesson(widget.lessonId, data['lesson'] as Map<String, dynamic>);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('402') || msg.contains('FREE_PLAYS')) {
        _blockReason = 'Free plays exhausted. Subscribe to continue!';
      } else {
        final cached = OfflineCache.getCachedLesson(widget.lessonId);
        if (cached != null) {
          _lesson = Lesson.fromJson(cached);
          _code = _lesson!.configJson['starterCode'] as String? ?? '';
        } else {
          _error = 'Failed to start game';
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_attemptId == null || _lesson == null) return;
    setState(() => _submitting = true);
    _stopwatch.stop();
    _timerTick?.cancel();
    try {
      final api = ref.read(apiServiceProvider);
      final type = GameTypeId.fromString(_lesson!.gameType);
      final data = await api.submitPlay(
        attemptId: _attemptId!,
        answer: type.isCoding ? null : _answer,
        code: type.isCoding ? _code : null,
        language: type.isCoding ? (_lesson!.configJson['language'] as String? ?? 'python') : null,
        timeSeconds: _stopwatch.elapsed.inSeconds,
      );
      setState(() => _result = PlayResult.fromJson(data));
      ref.read(authStateProvider.notifier).refresh();
      if (widget.roomId != null) {
        final uid = ref.read(authStateProvider).valueOrNull?.id;
        final score = _result!.score;
        if (uid != null) {
          ref.read(socketServiceProvider).submitScore(widget.roomId!, score);
          await api.finishRoom(widget.roomId!, {uid: score});
        }
      }
    } catch (e) {
      await OfflineCache.queueAttempt({
        'attemptId': _attemptId,
        'lessonId': widget.lessonId,
        'answer': _answer,
        'code': _code,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved offline — will sync when online')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _timerTick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_blockReason != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(_blockReason!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 24),
                FilledButton(onPressed: () => context.push('/subscription'), child: const Text('View Plans')),
                TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
              ],
            ),
          ),
        ),
      );
    }

    if (_result != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_result!.passed ? Icons.celebration : Icons.replay, size: 80,
                  color: _result!.passed ? Colors.green : Colors.orange),
              const SizedBox(height: 16),
              Text(_result!.passed ? 'Victory!' : 'Keep practicing!',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Score: ${_result!.score} · XP: +${_result!.xpEarned}'),
              const SizedBox(height: 24),
              if (widget.roomId != null)
                FilledButton(
                  onPressed: () => context.go('/multiplayer/room/${widget.roomId}'),
                  child: const Text('Back to Room'),
                )
              else
                FilledButton(onPressed: () => context.pop(), child: const Text('Continue')),
            ],
          ),
        ),
      );
    }

    final lesson = _lesson!;

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        actions: [
          if (_remainingPlays != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(label: Text('$_remainingPlays free plays')),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(label: Text(lesson.gameType.replaceAll('_', ' '))),
                        const SizedBox(width: 8),
                        Chip(label: Text(lesson.difficulty)),
                        const Spacer(),
                        Text('${lesson.points} pts'),
                      ],
                    ),
                    if (!GameTypeId.fromString(lesson.gameType).isCoding &&
                        lesson.gameType != 'MICRO_LESSON') ...[
                      const SizedBox(height: 12),
                      Text(lesson.content, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GameWidgetFactory(
              lesson: lesson,
              answer: _answer,
              code: _code,
              elapsedSeconds: _stopwatch.elapsed.inSeconds,
              onAnswerChanged: (v) => setState(() => _answer = v),
              onCodeChanged: (v) => setState(() => _code = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
