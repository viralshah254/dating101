import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mode/mode_provider.dart';
import '../../l10n/app_localizations.dart';

const _kAppLocaleKey = 'app_locale';

/// Current app language code (e.g. 'en', 'hi'). Null = use system locale.
final appLocaleProvider = StateNotifierProvider<AppLocaleNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppLocaleNotifier(prefs);
});

class AppLocaleNotifier extends StateNotifier<String?> {
  AppLocaleNotifier(this._prefs) : super(_prefs.getString(_kAppLocaleKey));

  final SharedPreferences _prefs;

  void setLocale(String languageCode) {
    _prefs.setString(_kAppLocaleKey, languageCode);
    state = languageCode;
  }
}

/// Supported locales for the language picker (11 locales).
List<Locale> get supportedAppLocales => AppLocalizations.supportedLocales;
