import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';

/// Reads the referral code from the Android Play Store install referrer string.
///
/// When a user taps the shared link `https://www.shubhmilan.app/download?ref=CODE`,
/// the download page forwards `referrer=ref%3DCODE` to the Play Store URL. After
/// install, this function parses that referrer string and returns `CODE`.
///
/// Returns null on iOS, desktop, or when no `ref` param is present.
Future<String?> readInstallReferralCode() async {
  if (kIsWeb) return null;
  if (defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    final details = await PlayInstallReferrer.installReferrer;
    final raw = details.installReferrer ?? '';
    if (raw.isEmpty) return null;
    // The referrer string is URL-encoded: "ref=GFLAE5DH" or "ref%3DGFLAE5DH"
    final decoded = Uri.decodeComponent(raw);
    final params = Uri.splitQueryString(decoded);
    final code = params['ref']?.trim();
    return (code != null && code.isNotEmpty) ? code : null;
  } catch (_) {
    return null;
  }
}
