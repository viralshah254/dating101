import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Wraps Google Play In-App Updates API.
///
/// - [forceUpdate] = true  → [AppUpdateType.immediate]: full-screen Play UI,
///   app cannot be used until the user installs the update.
/// - [forceUpdate] = false → [AppUpdateType.flexible]: background download,
///   shows a "Restart to update" snackbar when done.
///
/// Only runs on Android. Silently skips on iOS (App Store handles updates there)
/// and in non-Play-Store installs (debug / sideloaded APKs).
class AppUpdateService {
  AppUpdateService._();

  /// Call on app start and on foreground resume.
  static Future<void> checkForUpdate({required bool forceUpdate}) async {
    if (!Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

      if (forceUpdate) {
        // Blocks the app — user must install before continuing.
        await InAppUpdate.performImmediateUpdate();
      } else {
        // Downloads in the background while the user keeps using the app.
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          // Download finished — trigger install (shows Google Play restart prompt).
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      // Expected in debug builds / APK sideloads — not installed from Play Store.
      if (kDebugMode) debugPrint('[AppUpdate] skipped: $e');
    }
  }
}
