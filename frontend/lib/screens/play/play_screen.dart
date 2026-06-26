import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/socket_provider.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../services/offline_cache.dart';
import '../../widgets/clay/clay_widgets.dart';
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

  Color get _gameColor => SkillPlayTheme.gameColors[_lesson?.gameType] ?? SkillPlayTheme.primary;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ClayScaffold(body: Center(child: CircularProgressIndicator(color: SkillPlayTheme.primary)));
    }

    if (_blockReason != null) {
      return ClayScaffold(
        appBar: const ClayAppBar(title: 'Locked'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClayBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 64, color: Color(0xFFFFB347)),
                  const SizedBox(height: 16),
                  Text(_blockReason!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  ClayButton(label: 'View Plans', icon: Icons.star, onPressed: () => context.push('/subscription')),
                  TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_result != null) {
      final passed = _result!.passed;
      return ClayScaffold(
        appBar: const ClayAppBar(title: 'Results'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClayBox(
              color: passed ? const Color(0xFF6BCB77).withValues(alpha: 0.12) : const Color(0xFFFFB347).withValues(alpha: 0.12),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(passed ? '🎉' : '💪', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(passed ? 'Victory!' : 'Almost there!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Score: ${_result!.score} · XP: +${_result!.xpEarned}',
                      style: TextStyle(color: SkillPlayTheme.clayTextMuted, fontSize: 16)),
                  const SizedBox(height: 28),
                  if (widget.roomId != null)
                    ClayButton(label: 'Back to Room', onPressed: () => context.go('/multiplayer/room/${widget.roomId}'))
                  else
                    ClayButton(label: 'Continue', icon: Icons.arrow_forward, onPressed: () => context.pop()),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final lesson = _lesson!;

    return ClayScaffold(
      appBar: ClayAppBar(
        title: lesson.title,
        actions: [
          if (_remainingPlays != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gameColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('$_remainingPlays free', style: TextStyle(fontWeight: FontWeight.w700, color: _gameColor, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClayBox(
              color: _gameColor.withValues(alpha: 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _gameColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text(lesson.gameType.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _gameColor)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: SkillPlayTheme.clayTextMuted.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text(lesson.difficulty, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text('${lesson.points} pts', style: TextStyle(fontWeight: FontWeight.w800, color: _gameColor)),
                    ],
                  ),
                  if (!GameTypeId.fromString(lesson.gameType).isCoding &&
                      lesson.gameType != 'MICRO_LESSON') ...[
                    const SizedBox(height: 14),
                    Text(lesson.content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClayBox(
              inset: true,
              padding: const EdgeInsets.all(20),
              child: GameWidgetFactory(
                lesson: lesson,
                answer: _answer,
                code: _code,
                elapsedSeconds: _stopwatch.elapsed.inSeconds,
                onAnswerChanged: (v) => setState(() => _answer = v),
                onCodeChanged: (v) => setState(() => _code = v),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
            ],
            const SizedBox(height: 24),
            ClayButton(
              label: _submitting ? 'Submitting...' : 'Submit Answer',
              icon: Icons.check_circle_outline,
              color: _gameColor,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
