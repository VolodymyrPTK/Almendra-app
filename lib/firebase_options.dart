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
    databaseURL: 'https://almendra-a411d-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'almendra-a411d.appspot.com',
    measurementId: 'G-BPLB9LX991',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHlPzj1e537Z9r_ryzd0bVh-uX4hbsouI',
    appId: '1:673059035521:android:4f7216b7e0600cf6e47080',
    messagingSenderId: '673059035521',
    projectId: 'almendra-a411d',
    databaseURL: 'https://almendra-a411d-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'almendra-a411d.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwdRVyhcVC3xkqps-qqiBS2OSeGXhpBxQ',
    appId: '1:673059035521:ios:f3fd84296a27b937e47080',
    messagingSenderId: '673059035521',
    projectId: 'almendra-a411d',
    databaseURL: 'https://almendra-a411d-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'almendra-a411d.appspot.com',
    androidClientId: '673059035521-24u1g554st1ov0av11ptanj9g3ega5t5.apps.googleusercontent.com',
    iosClientId: '673059035521-7jhplak26g6ii2bno259t90tpuqm69g6.apps.googleusercontent.com',
    iosBundleId: 'com.example.almendra',
  );

}