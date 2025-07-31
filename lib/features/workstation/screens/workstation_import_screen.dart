import 'package:flutter/material.dart';
import '../models/workstation_model.dart';
import '../services/excel_import_service.dart';
import '../services/workstation_storage_service.dart';
import 'qr_scanner_screen.dart';
import 'workstation_list_screen.dart';

class WorkstationImportScreen extends StatefulWidget {
  const WorkstationImportScreen({super.key});

  @override
  State<WorkstationImportScreen> createState() => _WorkstationImportScreenState();
}

class _WorkstationImportScreenState extends State<WorkstationImportScreen> {
  bool _isImporting = false;
  List<WorkstationModel> _importedWorkstations = [];
  String _importStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWS Workstation Manager'),
        backgroundColor: const Color(0xFF1565C0), // SEWS Blue
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorkstationListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.factory,
                      size: 64,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SEWS Connect',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Workstation Management System',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Import Section
            const Text(
              'Import Workstation Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Import from File Button
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _importFromFile,
              icon: _isImporting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_upload),
              label: Text(_isImporting ? 'Importing...' : 'Import from Excel/CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // SEWS Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Import Sample Data Button
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _importSampleData,
              icon: const Icon(Icons.science),
              label: const Text('Import Sample Data (First 5 Rows)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF1565C0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Import Status
            if (_importStatus.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _importedWorkstations.isNotEmpty 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _importedWorkstations.isNotEmpty 
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _importedWorkstations.isNotEmpty 
                              ? Icons.check_circle
                              : Icons.info,
                          color: _importedWorkstations.isNotEmpty 
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Import Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_importStatus),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Imported Data Preview
            if (_importedWorkstations.isNotEmpty) ...[
              const Text(
                'Imported Workstations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _importedWorkstations.length,
                    itemBuilder: (context, index) {
                      final workstation = _importedWorkstations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1565C0),
                          child: Text(
                            workstation.workStation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('${workstation.workStation} - ${workstation.project}'),
                        subtitle: Text(
                          'Qty: ${workstation.quantity} | Status: ${workstation.workstepProgress} | Priority: ${workstation.priority}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(workstation.workstepProgress),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${workstation.completionPercentage.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              // Empty State
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workstation data imported yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Import your Excel/CSV file to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _importedWorkstations.isEmpty ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkstationListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('View All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromFile() async {
    setState(() {
      _isImporting = true;
      _importStatus = 'Selecting file...';
    });

    try {
      final workstations = await ExcelImportService.importFromFile();
      
      if (workstations.isNotEmpty) {
        // Save to storage
        await WorkstationStorageService.saveWorkstations(workstations);
        
        setState(() {
          _importedWorkstations = workstations;
          _importStatus = 'Successfully imported ${workstations.length} workstations from your file!';
        });
      } else {
        setState(() {
          _importStatus = 'No data found in the selected file or import was cancelled.';
        });
      }
    } catch (e) {
      setState(() {
        _importStatus = 'Error importing file: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _importSampleData() async {
    setState(() {
      _isImporting = true;
      _importStatus = 'Loading sample data...';
    });

    try {
      // Use the sample CSV based on your provided data
      final sampleCSV = ExcelImportService.createSampleCSV();
      final workstations = await ExcelImportService.importFromCSVContent(sampleCSV);
      
      if (workstations.isNotEmpty) {
        // Save to storage
        await WorkstationStorageService.saveWorkstations(workstations);
        
        setState(() {
          _importedWorkstations = workstations;
          _importStatus = 'Successfully imported ${workstations.length} sample workstations! These match the structure of your Excel data.';
        });
      } else {
        setState(() {
          _importStatus = 'Failed to load sample data.';
        });
      }
    } catch (e) {
      setState(() {
        _importStatus = 'Error loading sample data: $e';
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
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
