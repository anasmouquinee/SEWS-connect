// Add this to your existing SEWS Connect app

import 'package:flutter/material.dart';
import 'features/workstation/screens/workstation_import_screen.dart';
import 'features/workstation/services/workstation_storage_service.dart';

class MyExistingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SEWS Connect')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your existing widgets...
            
            // Add this button to import workstation data
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkstationImportScreen(),
                  ),
                );
              },
              icon: Icon(Icons.factory),
              label: Text('Workstation Manager'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1565C0), // SEWS Blue
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Don't forget to initialize Hive in your main() function:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await WorkstationStorageService.initialize();
  
  runApp(MyApp());
}
