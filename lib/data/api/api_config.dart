import 'package:flutter/foundation.dart';

/// API environment configuration.
/// [repository_providers] defaults to [production] unless you pass
/// `--dart-define=API_ENV=localDev|fake` or `API_BASE_URL=...`.
class ApiConfig {
  const ApiConfig({
    this.baseUrl = 'http://localhost:8000',
    this.useFakeBackend = true,
  });

  final String baseUrl;
  final bool useFakeBackend;

  /// Production config.
  /// Live API (EC2 / load balancer). When you add HTTPS + `api.shubhmilan.app`, point this to
  /// `https://api.shubhmilan.app` and remove cleartext exceptions in iOS/Android.
  static const production = ApiConfig(
    baseUrl: 'http://34.237.17.228',
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
  

  /// Fake/mock backend. Enable with `--dart-define=API_ENV=fake`.
  static const fake = ApiConfig(useFakeBackend: true);
}
