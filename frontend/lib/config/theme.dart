import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkillPlayTheme {
  static const primary = Color(0xFF7B6CF6);
  static const secondary = Color(0xFF5ECFC9);
  static const accent = Color(0xFFFF8FAB);
  static const claySurface = Color(0xFFF8F4FF);
  static const clayText = Color(0xFF3D3558);
  static const clayTextMuted = Color(0xFF8B83A8);
  static const clayShadowDark = Color(0xFFB8AED4);

  static const clayBackgroundGradient = [
    Color(0xFFFFE8F0),
    Color(0xFFE8F4FD),
    Color(0xFFF0EBFF),
  ];

  static const gameColors = {
    'MICRO_LESSON': Color(0xFF7B6CF6),
    'PUZZLE_DRAG_DROP': Color(0xFFFF8FAB),
    'PUZZLE_REORDER': Color(0xFFFFB347),
    'CODE_COMPLETION': Color(0xFF5ECFC9),
    'TIMED_CHALLENGE': Color(0xFFFF6B6B),
    'SCENARIO_SIMULATION': Color(0xFF6BCB77),
  };

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          secondary: secondary,
          tertiary: accent,
          brightness: Brightness.light,
          surface: claySurface,
          onSurface: clayText,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().apply(
          bodyColor: clayText,
          displayColor: clayText,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: Colors.transparent),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: claySurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: claySurface.withValues(alpha: 0.85),
          indicatorColor: primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      );

  static ThemeData get dark => light;
}
