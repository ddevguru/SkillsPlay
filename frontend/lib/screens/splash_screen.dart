import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../widgets/clay/clay_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClayBox(
              color: SkillPlayTheme.primary.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(32),
              child: const Icon(Icons.sports_esports, size: 72, color: SkillPlayTheme.primary)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
            ),
            const SizedBox(height: 28),
            Text(
              'SkillPlay',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: SkillPlayTheme.clayText),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              'Learn. Play. Compete. 🎮',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SkillPlayTheme.clayTextMuted),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: SkillPlayTheme.primary),
          ],
        ),
      ),
    );
  }
}
