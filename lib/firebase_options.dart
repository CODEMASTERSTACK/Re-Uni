// Firebase web config for UniDate (unidate-31873)
// https://firebase.google.com/docs/flutter/setup

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBItYhYTFanRwzkUcsjgthzmSbesROqe64',
    authDomain: 'unidate-31873.firebaseapp.com',
    projectId: 'unidate-31873',
    storageBucket: 'unidate-31873.firebasestorage.app',
    messagingSenderId: '1029379736941',
    appId: '1:1029379736941:web:06badc2613be894d90c664',
    measurementId: 'G-BEKF3P4CV9',
  );
}
