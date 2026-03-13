import 'package:flutter/foundation.dart';

/// API environment configuration.
/// Set [useFakeBackend] to false and provide the real base URL to switch.
class ApiConfig {
  const ApiConfig({
    this.baseUrl = 'http://localhost:3000',
    this.useFakeBackend = true,
  });

  final String baseUrl;
  final bool useFakeBackend;

  /// Production config.
  static const production = ApiConfig(
    baseUrl: 'https://api.saathi.app',
    useFakeBackend: false,
  );

  /// Local dev with real backend.
  /// Android emulators must use 10.0.2.2 to reach the host machine.
  static ApiConfig get localDev => ApiConfig(
    baseUrl: defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000',
       
    useFakeBackend: false,
  );
  

  /// Fake/mock backend (default for now).
  static const fake = ApiConfig(useFakeBackend: true);
}
