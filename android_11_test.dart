import 'package:flutter/material.dart';
import 'core/services/android_permission_service.dart';
import 'core/services/real_webrtc_service.dart';

/// Android 11+ WebRTC Test App
class Android11TestApp extends StatelessWidget {
  const Android11TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Android 11+ WebRTC Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PermissionTestScreen(),
    );
  }
}

class PermissionTestScreen extends StatefulWidget {
  const PermissionTestScreen({super.key});

  @override
  State<PermissionTestScreen> createState() => _PermissionTestScreenState();
}

class _PermissionTestScreenState extends State<PermissionTestScreen> {
  String _permissionStatus = 'Not checked';
  String _webrtcStatus = 'Not initialized';
  Map<String, String> _detailedStatus = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _permissionStatus = 'Checking permissions...';
    });

    try {
      // Test Android permission service
      final granted = await AndroidPermissionService.initializePermissionsForWebRTC();
      final detailed = await AndroidPermissionService.getPermissionStatus();
      
      // Test WebRTC initialization
      final webrtcInit = await RealWebRTCService.initialize();
      
      setState(() {
        _permissionStatus = granted ? 'All permissions granted ✅' : 'Some permissions denied ⚠️';
        _webrtcStatus = webrtcInit ? 'WebRTC initialized ✅' : 'WebRTC failed ❌';
        _detailedStatus = detailed;
      });
    } catch (e) {
      setState(() {
        _permissionStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Android 11+ WebRTC Test'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permission Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_permissionStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WebRTC Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_webrtcStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_detailedStatus.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detailed Permission Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._detailedStatus.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    color: entry.value.contains('granted') 
                                        ? Colors.green 
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkPermissions,
                child: const Text('Re-check Permissions'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await AndroidPermissionService.openSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Open App Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const Android11TestApp());
}
