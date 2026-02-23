import 'package:shared_preferences/shared_preferences.dart';

import 'app_mode.dart';

const String _keyMode = 'desilink_app_mode';
const String _keyModeSelectedOnce = 'desilink_mode_selected_once';

/// Persists and reads app mode locally.
/// In production, also sync with user profile on backend.
abstract class ModeRepository {
  Future<AppMode?> getMode();
  Future<void> setMode(AppMode mode);
  Future<bool> hasSelectedModeOnce();
  Future<void> setModeSelectedOnce();
}

class ModeRepositoryImpl implements ModeRepository {
  ModeRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppMode?> getMode() async {
    final raw = _prefs.getString(_keyMode);
    if (raw == null) return null;
    try {
      return AppMode.values.firstWhere((e) => e.name == raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setMode(AppMode mode) async {
    await _prefs.setString(_keyMode, mode.name);
  }

  @override
  Future<bool> hasSelectedModeOnce() async {
    return _prefs.getBool(_keyModeSelectedOnce) ?? false;
  }

  @override
  Future<void> setModeSelectedOnce() async {
    await _prefs.setBool(_keyModeSelectedOnce, true);
  }
}
