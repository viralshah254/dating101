import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../location/app_location_service.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/splash/screens/tagline_screen.dart';
import '../../features/location/screens/location_required_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/mode_select/screens/mode_select_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/screens/profile_wizard_screen.dart';
import '../../features/profile_setup/screens/profile_setup_screen.dart';
import '../../features/profile/screens/full_profile_screen.dart';
import '../../features/profile/screens/blocked_users_screen.dart';
import '../../features/profile/screens/profile_view_screen.dart';
import '../../features/premium/screens/paywall_screen.dart';
import '../../features/verification/screens/verification_screen.dart';
import '../../features/verification/screens/photo_verification_screen.dart';
import '../../features/identity/screens/identity_onboarding_screen.dart';
import '../../features/referral/screens/referral_screen.dart';
import '../../features/chat/screens/chat_thread_screen.dart';
import '../shell/root_shell.dart';
import '../shell/shell_branch_content.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final isShellRoute =
          loc == '/' ||
          loc.startsWith('/map') ||
          loc.startsWith('/chats') ||
          loc.startsWith('/community') ||
          loc.startsWith('/profile-settings');
      if (isShellRoute) {
        final access = await AppLocationService.instance.checkAccess();
        if (access != LocationAccess.granted) {
          return '/location-required?then=${Uri.encodeComponent(loc)}';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/tagline', builder: (_, __) => const TaglineScreen()),
      GoRoute(
        path: '/location-required',
        builder: (_, state) {
          final thenPath = state.uri.queryParameters['then'] ?? '/';
          return LocationRequiredScreen(thenPath: thenPath);
        },
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final phone = state.uri.queryParameters['phone'];
          final vid = state.uri.queryParameters['vid'];
          return OtpScreen(phone: phone, verificationId: vid);
        },
      ),
      GoRoute(
        path: '/mode-select',
        builder: (_, __) => const ModeSelectScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-wizard',
        builder: (_, __) => const ProfileWizardScreen(),
      ),
      GoRoute(
        path: '/profile-view',
        builder: (_, __) => const ProfileViewScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (_, state) {
          final editing = state.uri.queryParameters['edit'] == 'true';
          final step = int.tryParse(state.uri.queryParameters['step'] ?? '');
          return ProfileSetupScreen(isEditing: editing, initialStep: step);
        },
      ),
      GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      GoRoute(
        path: '/verification',
        builder: (_, __) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/photo-verification',
        builder: (_, __) => const PhotoVerificationScreen(),
      ),
      GoRoute(
        path: '/identity',
        builder: (_, __) => const IdentityOnboardingScreen(),
      ),
      GoRoute(path: '/referral', builder: (_, __) => const ReferralScreen()),
      GoRoute(
        path: '/blocked-users',
        builder: (_, __) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          return FullProfileScreen(profileId: id);
        },
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (_, state) {
          final id = state.pathParameters['threadId'] ?? '';
          final otherUserId = state.uri.queryParameters['otherUserId'];
          return ChatThreadScreen(threadId: id, otherUserId: otherUserId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => RootShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const ShellBranchContent(branchIndex: 0),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (_, __) => const ShellBranchContent(branchIndex: 1),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (_, __) => const ShellBranchContent(branchIndex: 2),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (_, __) => const ShellBranchContent(branchIndex: 3),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile-settings',
                builder: (_, __) => const ShellBranchContent(branchIndex: 4),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

GoRouter createAppRouter() {
  // Used when router is not created via Provider (e.g. tests or app.dart without ref).
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/mode-select',
        builder: (_, __) => const ModeSelectScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Shell requires Provider')),
        ),
      ),
    ],
  );
}
