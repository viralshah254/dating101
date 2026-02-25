import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/mode/mode_provider.dart';
import 'core/providers/repository_providers.dart';
import 'data/api/token_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Run without Firebase until flutterfire configure is run
  }
  final prefs = await SharedPreferences.getInstance();
  final tokens = TokenStorage();
  await tokens.load();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(tokens),
      ],
      child: const SaathiApp(),
    ),
  );
}
