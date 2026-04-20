import 'package:flutter/foundation.dart';

/// API environment configuration.
/// Set [useFakeBackend] to false and provide the real base URL to switch.
/// Default local API port matches [dating-backend] `PORT` (see `.env.example`).
/// Next.js (`shubhmilan_web`) dev server uses **3000** — keep the API on **8000** to avoid clashes.
class ApiConfig {
  const ApiConfig({
    this.baseUrl = 'http://localhost:8000',
    this.useFakeBackend = true,
  });

  final String baseUrl;
  final bool useFakeBackend;

  /// Production config.
  static const production = ApiConfig(
    baseUrl: 'https://api.shubhmilan.app',
    useFakeBackend: false,
  );

  /// Local dev with real backend.
  ///
  /// - **iOS Simulator / desktop:** `localhost` reaches your Mac.
  /// - **Android Emulator:** `10.0.2.2` is the host loopback (not `localhost`).
  /// - **Physical phone:** `localhost` is the phone — use your computer's LAN IP, e.g.
  ///   `flutter run --dart-define=API_BASE_URL=http://192.168.1.12:8000`
  static ApiConfig get localDev => ApiConfig(
    baseUrl: defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000',
    useFakeBackend: false,
  );
  

  /// Fake/mock backend (default for now).
  static const fake = ApiConfig(useFakeBackend: true);
}
