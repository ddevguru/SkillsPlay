import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../clay/clay_widgets.dart';

class CodeChallengeWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final String content;
  final bool timed;
  final int elapsedSeconds;
  final ValueChanged<String> onCodeChanged;

  const CodeChallengeWidget({
    super.key,
    required this.config,
    required this.content,
    this.timed = false,
    this.elapsedSeconds = 0,
    required this.onCodeChanged,
  });

  @override
  State<CodeChallengeWidget> createState() => _CodeChallengeWidgetState();
}

class _CodeChallengeWidgetState extends State<CodeChallengeWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.config['starterCode'] as String? ?? '',
    );
    _controller.addListener(() => widget.onCodeChanged(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.config['language'] as String? ?? 'python';
    final timeLimit = widget.config['timeLimitSeconds'] as int? ?? 300;
    final accent = widget.timed ? const Color(0xFFFF6B6B) : SkillPlayTheme.secondary;
    final timeRatio = (widget.elapsedSeconds / timeLimit).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.timed) ...[
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text('${widget.elapsedSeconds}s / ${timeLimit}s', style: TextStyle(fontWeight: FontWeight.w800, color: accent)),
              const Spacer(),
              Text('${(timeRatio * 100).toInt()}%', style: TextStyle(color: SkillPlayTheme.clayTextMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: timeRatio,
              minHeight: 8,
              color: timeRatio > 0.8 ? const Color(0xFFFF6B6B) : accent,
              backgroundColor: accent.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 14, color: accent),
                  const SizedBox(width: 4),
                  Text(language.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: accent)),
                ],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                _controller.text = widget.config['starterCode'] as String? ?? '';
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClayBox(
          inset: true,
          padding: const EdgeInsets.all(4),
          child: TextField(
            controller: _controller,
            maxLines: 16,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Write your $language solution...',
              filled: false,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }
}
