import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/clay/clay_widgets.dart';

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
    final progress = quiz != null && onLastSlide ? 1.0 : (_slideIndex + 1) / slides.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: SkillPlayTheme.primary.withValues(alpha: 0.1),
            color: SkillPlayTheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        if (!onLastSlide || quiz == null) ...[
          Text(slides[_slideIndex]['title'] ?? 'Slide ${_slideIndex + 1}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(slides[_slideIndex]['body'] ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_slideIndex > 0)
                ClayButton(label: 'Back', outlined: true, onPressed: () => setState(() => _slideIndex--))
              else
                const SizedBox(),
              ClayButton(
                label: onLastSlide && quiz != null ? 'Take Quiz' : 'Next',
                icon: Icons.arrow_forward,
                onPressed: () => setState(() => _slideIndex++),
              ),
            ],
          ),
        ],
        if (onLastSlide && quiz != null) ...[
          Text('🧠 Quick Check', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(quiz['question'] ?? 'Test your knowledge', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          ...(quiz['options'] as List? ?? ['Yes']).map((opt) {
            final label = opt.toString();
            final selected = _selected == label;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ClayBox(
                color: selected ? SkillPlayTheme.primary.withValues(alpha: 0.15) : SkillPlayTheme.claySurface,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                depth: selected ? 0.5 : 1,
                onTap: () {
                  setState(() => _selected = label);
                  widget.onAnswerChanged(label);
                },
                child: Row(
                  children: [
                    Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? SkillPlayTheme.primary : SkillPlayTheme.clayTextMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
