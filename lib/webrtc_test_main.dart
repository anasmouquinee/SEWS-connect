import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'webrtc_call_test.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await FirebaseService.initialize();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }
  
  runApp(const WebRTCTestApp());
}

class WebRTCTestApp extends StatelessWidget {
  const WebRTCTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEWS Connect - WebRTC Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1565C0),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
        ),
      ),
      home: const WebRTCTestHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebRTCTestHome extends StatelessWidget {
  const WebRTCTestHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWS Connect - WebRTC Test'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SEWS Logo Placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.factory,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 30),
            
            const Text(
              'SEWS Connect',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            
            const SizedBox(height: 10),
            
            const Text(
              'WebRTC Video Call Testing',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Test Features Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'WebRTC Features to Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    const ListTile(
                      leading: Icon(Icons.videocam, color: Color(0xFF1565C0)),
                      title: Text('Video Calls'),
                      subtitle: Text('HD video calling with camera controls'),
                    ),
                    
                    const ListTile(
                      leading: Icon(Icons.mic, color: Colors.green),
                      title: Text('Audio Calls'),
                      subtitle: Text('Clear audio with mute/unmute'),
                    ),
                    
                    const ListTile(
                      leading: Icon(Icons.settings, color: Colors.orange),
                      title: Text('Call Controls'),
                      subtitle: Text('Camera switch, video toggle, mute controls'),
                    ),
                    
                    const ListTile(
                      leading: Icon(Icons.cloud, color: Colors.purple),
                      title: Text('Firebase Signaling'),
                      subtitle: Text('Real-time signaling through Firebase'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Start Test Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WebRTCCallTestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_fill, size: 28),
                label: const Text(
                  'Start WebRTC Test',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info Text
            const Text(
              'This test will verify your WebRTC implementation is working correctly with camera, microphone, and Firebase signaling.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
