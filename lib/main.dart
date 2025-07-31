import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'core/app.dart';
import 'core/services/hive_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/call_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with REAL data for all platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
    
    // Initialize local storage
    await HiveService.init();
    debugPrint('✅ Hive storage initialized');
    
    // Initialize call service with Firestore connectivity test
    try {
      await CallService.initialize();
      debugPrint('✅ Call service initialized');
    } catch (e) {
      debugPrint('⚠️ Call service initialization failed: $e');
    }
    
    // Seed initial Firebase data if needed (non-blocking)
    if (!kIsWeb) {
      FirebaseService.seedInitialData().catchError((error) {
        debugPrint('⚠️ Firebase seeding failed: $error');
      });
    }
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: SEWSConnectApp(),
    ),
  );
}
