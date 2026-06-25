import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _api;
  AuthNotifier(this._api) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _api.loadTokens();
    if (_api.isAuthenticated) {
      try {
        final data = await _api.getMe();
        state = AsyncValue.data(User.fromJson(data));
      } catch (_) {
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.login(email, password);
      state = AsyncValue.data(User.fromJson(data['user']));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password, {List<String>? trackIds}) async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.signup(name, email, password, trackIds: trackIds);
      state = AsyncValue.data(User.fromJson(data['user']));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() async {
    try {
      final data = await _api.getMe();
      state = AsyncValue.data(User.fromJson(data));
    } catch (_) {}
  }
}

final tracksProvider = FutureProvider<List<Track>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getTracks();
  return data.map((t) => Track.fromJson(t)).toList();
});

final topicsProvider = FutureProvider.family<List<Topic>, String>((ref, trackId) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getTopics(trackId);
  return data.map((t) => Topic.fromJson(t)).toList();
});

final plansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getPlans();
  return data.map((p) => SubscriptionPlan.fromJson(p)).toList();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final api = ref.read(apiServiceProvider);
  final data = await api.getGlobalLeaderboard();
  return data.asMap().entries.map((e) => LeaderboardEntry.fromJson(e.value, e.key + 1)).toList();
});
