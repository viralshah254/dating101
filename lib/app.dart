import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/entitlements/entitlements.dart';
import 'core/locale/app_locale_provider.dart';
import 'core/mode/app_mode.dart';
import 'core/mode/mode_provider.dart';
import 'core/notifications/notification_deep_link.dart';
import 'core/providers/repository_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/session/session_api_cache_invalidation.dart';
import 'l10n/app_localizations.dart';

class ShubhmilanApp extends ConsumerStatefulWidget {
  const ShubhmilanApp({super.key});

  @override
  ConsumerState<ShubhmilanApp> createState() => _ShubhmilanAppState();
}

class _ShubhmilanAppState extends ConsumerState<ShubhmilanApp>
    with WidgetsBindingObserver {
  late final VoidCallback _tokenStorageListener;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    final tokens = ref.read(tokenStorageProvider);
    _wasLoggedIn = tokens.isLoggedIn;
    _tokenStorageListener = _onTokenStorageChanged;
    tokens.addListener(_tokenStorageListener);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSubscriptionAccess());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
  }

  void _onTokenStorageChanged() {
    if (!mounted) return;
    final tokens = ref.read(tokenStorageProvider);
    final now = tokens.isLoggedIn;
    if (_wasLoggedIn && !now) {
      ref.invalidate(appModeProvider);
      ref.invalidate(modePreferenceProvider);
      ref.invalidate(modeSelectedOnceProvider);
      ref.invalidate(appLocaleProvider);
      invalidateSessionScopedApiCaches(ref);
    } else if (!_wasLoggedIn && now) {
      // New sign-in: non–autoDispose feed providers would otherwise keep the
      // previous user's AsyncError (e.g. session expired) or stale data.
      invalidateSessionScopedApiCaches(ref);
    }
    _wasLoggedIn = now;
  }

  @override
  void dispose() {
    ref.read(tokenStorageProvider).removeListener(_tokenStorageListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSubscriptionAccess();
      _touchChatPresenceAfterResume();
    }
  }

  /// WS `ping` updates server in-memory online + throttled `Profile.lastActiveAt`.
  void _touchChatPresenceAfterResume() {
    final client = ref.read(chatWebSocketClientProvider);
    if (client == null) return;
    if (client.isConnected) {
      client.sendPing();
    } else {
      unawaited(
        client.connect().then((_) {
          if (!mounted) return;
          client.sendPing();
        }),
      );
    }
  }

  void _refreshSubscriptionAccess() {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.currentUserId == null) return;
    ref.read(subscriptionAccessRefreshProvider)();
  }

  void _initNotifications() {
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) debugPrint('[FCM] Skipping (Firebase not initialized)');
      return;
    }
    try {
      final router = ref.read(appRouterProvider);
      final service = ref.read(notificationServiceProvider);
      service.setOnNotificationTap((data) {
        final mode = ref.read(appModeProvider) ?? AppMode.dating;
        final path = notificationDataToPath(data, appMode: mode);
        if (path != null) router.go(path);
      });
      service.initialize();
      if (kDebugMode) debugPrint('[FCM] Initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Init failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final localeCode = ref.watch(appLocaleProvider);
    final locale = localeCode != null ? Locale(localeCode) : null;

    // Derive gender from entitlements; falls back to `unknown` (rose theme)
    // before the profile loads or when the user is logged out.
    final gender = ref.watch(entitlementsProvider).gender;

    return MaterialApp.router(
      title: lookupAppLocalizations(locale ?? const Locale('en')).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(gender: gender),
      darkTheme: AppTheme.dark(gender: gender),
      themeMode: ThemeMode.system,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
