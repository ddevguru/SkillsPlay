import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Soft claymorphism surface — rounded, puffy, with dual shadows.
class ClayBox extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool inset;
  final VoidCallback? onTap;
  final double depth;

  const ClayBox({
    super.key,
    required this.child,
    this.color,
    this.radius = 24,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.inset = false,
    this.onTap,
    this.depth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? SkillPlayTheme.claySurface;
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5),
        boxShadow: inset ? _insetShadows(base) : _outerShadows(depth),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }

  List<BoxShadow> _outerShadows(double d) => [
        BoxShadow(
          color: SkillPlayTheme.clayShadowDark.withValues(alpha: 0.18 * d),
          offset: Offset(6 * d, 8 * d),
          blurRadius: 18 * d,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.9),
          offset: Offset(-4 * d, -4 * d),
          blurRadius: 12 * d,
        ),
      ];

  List<BoxShadow> _insetShadows(Color base) => [
        BoxShadow(
          color: SkillPlayTheme.clayShadowDark.withValues(alpha: 0.12),
          offset: const Offset(3, 3),
          blurRadius: 8,
          spreadRadius: -2,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.8),
          offset: const Offset(-2, -2),
          blurRadius: 6,
          spreadRadius: -2,
        ),
      ];
}

class ClayScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const ClayScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: SkillPlayTheme.clayBackgroundGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

class ClayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const ClayAppBar({super.key, required this.title, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: SkillPlayTheme.clayText,
            ),
      ),
      actions: actions,
    );
  }
}

class ClayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final bool loading;
  final bool outlined;

  const ClayButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.loading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? SkillPlayTheme.primary;
    return ClayBox(
      color: outlined ? SkillPlayTheme.claySurface : bg,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      onTap: loading ? null : onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else ...[
            if (icon != null) ...[Icon(icon, color: outlined ? bg : Colors.white, size: 20), const SizedBox(width: 8)],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: outlined ? bg : Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ClayGameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;

  const ClayGameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ClayBox(
      margin: const EdgeInsets.only(bottom: 12),
      color: accent.withValues(alpha: 0.12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SkillPlayTheme.clayTextMuted)),
              ],
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badge!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
            ),
          const SizedBox(width: 8),
          Icon(Icons.play_circle_filled, color: accent, size: 36),
        ],
      ),
    );
  }
}

class ClayChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const ClayChip({super.key, required this.label, required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SkillPlayTheme.primary;
    return ClayBox(
      color: c.withValues(alpha: 0.1),
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      depth: 0.6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: c, fontSize: 13)),
        ],
      ),
    );
  }
}
