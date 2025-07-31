import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "your-web-api-key",
    authDomain: "sews-connect.firebaseapp.com",
    projectId: "sews-connect",
    storageBucket: "sews-connect.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef123456",
    measurementId: "G-ABCDEFGHIJ",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "your-android-api-key",
    appId: "1:123456789:android:abcdef123456",
    messagingSenderId: "123456789",
    projectId: "sews-connect",
    storageBucket: "sews-connect.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "your-ios-api-key",
    appId: "1:123456789:ios:abcdef123456",
    messagingSenderId: "123456789",
    projectId: "sews-connect",
    storageBucket: "sews-connect.appspot.com",
    iosBundleId: "com.example.sewsConnect",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "your-web-api-key",
    authDomain: "sews-connect.firebaseapp.com",
    projectId: "sews-connect",
    storageBucket: "sews-connect.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef123456",
    measurementId: "G-ABCDEFGHIJ",
  );
}
