import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../clay/clay_widgets.dart';

String _itemLabel(dynamic e) {
  if (e is Map) return (e['label'] ?? e['id'] ?? e).toString();
  return e.toString();
}

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
    return raw.map(_itemLabel).toList();
  }

  @override
  void initState() {
    super.initState();
    final raw = widget.config['items'] as List? ?? [];
    _pool = raw.map(_itemLabel).toList();
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
        Text('🎯 Match Maker', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Drag each item into the correct zone', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SkillPlayTheme.clayTextMuted)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _pool.map((item) {
            return Draggable<String>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: ClayBox(
                  color: SkillPlayTheme.accent.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  depth: 1.5,
                  child: Text(item, style: const TextStyle(fontWeight: FontWeight.w800)),
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
                return ClayBox(
                  inset: candidates.isEmpty,
                  color: candidates.isNotEmpty
                      ? SkillPlayTheme.primary.withValues(alpha: 0.12)
                      : SkillPlayTheme.claySurface,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: Text(zone, style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (assigned != null)
                        GestureDetector(
                          onTap: () => _returnToPool(assigned),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: SkillPlayTheme.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(assigned, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(width: 4),
                                const Icon(Icons.close, size: 14),
                              ],
                            ),
                          ),
                        )
                      else
                        Text('Drop here', style: TextStyle(color: SkillPlayTheme.clayTextMuted, fontSize: 13)),
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
    return ClayBox(
      color: SkillPlayTheme.accent.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      depth: 0.7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.drag_indicator, size: 18, color: SkillPlayTheme.accent),
          const SizedBox(width: 6),
          Text(item, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
