import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyByuekHT6ISVDHhaLngcSMSz_LlAaWg64g',
    appId: '1:823813601514:web:d75f9e956c97ab91453f93',
    messagingSenderId: '823813601514',
    projectId: 'nwt-app-28415',
    authDomain: 'nwt-app-28415.firebaseapp.com',
    storageBucket: 'nwt-app-28415.firebasestorage.app',
    measurementId: 'G-N69XT4LQT5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDSVcrXmNbomQmBdFGduO2rOC-MWuJq6g',
    appId: '1:823813601514:android:4a89119dd051d1b0453f93',
    messagingSenderId: '823813601514',
    projectId: 'nwt-app-28415',
    storageBucket: 'nwt-app-28415.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB4zbVPVcbNa_aGQlkjGDjGSqpcZLbZF4Y',
    appId: '1:823813601514:ios:2615d9be0a1927e2453f93',
    messagingSenderId: '823813601514',
    projectId: 'nwt-app-28415',
    storageBucket: 'nwt-app-28415.firebasestorage.app',
    androidClientId: '823813601514-8bh26douaega0t2nhq6e6848s4lv36fn.apps.googleusercontent.com',
    iosClientId: '823813601514-3p4gu65jtjd6seg11u9p042emhaoaa2t.apps.googleusercontent.com',
    iosBundleId: 'com.app.networthtracker',
  );

}