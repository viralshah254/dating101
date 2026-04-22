/// PaywallTriggerService
///
/// Central controller for smart paywall popup triggers.
/// Enforces cooldown rules so users are not over-prompted:
///   - Max 1 popup per 30-minute session window.
///   - Max 2 popups per calendar day.
///   - Never show during active chat.
///
/// Usage:
///   PaywallTriggerService.maybeShow(context, ref, PaywallReason.messagingBlocked);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/entitlements/entitlements.dart';

// ── Trigger reasons ───────────────────────────────────────────────────────────

enum PaywallReason {
  messagingBlocked,
  likesTab,
  swipeLimit,
  matchAccepted,
  photoLimit,
  dayStreak,
}

extension PaywallReasonX on PaywallReason {
  String get queryParam {
    switch (this) {
      case PaywallReason.messagingBlocked:
        return 'messagingBlocked';
      case PaywallReason.likesTab:
        return 'likesTab';
      case PaywallReason.swipeLimit:
        return 'swipeLimit';
      case PaywallReason.matchAccepted:
        return 'matchAccepted';
      case PaywallReason.photoLimit:
        return 'photoLimit';
      case PaywallReason.dayStreak:
        return 'dayStreak';
    }
  }

  /// Human-readable headline shown on the paywall screen.
  String get headline {
    switch (this) {
      case PaywallReason.messagingBlocked:
        return 'Start the conversation';
      case PaywallReason.likesTab:
        return 'See who liked your profile';
      case PaywallReason.swipeLimit:
        return "You've browsed 15 matches — unlock more";
      case PaywallReason.matchAccepted:
        return "They're interested! Message them now";
      case PaywallReason.photoLimit:
        return 'Upgrade to see all photos';
      case PaywallReason.dayStreak:
        return "You've been active 3 days — take the next step";
    }
  }
}

// ── Storage keys ──────────────────────────────────────────────────────────────

const _kLastShownMs = 'paywall_last_shown_ms';
const _kDailyCount = 'paywall_daily_count';
const _kDailyDate = 'paywall_daily_date';
const _kActiveDays = 'paywall_active_days'; // comma-separated date strings
const _kSwipeCount = 'paywall_session_swipe_count';
const _kSwipeSessionMs = 'paywall_session_start_ms';

// ── Cooldown constants ────────────────────────────────────────────────────────

const _kMinIntervalMs = 30 * 60 * 1000; // 30 minutes between popups
const _kMaxPerDay = 2;
const _kSwipeLimitTrigger = 15; // show after 15 profiles viewed
const _kStreakDays = 3; // consecutive active days before streak trigger

// ── Service ───────────────────────────────────────────────────────────────────

class PaywallTriggerService {
  PaywallTriggerService._();

  /// Must be called in main() after SharedPreferences is available.
  /// Tracks today as an active day (for streak calculation).
  static Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    final raw = prefs.getString(_kActiveDays) ?? '';
    final days = raw.isEmpty ? <String>[] : raw.split(',');
    if (!days.contains(today)) {
      days.add(today);
      // Keep only last 7 days to bound storage
      if (days.length > 7) days.removeAt(0);
      await prefs.setString(_kActiveDays, days.join(','));
    }
  }

  /// Call every time a user views a new profile card in discovery.
  /// Returns true if the swipe-limit paywall was shown.
  static Future<bool> recordSwipe(BuildContext context, WidgetRef ref) async {
    final entitlements = ref.read(entitlementsProvider);
    if (entitlements.isPremium || entitlements.isFemale) return false;

    final prefs = await SharedPreferences.getInstance();
    final sessionStart = prefs.getInt(_kSwipeSessionMs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Reset swipe count if session is older than 60 minutes
    if (now - sessionStart > 60 * 60 * 1000) {
      await prefs.setInt(_kSwipeSessionMs, now);
      await prefs.setInt(_kSwipeCount, 0);
    }

    final count = (prefs.getInt(_kSwipeCount) ?? 0) + 1;
    await prefs.setInt(_kSwipeCount, count);

    if (count >= _kSwipeLimitTrigger) {
      await prefs.setInt(_kSwipeCount, 0); // reset so it fires again after another 15
      return maybeShow(context, ref, PaywallReason.swipeLimit);
    }
    return false;
  }

  /// Core method: shows the paywall if cooldown allows.
  /// Returns true if paywall was actually shown.
  static Future<bool> maybeShow(
    BuildContext context,
    WidgetRef ref,
    PaywallReason reason, {
    bool inChat = false,
  }) async {
    if (inChat) return false;

    final entitlements = ref.read(entitlementsProvider);
    if (entitlements.isPremium) return false;

    // Female users are not hard-gated on most things; only show for explicit hard gates
    if (entitlements.isFemale &&
        reason != PaywallReason.photoLimit &&
        reason != PaywallReason.matchAccepted) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 30-minute cooldown
    final lastShown = prefs.getInt(_kLastShownMs) ?? 0;
    if (now - lastShown < _kMinIntervalMs) return false;

    // Max 2 per day
    final today = _dateKey(DateTime.now());
    final dailyDate = prefs.getString(_kDailyDate) ?? '';
    int dailyCount = dailyDate == today ? (prefs.getInt(_kDailyCount) ?? 0) : 0;
    if (dailyCount >= _kMaxPerDay) return false;

    // All checks passed — update state and show
    await prefs.setInt(_kLastShownMs, now);
    await prefs.setString(_kDailyDate, today);
    await prefs.setInt(_kDailyCount, dailyCount + 1);

    if (context.mounted) {
      context.push('/premium?reason=${reason.queryParam}');
    }
    return true;
  }

  /// Check if the user has been active for [_kStreakDays] consecutive days
  /// and trigger the streak paywall if so.
  static Future<bool> maybeShowStreakPaywall(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kActiveDays) ?? '';
    if (raw.isEmpty) return false;

    final days = raw.split(',');
    if (days.length < _kStreakDays) return false;

    // Check that the last N days are consecutive
    final today = DateTime.now();
    bool isStreak = true;
    for (int i = 0; i < _kStreakDays; i++) {
      final expected = _dateKey(today.subtract(Duration(days: i)));
      if (!days.contains(expected)) {
        isStreak = false;
        break;
      }
    }

    if (isStreak) {
      return maybeShow(context, ref, PaywallReason.dayStreak);
    }
    return false;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// ── Session swipe counter provider (Riverpod) ─────────────────────────────────

/// Tracks how many profiles have been viewed this session for swipe-limit trigger.
/// Increment this in the discovery screen on each card view.
final sessionSwipeCountProvider = StateProvider<int>((ref) => 0);
