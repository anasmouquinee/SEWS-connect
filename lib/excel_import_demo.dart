import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/workstation/services/workstation_storage_service.dart';
import 'features/workstation/services/excel_import_service.dart';
import 'features/workstation/models/workstation_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Workstation Storage
  await WorkstationStorageService.initialize();
  
  runApp(const ExcelImportDemo());
}

class ExcelImportDemo extends StatelessWidget {
  const ExcelImportDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEWS Excel Import Demo',
      theme: ThemeData(
        primaryColor: const Color(0xFF1565C0),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
      ),
      home: const ImportDemoScreen(),
    );
  }
}

class ImportDemoScreen extends StatefulWidget {
  const ImportDemoScreen({super.key});

  @override
  State<ImportDemoScreen> createState() => _ImportDemoScreenState();
}

class _ImportDemoScreenState extends State<ImportDemoScreen> {
  List<WorkstationModel> _workstations = [];
  bool _isLoading = false;
  String _status = 'Ready to import';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWS Excel Import Demo'),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _workstations.isNotEmpty ? Icons.check_circle : Icons.info,
                      size: 48,
                      color: _workstations.isNotEmpty ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Import Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _importYourExcelData,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.table_chart),
              label: Text(_isLoading ? 'Importing...' : 'Import Your Excel Data (First 5 Rows)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _importFromFile,
              icon: const Icon(Icons.file_upload),
              label: const Text('Import from CSV/Excel File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: _workstations.isEmpty ? null : _clearData,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Data'),
            ),
            
            const SizedBox(height: 24),
            
            // Results
            if (_workstations.isNotEmpty) ...[
              Text(
                'Imported Workstations (${_workstations.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _workstations.length,
                    itemBuilder: (context, index) {
                      final ws = _workstations[index];
                      return ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1565C0),
                          child: Text(
                            ws.workStation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('${ws.workStation} - Project: ${ws.project}'),
                        subtitle: Text(
                          'Qty: ${ws.quantity} | Status: ${ws.workstepProgress} | Priority: ${ws.priority}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Work Station', ws.workStation),
                                _buildDetailRow('Project', ws.project),
                                _buildDetailRow('Quantity', ws.quantity.toString()),
                                _buildDetailRow('Workstep Progress', ws.workstepProgress),
                                _buildDetailRow('Micrograph Progress', ws.micrographProgress),
                                _buildDetailRow('Priority', ws.priority),
                                _buildDetailRow('Prototyping', ws.prototyping),
                                _buildDetailRow('Good Parts', ws.goodParts),
                                if (ws.creationDate != null)
                                  _buildDetailRow('Creation Date', ws.creationDate.toString()),
                                if (ws.targetDate != null)
                                  _buildDetailRow('Target Date', ws.targetDate.toString()),
                                if (ws.qrCode != null)
                                  _buildDetailRow('QR Code', ws.qrCode!),
                                _buildDetailRow('Department', ws.department),
                                _buildDetailRow('Status', ws.status),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data imported yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click "Import Your Excel Data" to see your workstation data',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _importYourExcelData() async {
    setState(() {
      _isLoading = true;
      _status = 'Importing your Excel data structure...';
    });

    try {
      // This uses your exact Excel data structure
      final csvContent = '''Work Station,Project,Quantity,Workstep Progress,Micrograph Progress,Priority,Prototyping,Locked Look Reason,Good Parts,Creation Date,Target Date,Planned Start Date,Planned End Date,Actual Start Date,Actual End Date,Planned Setup Duration,Planned Production
M12,40,1000,finished,Not Requested,express,no,no,1000,28.06.2025 12:56:22,28.06.2025 22:00:00,28.06.2025 13:02:18,28.06.2025 15:56:18,28.06.2025 13:02:18,28.06.2025 15:56:18,13,179
M12,40,40,finished,Not Requested,express,no,no,40,28.06.2025 12:54:24,24.06.2025 22:00:00,28.06.2025 13:09:51,28.06.2025 13:48:05,1,234
M08,275,275,finished,Not Requested,express,no,no,275,28.06.2025 12:49:17,30.06.2025 22:00:00,28.06.2025 13:06:39,28.06.2025 13:30:45,1,14.2
CH18,175,175,finished,Not Requested,express,no,no,175,28.06.2025 12:41:35,28.06.2025 22:00:00,28.06.2025 13:01:02,28.06.2025 13:26:37,1,9.275
CH08,897,697,finished,Not Requested,express,no,no,697,28.06.2025 11:37:54,28.06.2025 22:00:00,28.06.2025 13:04:19,28.06.2025 14:20:50,1,26.446''';

      final workstations = await ExcelImportService.importFromCSVContent(csvContent);
      
      if (workstations.isNotEmpty) {
        // Save to storage
        await WorkstationStorageService.saveWorkstations(workstations);
        
        setState(() {
          _workstations = workstations;
          _status = '✅ Successfully imported ${workstations.length} workstations from your Excel structure!\n\nEach workstation now has:\n• QR Code generated\n• All your data fields\n• Ready for scanning and task assignment';
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${workstations.length} workstations successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _status = '❌ No workstations found in the data';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error importing data: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importFromFile() async {
    setState(() {
      _isLoading = true;
      _status = 'Opening file picker...';
    });

    try {
      final workstations = await ExcelImportService.importFromFile();
      
      if (workstations.isNotEmpty) {
        await WorkstationStorageService.saveWorkstations(workstations);
        
        setState(() {
          _workstations = workstations;
          _status = '✅ Successfully imported ${workstations.length} workstations from your file!';
        });
      } else {
        setState(() {
          _status = 'No file selected or no data found';
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error importing file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    await WorkstationStorageService.clearAllWorkstations();
    setState(() {
      _workstations = [];
      _status = 'Data cleared - ready to import';
    });
  }
}
