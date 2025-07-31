import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/workstation/services/workstation_storage_service.dart';
import 'features/workstation/screens/workstation_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Workstation Storage
  await WorkstationStorageService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEWS Connect Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1565C0), // SEWS Blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          secondary: const Color(0xFF4CAF50), // SEWS Green
        ),
        useMaterial3: true,
      ),
      home: const WorkstationTestApp(),
    );
  }
}

class WorkstationTestApp extends StatelessWidget {
  const WorkstationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWS Connect - Workstation Test'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.factory,
                size: 100,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(height: 24),
              const Text(
                'SEWS Connect',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Workstation Management System',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkstationTestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.science),
                label: const Text('Test Workstation System'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'This will test:\n'
                '• Excel/CSV import with your data structure\n'
                '• QR code generation and scanning\n'
                '• Workstation management\n'
                '• First-scan-wins task assignment\n'
                '• Local storage with Hive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
