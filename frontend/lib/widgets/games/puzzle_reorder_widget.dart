import 'package:flutter/material.dart';

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
        Text('Drag to reorder', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Put the steps in the correct order', style: Theme.of(context).textTheme.bodySmall),
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
            return Card(
              key: ValueKey(_items[index]),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(_items[index]),
                trailing: const Icon(Icons.drag_handle),
              ),
            );
          },
        ),
      ],
    );
  }
}
