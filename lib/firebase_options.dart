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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyA9fn0hS3pAjteQlwDALmVnS0IwX-5PERQ',
    appId: '1:347670359263:web:a26b9f8b827847c7cb0d6a',
    messagingSenderId: '347670359263',
    projectId: 'emoticore',
    authDomain: 'emoticore.firebaseapp.com',
    storageBucket: 'emoticore.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAlrfxe4YemuJ7Qx2hIinZhPRYhOqewAp8',
    appId: '1:347670359263:android:f01117374ccbb21bcb0d6a',
    messagingSenderId: '347670359263',
    projectId: 'emoticore',
    storageBucket: 'emoticore.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHt9sQCrCvJJPyPB1jcJ9sqdj56yiSXEY',
    appId: '1:347670359263:ios:a5791db608a47809cb0d6a',
    messagingSenderId: '347670359263',
    projectId: 'emoticore',
    storageBucket: 'emoticore.firebasestorage.app',
    iosBundleId: 'com.example.emoticore',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBHt9sQCrCvJJPyPB1jcJ9sqdj56yiSXEY',
    appId: '1:347670359263:ios:a5791db608a47809cb0d6a',
    messagingSenderId: '347670359263',
    projectId: 'emoticore',
    storageBucket: 'emoticore.firebasestorage.app',
    iosBundleId: 'com.example.emoticore',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA9fn0hS3pAjteQlwDALmVnS0IwX-5PERQ',
    appId: '1:347670359263:web:c093f94d93f41bcfcb0d6a',
    messagingSenderId: '347670359263',
    projectId: 'emoticore',
    authDomain: 'emoticore.firebaseapp.com',
    storageBucket: 'emoticore.firebasestorage.app',
  );
}
