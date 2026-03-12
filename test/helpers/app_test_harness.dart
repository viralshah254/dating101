import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saathi/app.dart';
import 'package:saathi/core/mode/mode_provider.dart';
import 'package:saathi/core/router/app_router.dart';

Future<Widget> buildTestApp() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appRouterProvider.overrideWithValue(
        GoRouter(
          initialLocation: '/test',
          routes: [
            GoRoute(
              path: '/test',
              builder: (_, __) =>
                  const Scaffold(body: Center(child: Text('App Test Harness'))),
            ),
          ],
        ),
      ),
    ],
    child: const ShubhmilanApp(),
  );
}
