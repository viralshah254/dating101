// File generated from your Firebase config (GoogleService-Info.plist + google-services.json).
// Re-run `dart run flutterfire_cli:flutterfire configure` to regenerate.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwbDG-JRKT_D4vONYpNKocMv4gi_moaqg',
    appId: '1:450608436873:web:19043f88f8fc10812e1858',
    messagingSenderId: '450608436873',
    projectId: 'shubhmilan-app',
    authDomain: 'shubhmilan-app.firebaseapp.com',
    storageBucket: 'shubhmilan-app.firebasestorage.app',
    measurementId: 'G-6N9DKEVVB0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAir75Ia4KBUKRXpt_kvkPWemydHRbIyBw',
    appId: '1:1067844155109:android:1746f538ac45add7fa060c',
    messagingSenderId: '1067844155109',
    projectId: 'shubhmilan-app',
    storageBucket: 'shubhmilan-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAW3f1H34EfhL3bkPhQ0_qYFiZiPJQ64G4',
    appId: '1:1067844155109:ios:971036ac32da087cfa060c',
    messagingSenderId: '1067844155109',
    projectId: 'shubhmilan-app',
    storageBucket: 'shubhmilan-app.firebasestorage.app',
    iosBundleId: 'com.dvtechventures.shubhmilan',
  );
}
