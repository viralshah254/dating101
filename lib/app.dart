import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/locale/app_locale_provider.dart';
import 'core/providers/repository_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'l10n/app_localizations.dart';

class ShubhmilanApp extends ConsumerStatefulWidget {
  const ShubhmilanApp({super.key});

  @override
  ConsumerState<ShubhmilanApp> createState() => _ShubhmilanAppState();
}

class _ShubhmilanAppState extends ConsumerState<ShubhmilanApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
  }

  void _initNotifications() {
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) debugPrint('[FCM] Skipping (Firebase not initialized)');
      return;
    }
    try {
      final router = ref.read(appRouterProvider);
      final service = ref.read(notificationServiceProvider);
      service.setOnNotificationTap((path) => router.go(path));
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
    return MaterialApp.router(
      title: lookupAppLocalizations(locale ?? const Locale('en')).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
