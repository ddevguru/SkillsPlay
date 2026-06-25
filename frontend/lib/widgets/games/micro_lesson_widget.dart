import 'package:flutter/material.dart';

class MicroLessonWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final String content;
  final ValueChanged<dynamic> onAnswerChanged;

  const MicroLessonWidget({
    super.key,
    required this.config,
    required this.content,
    required this.onAnswerChanged,
  });

  @override
  State<MicroLessonWidget> createState() => _MicroLessonWidgetState();
}

class _MicroLessonWidgetState extends State<MicroLessonWidget> {
  int _slideIndex = 0;
  String? _selected;

  List<Map<String, dynamic>> get _slides {
    final raw = widget.config['slides'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [{'title': 'Lesson', 'body': widget.content}];
  }

  Map<String, dynamic>? get _quiz {
    final q = widget.config['quiz'];
    return q is Map ? Map<String, dynamic>.from(q) : null;
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    final onLastSlide = _slideIndex >= slides.length - 1;
    final quiz = _quiz;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: (_slideIndex + 1) / slides.length),
        const SizedBox(height: 16),
        if (!onLastSlide || quiz == null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slides[_slideIndex]['title'] ?? 'Slide ${_slideIndex + 1}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(slides[_slideIndex]['body'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_slideIndex > 0)
                OutlinedButton(onPressed: () => setState(() => _slideIndex--), child: const Text('Back'))
              else
                const SizedBox(),
              FilledButton(
                onPressed: () => setState(() => _slideIndex++),
                child: Text(onLastSlide && quiz != null ? 'Take Quiz' : 'Next'),
              ),
            ],
          ),
        ],
        if (onLastSlide && quiz != null) ...[
          Text(quiz['question'] ?? 'Quick check', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...(quiz['options'] as List? ?? ['Yes']).map((opt) {
            final label = opt.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selected == label
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                title: Text(label),
                selected: _selected == label,
                onTap: () {
                  setState(() => _selected = label);
                  widget.onAnswerChanged(label);
                },
              ),
            );
          }),
        ],
      ],
    );
  }
}
