import 'package:shared_preferences/shared_preferences.dart';

import 'app_mode.dart';

const String _keyMode = 'shubhmilan_app_mode';
const String _keyModeSelectedOnce = 'shubhmilan_mode_selected_once';
const String _keyCurrentView = 'shubhmilan_mode_current_view';

/// Persists and reads app mode locally.
/// [getMode] returns effective mode (dating or matrimony) for UI. When preference is [both], returns [getCurrentView].
/// In production, also sync with user profile on backend.
abstract class ModeRepository {
  /// Effective mode for shell/discovery: always dating or matrimony. When preference is both, returns current view.
  Future<AppMode?> getMode();
  /// Signup preference: dating, matrimony, or both.
  Future<AppMode> getPreference();
  Future<void> setMode(AppMode mode);
  /// Switch current view when preference is both. No-op when preference is dating or matrimony.
  Future<void> setCurrentView(AppMode view);
  Future<AppMode?> getCurrentView();
  Future<bool> hasSelectedModeOnce();
  Future<void> setModeSelectedOnce();
}

class ModeRepositoryImpl implements ModeRepository {
  ModeRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppMode?> getMode() async {
    final pref = await getPreference();
    if (pref.isSingleMode) return pref;
    final view = _prefs.getString(_keyCurrentView);
    if (view != null) {
      try {
        final v = AppMode.values.firstWhere((e) => e.name == view && e.isSingleMode);
        return v;
      } catch (_) {}
    }
    return AppMode.dating;
  }

  @override
  Future<AppMode> getPreference() async {
    final raw = _prefs.getString(_keyMode);
    if (raw == null) return AppMode.dating;
    try {
      return AppMode.values.firstWhere((e) => e.name == raw);
    } catch (_) {
      return AppMode.dating;
    }
  }

  @override
  Future<void> setMode(AppMode mode) async {
    await _prefs.setString(_keyMode, mode.name);
    if (mode == AppMode.both) {
      await _prefs.setString(_keyCurrentView, AppMode.dating.name);
    }
  }

  @override
  Future<void> setCurrentView(AppMode view) async {
    if (view != AppMode.dating && view != AppMode.matrimony) return;
    await _prefs.setString(_keyCurrentView, view.name);
  }

  @override
  Future<AppMode?> getCurrentView() async {
    final raw = _prefs.getString(_keyCurrentView);
    if (raw == null) return null;
    try {
      final v = AppMode.values.firstWhere((e) => e.name == raw);
      return v.isSingleMode ? v : null;
    } catch (_) {
      return null;
    }
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
