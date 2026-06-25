import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  late final Dio _dio;
  String? _accessToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _refreshToken != null) {
          try {
            final res = await _dio.post('/auth/refresh', data: {'refreshToken': _refreshToken});
            _accessToken = res.data['accessToken'] as String;
            await _saveTokens();
            error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
            final retry = await _dio.fetch(error.requestOptions);
            return handler.resolve(retry);
          } catch (_) {}
        }
        handler.next(error);
      },
    ));
  }

  String? _refreshToken;

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    await _saveTokens();
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString('access_token', _accessToken!);
    if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  bool get isAuthenticated => _accessToken != null;

  // Auth
  Future<Map<String, dynamic>> signup(String name, String email, String password, {List<String>? trackIds}) async {
    final res = await _dio.post('/auth/signup', data: {
      'name': name,
      'email': email,
      'password': password,
      if (trackIds != null) 'trackIds': trackIds,
    });
    await saveTokens(res.data['accessToken'], res.data['refreshToken']);
    return res.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    await saveTokens(res.data['accessToken'], res.data['refreshToken']);
    return res.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data;
  }

  // Tracks
  Future<List<dynamic>> getTracks() async {
    final res = await _dio.get('/tracks');
    return res.data as List;
  }

  Future<List<dynamic>> getTopics(String trackId) async {
    final res = await _dio.get('/tracks/$trackId/topics');
    return res.data as List;
  }

  Future<Map<String, dynamic>> selectTracks(List<String> trackIds) async {
    final res = await _dio.post('/tracks/select', data: {'trackIds': trackIds});
    return res.data;
  }

  Future<List<dynamic>> getTopicLessons(String trackId, String topicId) async {
    final res = await _dio.get('/tracks/$trackId/topics/$topicId/lessons');
    return res.data as List;
  }

  Future<Map<String, dynamic>> getLesson(String lessonId) async {
    final res = await _dio.get('/tracks/lessons/$lessonId');
    return res.data;
  }

  // Play
  Future<Map<String, dynamic>> startPlay(String lessonId) async {
    final res = await _dio.post('/play/start', data: {'lessonId': lessonId});
    return res.data;
  }

  Future<Map<String, dynamic>> submitPlay({
    required String attemptId,
    dynamic answer,
    String? code,
    String? language,
    int? timeSeconds,
  }) async {
    final res = await _dio.post('/play/submit', data: {
      'attemptId': attemptId,
      'answer': answer,
      if (code != null) 'code': code,
      if (language != null) 'language': language,
      if (timeSeconds != null) 'timeSeconds': timeSeconds,
    });
    return res.data;
  }

  // Leaderboard
  Future<List<dynamic>> getGlobalLeaderboard({String period = 'ALL_TIME'}) async {
    final res = await _dio.get('/leaderboard/global', queryParameters: {'period': period});
    return res.data as List;
  }

  Future<List<dynamic>> getFriendsLeaderboard() async {
    final res = await _dio.get('/leaderboard/friends');
    return res.data as List;
  }

  // Payments (mock)
  Future<List<dynamic>> getPlans() async {
    final res = await _dio.get('/payments/plans');
    return res.data as List;
  }

  Future<Map<String, dynamic>> checkout(String planId, {String? coupon}) async {
    final res = await _dio.post('/payments/checkout', data: {
      'planId': planId,
      if (coupon != null) 'coupon': coupon,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> completeMockPayment(String paymentId) async {
    final res = await _dio.post('/payments/mock/complete', data: {'paymentId': paymentId});
    return res.data;
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final res = await _dio.get('/payments/subscriptions/status');
    return res.data;
  }

  // Multiplayer
  Future<Map<String, dynamic>> createRoom({String? lessonId}) async {
    final res = await _dio.post('/rooms/create', data: {if (lessonId != null) 'lessonId': lessonId});
    return res.data;
  }

  Future<Map<String, dynamic>> joinRoom(String roomCode) async {
    final res = await _dio.post('/rooms/join', data: {'roomCode': roomCode});
    return res.data;
  }

  Future<Map<String, dynamic>> getRoom(String roomId) async {
    final res = await _dio.get('/rooms/$roomId');
    return res.data;
  }

  Future<Map<String, dynamic>> startRoom(String roomId) async {
    final res = await _dio.post('/rooms/$roomId/start');
    return res.data;
  }

  Future<Map<String, dynamic>> finishRoom(String roomId, Map<String, int> scores) async {
    final res = await _dio.post('/rooms/$roomId/finish', data: {'scores': scores});
    return res.data;
  }
}
