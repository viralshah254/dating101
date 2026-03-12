import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_mode.dart';
import 'mode_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'Override sharedPreferencesProvider with SharedPreferences.getInstance()',
  );
});

final modeRepositoryProvider = Provider<ModeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ModeRepositoryImpl(prefs);
});

/// Current app mode (effective: dating or matrimony). Null until user selects at signup.
final appModeProvider = StateNotifierProvider<AppModeNotifier, AppMode?>((ref) {
  final repo = ref.watch(modeRepositoryProvider);
  return AppModeNotifier(repo);
});

/// User's signup preference: dating, matrimony, or both. Use to show mode switch only when both.
final modePreferenceProvider = FutureProvider<AppMode>((ref) async {
  final repo = ref.watch(modeRepositoryProvider);
  return repo.getPreference();
});

/// Whether user has completed mode selection at least once.
final modeSelectedOnceProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(modeRepositoryProvider);
  return repo.hasSelectedModeOnce();
});

class AppModeNotifier extends StateNotifier<AppMode?> {
  AppModeNotifier(this._repo) : super(null) {
    _load();
  }

  final ModeRepository _repo;

  Future<void> _load() async {
    state = await _repo.getMode();
  }

  /// Set at signup: dating, matrimony, or both. When both, effective mode becomes dating until user switches.
  Future<void> setMode(AppMode mode) async {
    await _repo.setMode(mode);
    await _repo.setModeSelectedOnce();
    state = await _repo.getMode();
  }

  /// Switch current view when preference is both (dating ↔ matrimony). No-op when preference is single mode.
  Future<void> setCurrentView(AppMode view) async {
    if (view != AppMode.dating && view != AppMode.matrimony) return;
    await _repo.setCurrentView(view);
    state = view;
  }
}
