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

/// Current app mode. Null until user selects Dating or Matrimony (first run or after reset).
final appModeProvider = StateNotifierProvider<AppModeNotifier, AppMode?>((ref) {
  final repo = ref.watch(modeRepositoryProvider);
  return AppModeNotifier(repo);
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

  Future<void> setMode(AppMode mode) async {
    await _repo.setMode(mode);
    await _repo.setModeSelectedOnce();
    state = mode;
  }
}
