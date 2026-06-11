import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/journal/presentation/journal_list_screen.dart';
import '../features/journal/presentation/journal_detail_screen.dart';
import '../providers/providers.dart';

/// Notifier that triggers GoRouter redirects whenever authentication or onboarding state changes.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to changes in auth state and user onboarding profiles
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
    _ref.listen(appUserProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authValue = ref.read(authStateProvider);
      final userValue = ref.read(appUserProvider);

      // Wait if the auth state is still loading
      if (authValue.isLoading || userValue.isLoading) return null;

      final bool isLoggedIn = authValue.value != null;
      final bool isOnboarded = userValue.value?.onboarded ?? false;

      final String location = state.uri.path;
      final bool isAuthPath = location == '/login' || location == '/signup';
      final bool isOnboardingPath = location == '/onboarding';

      // 1. Unauthenticated users must only access login/signup
      if (!isLoggedIn) {
        if (isAuthPath) return null;
        return '/login';
      }

      // 2. Authenticated but non-onboarded users must stay on the onboarding questionnaire
      if (!isOnboarded) {
        if (isOnboardingPath) return null;
        return '/onboarding';
      }

      // 3. Onboarded users trying to access login, signup, or onboarding are sent to dashboard
      if (isAuthPath || isOnboardingPath) {
        return '/';
      }

      // Allow navigation to other screens
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const JournalDetailScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return JournalDetailScreen(entryId: id);
            },
          ),
        ],
      ),
    ],
  );
});
