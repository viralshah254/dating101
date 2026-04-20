import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_motion.dart';
import '../../l10n/app_localizations.dart';
import '../location/app_location_service.dart';
import '../location/location_service_provider.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/splash/screens/tagline_screen.dart';
import '../../features/location/screens/location_required_screen.dart';
import '../../features/auth/screens/language_select_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/mode_select/screens/mode_select_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/screens/profile_wizard_screen.dart';
import '../../features/profile_setup/screens/profile_setup_screen.dart';
import '../../features/profile_setup/screens/profile_section_edit_screen.dart';
import '../../features/profile/screens/full_profile_screen.dart';
import '../../features/family/screens/family_circle_screen.dart';
import '../../features/family/screens/handover_accept_screen.dart';
import '../../features/profile/screens/blocked_users_screen.dart';
import '../../features/profile/screens/profile_view_screen.dart';
import '../../features/premium/screens/paywall_screen.dart';
import '../../features/verification/screens/verification_screen.dart';
import '../../features/verification/screens/photo_verification_screen.dart';
import '../../features/identity/screens/identity_onboarding_screen.dart';
import '../../features/referral/screens/referral_screen.dart';
import '../../features/profile/screens/ai_profile_review_screen.dart';
import '../../features/stories/screens/success_stories_screen.dart';
import '../../features/safety/screens/meeting_safety_screen.dart';
import '../../features/chat/screens/chat_thread_screen.dart';
import '../../features/requests/screens/requests_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../analytics/analytics_service.dart';
import '../feature_flags/feature_flags.dart';
import '../shell/root_shell.dart';
import '../shell/shell_branch_content.dart';
import '../providers/repository_providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that do not require an authenticated user (sign-in / sign-up flow).
const _publicPaths = [
  '/splash',
  '/tagline',
  '/language-select',
  '/login',
  '/location-required',
  '/mode-select',
  '/onboarding',
];

Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: tokenStorage.authChangeListenable,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final eventsEnabled = ref.read(isEventsEnabledProvider);
      final isEventsRoute =
          loc.startsWith('/events') ||
          loc.startsWith('/community') ||
          loc.startsWith('/circles');
      if (!eventsEnabled && isEventsRoute) {
        AnalyticsService.instance.log(AnalyticsEvent.gatedRouteBlocked, {
          'route': loc,
          'flag': 'events',
        });
        return '/';
      }
      final isPublic =
          _publicPaths.any((p) => loc == p || loc.startsWith('$p?'));
      if (!isPublic && authRepo.currentUserId == null) {
        return '/login';
      }
        final isShellRoute =
          loc == '/' ||
          loc.startsWith('/map') ||
          loc.startsWith('/chats') ||
          loc.startsWith('/likes') ||
          loc.startsWith('/profile-settings') ||
          loc.startsWith('/notifications');
      if (isShellRoute) {
        final access = await ref.read(locationServiceProvider).checkAccess();
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
        path: '/language-select',
        pageBuilder: (_, s) => _buildPage(s, const LanguageSelectScreen()),
      ),
      GoRoute(
        path: '/location-required',
        pageBuilder: (_, state) {
          final thenPath = state.uri.queryParameters['then'] ?? '/';
          return _buildPage(state, LocationRequiredScreen(thenPath: thenPath));
        },
      ),
      GoRoute(path: '/login', pageBuilder: (_, s) => _buildPage(s, const LoginScreen())),
      GoRoute(
        path: '/mode-select',
        pageBuilder: (_, s) => _buildPage(s, const ModeSelectScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, s) => _buildPage(s, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/profile-wizard',
        pageBuilder: (_, s) => _buildPage(s, const ProfileWizardScreen()),
      ),
      GoRoute(
        path: '/profile-view',
        pageBuilder: (_, s) => _buildPage(s, const ProfileViewScreen()),
      ),
      GoRoute(
        path: '/profile-setup',
        pageBuilder: (_, state) {
          final editing = state.uri.queryParameters['edit'] == 'true';
          final step = int.tryParse(state.uri.queryParameters['step'] ?? '');
          return _buildPage(state, ProfileSetupScreen(isEditing: editing, initialStep: step));
        },
      ),
      GoRoute(
        path: '/profile-edit',
        pageBuilder: (_, state) {
          final section = state.uri.queryParameters['section'] ?? 'basic';
          return _buildPage(state, ProfileSectionEditScreen(sectionId: section));
        },
      ),
      GoRoute(path: '/paywall', pageBuilder: (_, s) => _buildPage(s, const PaywallScreen())),
      GoRoute(
        path: '/verification',
        pageBuilder: (_, s) => _buildPage(s, const VerificationScreen()),
      ),
      GoRoute(
        path: '/photo-verification',
        pageBuilder: (_, s) => _buildPage(s, const PhotoVerificationScreen()),
      ),
      GoRoute(
        path: '/identity',
        pageBuilder: (_, s) => _buildPage(s, const IdentityOnboardingScreen()),
      ),
      GoRoute(path: '/referral', pageBuilder: (_, s) => _buildPage(s, const ReferralScreen())),
      GoRoute(
        path: '/blocked-users',
        pageBuilder: (_, s) => _buildPage(s, const BlockedUsersScreen()),
      ),
      GoRoute(
        path: '/family-circle',
        pageBuilder: (_, s) => _buildPage(s, const FamilyCircleScreen()),
      ),
      GoRoute(
        path: '/family/handover',
        pageBuilder: (_, s) {
          final token = s.uri.queryParameters['token'] ?? '';
          return _buildPage(s, HandoverAcceptScreen(token: token));
        },
      ),
      GoRoute(
        path: '/requests',
        pageBuilder: (_, s) => _buildPage(s, const RequestsScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, s) => _buildPage(s, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/profile/:id',
        pageBuilder: (_, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildCardPage(state, FullProfileScreen(profileId: id));
        },
      ),
      GoRoute(
        path: '/ai-profile-review',
        pageBuilder: (_, s) => _buildPage(s, const AiProfileReviewScreen()),
      ),
      GoRoute(
        path: '/success-stories',
        pageBuilder: (_, s) => _buildPage(s, const SuccessStoriesScreen()),
      ),
      GoRoute(
        path: '/meeting-safety',
        pageBuilder: (_, s) {
          final matchName = s.uri.queryParameters['matchName'];
          return _buildCardPage(s, MeetingSafetyScreen(matchName: matchName));
        },
      ),
      GoRoute(
        path: '/chat/:threadId',
        pageBuilder: (_, state) {
          final id = state.pathParameters['threadId'] ?? '';
          final otherUserId = state.uri.queryParameters['otherUserId'];
          final initialAdToken = state.uri.queryParameters['initialAdToken'];
          final initialText = state.uri.queryParameters['initialText'];
          return _buildCardPage(state, ChatThreadScreen(
            threadId: id,
            otherUserId: otherUserId,
            initialAdToken: initialAdToken,
            initialText: initialText,
          ));
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
                path: '/likes',
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

/// Standard page transition: subtle fade + 16 dp slide-up with spring curve.
Page<T> _buildPage<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.medium,
      reverseTransitionDuration: AppMotion.fast,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: AppMotion.spring),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: AppMotion.spring)),
          child: child,
        ),
      ),
    );

/// Bottom-up card reveal for immersive screens (profile, chat).
Page<T> _buildCardPage<T>(GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.medium,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: AppMotion.reveal)),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: AppMotion.spring),
          child: child,
        ),
      ),
    );

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
        builder: (_, __) => Scaffold(
          body: Center(child: Text(lookupAppLocalizations(const Locale('en')).shellRequiresProvider)),
        ),
      ),
    ],
  );
}
