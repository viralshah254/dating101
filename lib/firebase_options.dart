// File generated from your Firebase config (GoogleService-Info.plist + google-services.json).
// Re-run `dart run flutterfire_cli:flutterfire configure` to regenerate.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not supported. Use a mobile or desktop platform.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios; // Use iOS config for macOS if you add a macOS app in Firebase Console
      default:
        throw UnsupportedError('DefaultFirebaseOptions not supported for ${defaultTargetPlatform.name}');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAir75Ia4KBUKRXpt_kvkPWemydHRbIyBw',
    appId: '1:1067844155109:android:1746f538ac45add7fa060c',
    messagingSenderId: '1067844155109',
    projectId: 'saathi-2644b',
    storageBucket: 'saathi-2644b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAW3f1H34EfhL3bkPhQ0_qYFiZiPJQ64G4',
    appId: '1:1067844155109:ios:971036ac32da087cfa060c',
    messagingSenderId: '1067844155109',
    projectId: 'saathi-2644b',
    storageBucket: 'saathi-2644b.firebasestorage.app',
    iosBundleId: 'com.dvtechventures.saathi',
  );
}
