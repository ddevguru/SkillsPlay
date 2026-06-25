import 'package:flutter/material.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Chip(label: Text('Step ${_step + 1}/${_steps.length}')),
            const Spacer(),
            const Icon(Icons.psychology_outlined),
            const SizedBox(width: 4),
            const Text('Scenario'),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              current['prompt'] as String? ?? widget.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _select(opt),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _choices.length > _step && _choices[_step] == opt
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Text(opt),
              ),
            )),
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Previous step'),
          ),
      ],
    );
  }
}
