import 'package:flutter/material.dart';
import '../services/workstation_storage_service.dart';
import '../services/excel_import_service.dart';
import '../models/workstation_model.dart';
import 'workstation_import_screen.dart';
import 'qr_scanner_screen.dart';
import 'workstation_list_screen.dart';

class WorkstationTestScreen extends StatefulWidget {
  const WorkstationTestScreen({super.key});

  @override
  State<WorkstationTestScreen> createState() => _WorkstationTestScreenState();
}

class _WorkstationTestScreenState extends State<WorkstationTestScreen> {
  bool _isInitialized = false;
  String _statusMessage = 'Not initialized';
  List<WorkstationModel> _testWorkstations = [];

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    try {
      await WorkstationStorageService.initialize();
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Storage initialized successfully';
      });
      debugPrint('✅ Workstation storage initialized');
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing storage: $e';
      });
      debugPrint('❌ Error initializing storage: $e');
    }
  }

  Future<void> _loadTestData() async {
    try {
      setState(() {
        _statusMessage = 'Loading test data...';
      });

      // Create sample CSV based on your Excel data
      final sampleCSV = ExcelImportService.createSampleCSV();
      final workstations = await ExcelImportService.importFromCSVContent(sampleCSV);

      if (workstations.isNotEmpty) {
        await WorkstationStorageService.saveWorkstations(workstations);
        
        setState(() {
          _testWorkstations = workstations;
          _statusMessage = 'Loaded ${workstations.length} test workstations successfully!';
        });
        
        debugPrint('✅ Test data loaded: ${workstations.length} workstations');
      } else {
        setState(() {
          _statusMessage = 'No test data found';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading test data: $e';
      });
      debugPrint('❌ Error loading test data: $e');
    }
  }

  Future<void> _clearData() async {
    try {
      await WorkstationStorageService.clearAllWorkstations();
      setState(() {
        _testWorkstations = [];
        _statusMessage = 'All data cleared';
      });
      debugPrint('✅ Data cleared');
    } catch (e) {
      setState(() {
        _statusMessage = 'Error clearing data: $e';
      });
      debugPrint('❌ Error clearing data: $e');
    }
  }

  void _testQRCodeLookup() {
    if (_testWorkstations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Load test data first!')),
      );
      return;
    }

    // Test QR code lookup with first workstation
    final firstWorkstation = _testWorkstations.first;
    final qrCode = firstWorkstation.qrCode;
    
    if (qrCode != null) {
      final foundWorkstation = WorkstationStorageService.getWorkstationByQR(qrCode);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            foundWorkstation != null 
                ? 'QR Lookup Test: Found ${foundWorkstation.workStation}'
                : 'QR Lookup Test: Not found'
          ),
          backgroundColor: foundWorkstation != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workstation System Test'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isInitialized ? Colors.green.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isInitialized ? Icons.check_circle : Icons.warning,
                      color: _isInitialized ? Colors.green : Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'System Status',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_statusMessage),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            const Text(
              'Test Functions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Load Test Data Button
            ElevatedButton.icon(
              onPressed: _isInitialized ? _loadTestData : null,
              icon: const Icon(Icons.science),
              label: const Text('Load Test Data (Your Excel Sample)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Test QR Lookup
            ElevatedButton.icon(
              onPressed: _isInitialized ? _testQRCodeLookup : null,
              icon: const Icon(Icons.qr_code),
              label: const Text('Test QR Code Lookup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Clear Data Button
            ElevatedButton.icon(
              onPressed: _isInitialized ? _clearData : null,
              icon: const Icon(Icons.delete),
              label: const Text('Clear All Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Navigation Buttons
            const Text(
              'Navigate to Screens',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Import Screen
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkstationImportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.file_upload),
              label: const Text('Import Screen'),
            ),
            
            const SizedBox(height: 8),
            
            // QR Scanner Screen
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QR Scanner Screen'),
            ),
            
            const SizedBox(height: 8),
            
            // List Screen
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkstationListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Workstation List Screen'),
            ),
            
            const Spacer(),
            
            // Test Data Preview
            if (_testWorkstations.isNotEmpty) ...[
              const Text(
                'Loaded Test Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _testWorkstations.length,
                  itemBuilder: (context, index) {
                    final ws = _testWorkstations[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1565C0),
                        radius: 16,
                        child: Text(
                          ws.workStation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${ws.workStation} - ${ws.project}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        'QR: ${ws.qrCode?.substring(0, 20)}...',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ws.workstepProgress),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ws.workstepProgress,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'finished':
        return Colors.green;
      case 'in progress':
        return Colors.orange;
      case 'not requested':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
