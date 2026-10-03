import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/log/screens/log_screen.dart';
import '../../features/muse/screens/muse_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/rewards/screens/rewards_screen.dart';
import '../providers/user_data_provider.dart';
import '../widgets/app_shell.dart';

/// Route tree: welcome -> auth -> onboarding all sit outside the shell (no
/// bottom nav). Everything else is a tab wrapped once, centrally, by
/// [AppShell] via a ShellRoute — no screen constructs its own nav bar.
///
/// Gating depends on two independent backends: [AuthProvider] (is there a
/// signed-in Firebase user?) and [UserDataProvider] (has that user's
/// Firestore profile finished onboarding?) — both must be ready before the
/// redirect makes a decision, or a returning user would flash through
/// /welcome while Firebase is still resolving the session.
GoRouter buildRouter(AuthProvider auth, UserDataProvider data) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([auth, data]),
    redirect: (context, state) {
      if (!auth.ready || !data.hydrated) return null;
      final loc = state.matchedLocation;

      if (!auth.authed) {
        return (loc == '/welcome' || loc == '/auth') ? null : '/welcome';
      }
      if (!data.consent) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (loc == '/welcome' || loc == '/auth' || loc == '/onboarding') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/rewards', builder: (context, state) => const RewardsScreen()),
      GoRoute(path: '/style-profile', builder: (context, state) => const OnboardingScreen(editing: true)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/log', builder: (context, state) => const LogScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/muse', builder: (context, state) => const MuseScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/insights', builder: (context, state) => const InsightsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}
