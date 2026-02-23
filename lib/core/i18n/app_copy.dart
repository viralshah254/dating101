import 'package:flutter/material.dart';

import '../mode/app_mode.dart';
import '../../l10n/app_localizations.dart';

/// Mode-aware copy: use l10n keys and choose wording by [AppMode].
/// Use S.of(context) for raw strings; this layer adds mode-specific CTAs.
class AppCopy {
  AppCopy._();

  /// Primary action on a profile card: "Send Thoughtful Intro" vs "Express Interest".
  static String ctaSendPrimary(BuildContext context, AppMode mode) {
    final l = AppLocalizations.of(context)!;
    switch (mode) {
      case AppMode.dating:
        return l.ctaSendIntro;
      case AppMode.matrimony:
        return l.ctaSendInterest;
    }
  }

  /// Discovery / Matches tab title.
  static String discoveryTitle(BuildContext context, AppMode mode) {
    final l = AppLocalizations.of(context)!;
    switch (mode) {
      case AppMode.dating:
        return l.discoverTitle;
      case AppMode.matrimony:
        return l.navMatches;
    }
  }

  /// Paywall subtitle.
  static String paywallSubtitle(BuildContext context, AppMode mode) {
    final l = AppLocalizations.of(context)!;
    switch (mode) {
      case AppMode.dating:
        return l.paywallDatingSubtitle;
      case AppMode.matrimony:
        return l.paywallMatrimonySubtitle;
    }
  }
}
