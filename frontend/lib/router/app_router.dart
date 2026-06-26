import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/tracks/track_selection_screen.dart';
import '../screens/tracks/topic_screen.dart';
import '../screens/play/play_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/multiplayer/multiplayer_screen.dart';
import '../screens/multiplayer/multiplayer_room_screen.dart';
import '../screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isAuth = user != null;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final isSplash = state.matchedLocation == '/';

      if (isLoading && isSplash) return null;
      if (!isLoading && !isAuth && !isAuthRoute) return '/login';
      if (!isLoading && isAuth && (isAuthRoute || isSplash)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/tracks/select', builder: (_, __) => const TrackSelectionScreen()),
      GoRoute(
        path: '/tracks/:trackId',
        builder: (_, state) => TopicScreen(trackId: state.pathParameters['trackId']!),
      ),
      GoRoute(
        path: '/play/:lessonId',
        builder: (_, state) => PlayScreen(
          lessonId: state.pathParameters['lessonId']!,
          roomId: state.uri.queryParameters['roomId'],
        ),
      ),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
      GoRoute(path: '/multiplayer', builder: (_, __) => const MultiplayerScreen()),
      GoRoute(
        path: '/multiplayer/room/:roomId',
        builder: (_, state) => MultiplayerRoomScreen(roomId: state.pathParameters['roomId']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
