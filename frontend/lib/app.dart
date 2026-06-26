import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'router/app_router.dart';

class SkillPlayApp extends ConsumerWidget {
  const SkillPlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SkillPlay',
      debugShowCheckedModeBanner: false,
      theme: SkillPlayTheme.light,
      darkTheme: SkillPlayTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
