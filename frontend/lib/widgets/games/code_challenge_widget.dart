import 'package:flutter/material.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.timed) ...[
          Row(
            children: [
              const Icon(Icons.timer, size: 18),
              const SizedBox(width: 6),
              Text('${widget.elapsedSeconds}s / ${timeLimit}s'),
              const Spacer(),
              LinearProgressIndicator(
                value: (widget.elapsedSeconds / timeLimit).clamp(0.0, 1.0),
                minHeight: 6,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Chip(label: Text(language.toUpperCase()), avatar: const Icon(Icons.code, size: 16)),
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
        TextField(
          controller: _controller,
          maxLines: 16,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Write your $language solution...',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
