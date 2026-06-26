import 'package:flutter/material.dart';
import '../../config/theme.dart';

class XpBadge extends StatelessWidget {
  final int xp;
  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB347).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFB347).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: Color(0xFFE67E22), size: 18),
          const SizedBox(width: 4),
          Text('$xp XP', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: SkillPlayTheme.clayText)),
        ],
      ),
    );
  }
}
