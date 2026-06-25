import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCache {
  static SharedPreferences? _prefs;

  static Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  static Future<void> cacheTracks(List<dynamic> tracks) async {
    await _prefs?.setString('cached_tracks', jsonEncode(tracks));
    await _prefs?.setInt('cached_tracks_at', DateTime.now().millisecondsSinceEpoch);
  }

  static List<dynamic>? getCachedTracks() {
    final raw = _prefs?.getString('cached_tracks');
    if (raw == null) return null;
    return jsonDecode(raw) as List;
  }

  static Future<void> cacheLesson(String id, Map<String, dynamic> lesson) async {
    await _prefs?.setString('lesson_$id', jsonEncode(lesson));
  }

  static Map<String, dynamic>? getCachedLesson(String id) {
    final raw = _prefs?.getString('lesson_$id');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> queueAttempt(Map<String, dynamic> attempt) async {
    final queue = getPendingAttempts();
    queue.add({...attempt, 'queuedAt': DateTime.now().toIso8601String()});
    await _prefs?.setString('pending_attempts', jsonEncode(queue));
  }

  static List<Map<String, dynamic>> getPendingAttempts() {
    final raw = _prefs?.getString('pending_attempts');
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> clearPendingAttempts() async {
    await _prefs?.remove('pending_attempts');
  }
}
