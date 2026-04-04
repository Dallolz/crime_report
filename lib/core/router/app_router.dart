import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/matchmaking/screens/find_match_screen.dart';
import '../../features/matchmaking/screens/create_match_screen.dart';
import '../../features/matchmaking/screens/match_detail_screen.dart';
import '../../features/matchmaking/screens/match_lobby_screen.dart';
import '../../features/matchmaking/screens/match_result_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/sport_stats_screen.dart';
import '../../features/sports/screens/sports_list_screen.dart';
import '../../features/sports/screens/sport_detail_screen.dart';
import '../../features/community/screens/feed_screen.dart';
import '../../features/community/screens/nearby_players_screen.dart';
import '../../features/community/screens/leaderboard_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/venues/screens/venues_map_screen.dart';
import '../../features/venues/screens/venue_detail_screen.dart';
import '../../features/gamification/screens/badges_screen.dart';
import '../../features/gamification/screens/challenges_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/sports',
            builder: (context, state) => const SportsListScreen(),
          ),
          GoRoute(
            path: '/find-match',
            builder: (context, state) => const FindMatchScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Detail routes (outside shell)
      GoRoute(
        path: '/sport/:sportId',
        builder: (context, state) => SportDetailScreen(
          sportId: int.parse(state.pathParameters['sportId']!),
        ),
      ),
      GoRoute(
        path: '/create-match',
        builder: (context, state) => const CreateMatchScreen(),
      ),
      GoRoute(
        path: '/match/:matchId',
        builder: (context, state) => MatchDetailScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '/match/:matchId/lobby',
        builder: (context, state) => MatchLobbyScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '/match/:matchId/result',
        builder: (context, state) => MatchResultScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => ProfileScreen(
          userId: state.pathParameters['userId'],
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/sport-stats/:sportId',
        builder: (context, state) => SportStatsScreen(
          sportId: int.parse(state.pathParameters['sportId']!),
        ),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/nearby',
        builder: (context, state) => const NearbyPlayersScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) => ChatRoomScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/venues',
        builder: (context, state) => const VenuesMapScreen(),
      ),
      GoRoute(
        path: '/venue/:venueId',
        builder: (context, state) => VenueDetailScreen(
          venueId: int.parse(state.pathParameters['venueId']!),
        ),
      ),
      GoRoute(
        path: '/badges',
        builder: (context, state) => const BadgesScreen(),
      ),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
    ],
  );
});

/// Main shell widget with bottom navigation bar
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location == '/sports') return 1;
    if (location == '/find-match') return 2;
    if (location == '/chat') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/sports');
            case 2:
              context.go('/find-match');
            case 3:
              context.go('/chat');
            case 4:
              context.go('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_outlined),
            activeIcon: Icon(Icons.sports),
            label: 'Sports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_outlined),
            activeIcon: Icon(Icons.flash_on),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
