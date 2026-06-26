import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../clay/clay_widgets.dart';

class ScenarioSimulationWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final String content;
  final ValueChanged<dynamic> onAnswerChanged;

  const ScenarioSimulationWidget({
    super.key,
    required this.config,
    required this.content,
    required this.onAnswerChanged,
  });

  @override
  State<ScenarioSimulationWidget> createState() => _ScenarioSimulationWidgetState();
}

class _ScenarioSimulationWidgetState extends State<ScenarioSimulationWidget> {
  int _step = 0;
  final List<String> _choices = [];

  List<Map<String, dynamic>> get _steps {
    final raw = widget.config['steps'] as List?;
    if (raw != null) return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final scenario = widget.config['scenario'] as String? ?? widget.content;
    final options = (widget.config['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return [
      {'prompt': scenario, 'options': options},
    ];
  }

  void _select(String choice) {
    setState(() {
      if (_step < _choices.length) {
        _choices[_step] = choice;
      } else {
        _choices.add(choice);
      }
      if (_step < _steps.length - 1) {
        _step++;
      }
    });
    widget.onAnswerChanged(List<String>.from(_choices));
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps[_step];
    final options = (current['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final progress = (_step + 1) / _steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('🧠 Real World', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6BCB77).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Text('Step ${_step + 1}/${_steps.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6BCB77))),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: progress, minHeight: 6, color: const Color(0xFF6BCB77), backgroundColor: const Color(0xFF6BCB77).withValues(alpha: 0.15)),
        ),
        const SizedBox(height: 16),
        ClayBox(
          color: const Color(0xFF6BCB77).withValues(alpha: 0.08),
          child: Text(
            current['prompt'] as String? ?? widget.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((opt) {
          final selected = _choices.length > _step && _choices[_step] == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClayBox(
              color: selected ? const Color(0xFF6BCB77).withValues(alpha: 0.15) : SkillPlayTheme.claySurface,
              onTap: () => _select(opt),
              child: Row(
                children: [
                  Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? const Color(0xFF6BCB77) : SkillPlayTheme.clayTextMuted, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(opt, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
                ],
              ),
            ),
          );
        }),
        if (_step > 0)
          TextButton(onPressed: () => setState(() => _step--), child: const Text('← Previous step')),
      ],
    );
  }
}
