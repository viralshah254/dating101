import 'package:shared_preferences/shared_preferences.dart';

const String _keyLastShownDate = 'daily_matches_last_shown_date';

/// Persists when the daily matches popup was last shown. Used to show at most once per day.
class DailyMatchesStorage {
  DailyMatchesStorage(this._prefs);

  final SharedPreferences _prefs;

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// True if we should show the popup: we have not shown it today.
  bool shouldShowPopup([DateTime? now]) {
    final today = now ?? DateTime.now();
    final todayStr = _dateString(today);
    final last = _prefs.getString(_keyLastShownDate);
    return last != todayStr;
  }

  /// Call after showing the popup (or user dismissed) so we don't show again until the next day.
  Future<void> markShown() async {
    await _prefs.setString(_keyLastShownDate, _dateString(DateTime.now()));
  }
}
