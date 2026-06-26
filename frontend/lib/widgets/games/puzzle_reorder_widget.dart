import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../clay/clay_widgets.dart';

class PuzzleReorderWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final ValueChanged<dynamic> onAnswerChanged;

  const PuzzleReorderWidget({
    super.key,
    required this.config,
    required this.onAnswerChanged,
  });

  @override
  State<PuzzleReorderWidget> createState() => _PuzzleReorderWidgetState();
}

class _PuzzleReorderWidgetState extends State<PuzzleReorderWidget> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    final raw = widget.config['items'] as List? ?? [];
    _items = raw.map((e) => e.toString()).toList();
    if (widget.config['shuffleOnLoad'] == true) {
      _items.shuffle();
    }
    _emit();
  }

  void _emit() => widget.onAnswerChanged(List<String>.from(_items));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('🔢 Step Master', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Drag to put the steps in the correct order', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SkillPlayTheme.clayTextMuted)),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _items.removeAt(oldIndex);
              _items.insert(newIndex, item);
            });
            _emit();
          },
          itemBuilder: (context, index) {
            return ClayBox(
              key: ValueKey(_items[index]),
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFFFFB347).withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(_items[index], style: const TextStyle(fontWeight: FontWeight.w600))),
                  const Icon(Icons.drag_handle, color: SkillPlayTheme.clayTextMuted),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
