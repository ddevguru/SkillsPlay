import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/offline_cache.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const PlayScreen({super.key, required this.lessonId});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  String? _attemptId;
  Lesson? _lesson;
  int? _remainingPlays;
  final _codeCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  PlayResult? _result;
  String? _error;
  String? _blockReason;
  final _stopwatch = Stopwatch();

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
      _stopwatch.start();
      await OfflineCache.cacheLesson(widget.lessonId, data['lesson'] as Map<String, dynamic>);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('402') || msg.contains('FREE_PLAYS')) {
        _blockReason = 'Free plays exhausted. Subscribe to continue!';
      } else {
        final cached = OfflineCache.getCachedLesson(widget.lessonId);
        if (cached != null) {
          _lesson = Lesson.fromJson(cached);
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
    try {
      final api = ref.read(apiServiceProvider);
      final isCode = _lesson!.gameType.contains('CODE') || _lesson!.gameType.contains('TIMED');
      final data = await api.submitPlay(
        attemptId: _attemptId!,
        answer: isCode ? null : _answerCtrl.text,
        code: isCode ? _codeCtrl.text : null,
        language: isCode ? (_lesson!.configJson['language'] as String? ?? 'python') : null,
        timeSeconds: _stopwatch.elapsed.inSeconds,
      );
      setState(() => _result = PlayResult.fromJson(data));
      ref.read(authStateProvider.notifier).refresh();
    } catch (e) {
      await OfflineCache.queueAttempt({
        'attemptId': _attemptId,
        'lessonId': widget.lessonId,
        'answer': _answerCtrl.text,
        'code': _codeCtrl.text,
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
    _codeCtrl.dispose();
    _answerCtrl.dispose();
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
              FilledButton(onPressed: () => context.pop(), child: const Text('Continue')),
            ],
          ),
        ),
      );
    }

    final lesson = _lesson!;
    final isCode = lesson.gameType.contains('CODE') || lesson.gameType.contains('TIMED');

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
                    const SizedBox(height: 12),
                    Text(lesson.content, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isCode) ...[
              Text('Your Code', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _codeCtrl,
                maxLines: 12,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: lesson.configJson['starterCode'] as String? ?? 'Write your solution...',
                ),
              ),
            ] else ...[
              Text('Your Answer', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _answerCtrl,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter answer'),
              ),
            ],
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
