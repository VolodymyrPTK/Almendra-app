import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDO4sBYIDZlWsKTFrmUfgG1ZATkRbqumNE',
    appId: '1:673059035521:web:59332f550787711fe47080',
    messagingSenderId: '673059035521',
    projectId: 'almendra-a411d',
    authDomain: 'almendra-a411d.firebaseapp.com',
    databaseURL:
        'https://almendra-a411d-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'almendra-a411d.appspot.com',
    measurementId: 'G-BPLB9LX991',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDO4sBYIDZlWsKTFrmUfgG1ZATkRbqumNE',
    appId: '1:673059035521:android:0000000000000001',
    messagingSenderId: '673059035521',
    projectId: 'almendra-a411d',
    storageBucket: 'almendra-a411d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDO4sBYIDZlWsKTFrmUfgG1ZATkRbqumNE',
    appId: '1:673059035521:ios:0000000000000001',
    messagingSenderId: '673059035521',
    projectId: 'almendra-a411d',
    storageBucket: 'almendra-a411d.appspot.com',
  );
}
