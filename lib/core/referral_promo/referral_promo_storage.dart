import 'package:shared_preferences/shared_preferences.dart';

const String _keyLastShownDate = 'referral_promo_last_shown_date';

/// End date for the referral promo campaign (show popup only until this date inclusive).
final DateTime referralPromoEndDate = DateTime(2026, 10, 31);

/// Persists when the referral promo popup was last shown. Used to show at most once per day until [referralPromoEndDate].
class ReferralPromoStorage {
  ReferralPromoStorage(this._prefs);

  final SharedPreferences _prefs;

  static String _dateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// True if we should show the popup: today is on or before [referralPromoEndDate] and we have not shown it today.
  bool shouldShowPopup([DateTime? now]) {
    final today = now ?? DateTime.now();
    final todayStr = _dateString(today);
    final endStr = _dateString(referralPromoEndDate);
    if (todayStr.compareTo(endStr) > 0) return false;
    final last = _prefs.getString(_keyLastShownDate);
    return last != todayStr;
  }

  /// Call after showing the popup so we don't show again until the next day.
  Future<void> markShown() async {
    await _prefs.setString(_keyLastShownDate, _dateString(DateTime.now()));
  }
}
