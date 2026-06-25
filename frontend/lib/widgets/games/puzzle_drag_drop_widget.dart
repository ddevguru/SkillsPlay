import 'package:flutter/material.dart';

class PuzzleDragDropWidget extends StatefulWidget {
  final Map<String, dynamic> config;
  final ValueChanged<dynamic> onAnswerChanged;

  const PuzzleDragDropWidget({
    super.key,
    required this.config,
    required this.onAnswerChanged,
  });

  @override
  State<PuzzleDragDropWidget> createState() => _PuzzleDragDropWidgetState();
}

class _PuzzleDragDropWidgetState extends State<PuzzleDragDropWidget> {
  late List<String> _pool;
  final Map<String, String?> _zoneAssignments = {};

  List<String> get _zones {
    final raw = widget.config['zones'] as List? ?? widget.config['targets'] as List? ?? [];
    return raw.map((e) => e.toString()).toList();
  }

  @override
  void initState() {
    super.initState();
    final raw = widget.config['items'] as List? ?? [];
    _pool = raw.map((e) => e.toString()).toList();
    for (final z in _zones) {
      _zoneAssignments[z] = null;
    }
    _emit();
  }

  void _emit() {
    widget.onAnswerChanged(Map<String, String?>.from(_zoneAssignments));
  }

  void _assignToZone(String zone, String item) {
    setState(() {
      _pool.remove(item);
      final prev = _zoneAssignments[zone];
      if (prev != null) _pool.add(prev);
      for (final z in _zones) {
        if (_zoneAssignments[z] == item) _zoneAssignments[z] = null;
      }
      _zoneAssignments[zone] = item;
    });
    _emit();
  }

  void _returnToPool(String item) {
    setState(() {
      for (final z in _zones) {
        if (_zoneAssignments[z] == item) _zoneAssignments[z] = null;
      }
      if (!_pool.contains(item)) _pool.add(item);
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Drag items into the correct zones', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _pool.map((item) {
            return Draggable<String>(
              data: item,
              feedback: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: _chip(item)),
              child: _chip(item),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ..._zones.map((zone) {
          final assigned = _zoneAssignments[zone];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DragTarget<String>(
              onAcceptWithDetails: (d) => _assignToZone(zone, d.data),
              builder: (context, candidates, rejected) {
                return Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: candidates.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      width: candidates.isNotEmpty ? 2 : 1,
                    ),
                    color: candidates.isNotEmpty
                        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(zone, style: Theme.of(context).textTheme.titleSmall)),
                      if (assigned != null)
                        ActionChip(
                          label: Text(assigned),
                          onPressed: () => _returnToPool(assigned),
                          avatar: const Icon(Icons.close, size: 16),
                        )
                      else
                        Text('Drop here', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _chip(String item) {
    return Chip(label: Text(item), avatar: const Icon(Icons.drag_indicator, size: 18));
  }
}
