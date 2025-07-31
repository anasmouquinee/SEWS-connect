import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _isScanning = false;
  String? _scannedCode;
  Map<String, dynamic>? _machineInfo;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // Mock machine database
  final Map<String, Map<String, dynamic>> _machineDatabase = {
    'M-205': {
      'name': 'Conveyor Belt System',
      'location': 'Building A - Floor 2',
      'department': 'Production',
      'status': 'operational',
      'lastMaintenance': '2024-01-10',
      'nextMaintenance': '2024-01-24',
      'tasks': [
        {
          'id': 'TSK001',
          'title': 'Routine Inspection',
          'priority': 'High',
          'description': 'Check belt tension and lubrication',
        }
      ],
    },
    'QC-12': {
      'name': 'Quality Control Station',
      'location': 'Building B - Floor 1',
      'department': 'Quality Control',
      'status': 'maintenance_required',
      'lastMaintenance': '2024-01-05',
      'nextMaintenance': '2024-01-20',
      'tasks': [
        {
          'id': 'TSK003',
          'title': 'Sensor Calibration',
          'priority': 'Medium',
          'description': 'Calibrate quality control sensors',
        }
      ],
    },
    'NET-A15': {
      'name': 'Network Switch',
      'location': 'Building A - Server Room',
      'department': 'IT',
      'status': 'error',
      'lastMaintenance': '2024-01-08',
      'nextMaintenance': '2024-01-22',
      'tasks': [
        {
          'id': 'TSK002',
          'title': 'Replace Network Switch',
          'priority': 'High',
          'description': 'Replace faulty network switch',
        }
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR/Barcode Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Column(
        children: [
          // Scanner Area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isScanning
                  ? _buildScanningView()
                  : _buildScannerPlaceholder(),
            ),
          ),

          // Scanner Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? _stopScanning : _startScanning,
                    icon: Icon(_isScanning ? Icons.stop : Icons.qr_code_scanner),
                    label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScanning ? Colors.red : AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _simulateQRScan,
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Demo QR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _simulateBarcodeScan,
                        icon: const Icon(Icons.barcode_reader),
                        label: const Text('Demo Barcode'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Scanned Result
          if (_scannedCode != null) ...[
            const Divider(),
            Expanded(
              flex: 2,
              child: _buildScannedResult(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          // Mobile Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Scanning overlay
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Position QR code or barcode within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Ready to Scan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap "Start Scanning" to begin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedResult() {
    if (_machineInfo == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Machine Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.precision_manufacturing,
                        color: _getStatusColor(_machineInfo!['status']),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _machineInfo!['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_machineInfo!['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _machineInfo!['status'].toString().replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(_machineInfo!['status']),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, 'Location', _machineInfo!['location']),
                  _buildInfoRow(Icons.business, 'Department', _machineInfo!['department']),
                  _buildInfoRow(Icons.build, 'Last Maintenance', _machineInfo!['lastMaintenance']),
                  _buildInfoRow(Icons.schedule, 'Next Maintenance', _machineInfo!['nextMaintenance']),
                ],
              ),
            ),
          ),

          // Available Tasks
          if (_machineInfo!['tasks'] != null && _machineInfo!['tasks'].isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Available Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._machineInfo!['tasks'].map<Widget>((task) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPriorityColor(task['priority']),
                    child: const Icon(
                      Icons.task,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(task['title']),
                  subtitle: Text(task['description']),
                  trailing: ElevatedButton(
                    onPressed: () => _claimTask(task),
                    child: const Text('Claim'),
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'operational':
        return Colors.green;
      case 'maintenance_required':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
    });
    cameraController.start();
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
    cameraController.stop();
  }

  void _handleScannedCode(String code) {
    if (_scannedCode != code) {
      cameraController.stop();
      _handleScanResult(code);
    }
  }

  void _simulateQRScan() {
    // Simulate scanning machine M-205
    _handleScanResult('M-205');
  }

  void _simulateBarcodeScan() {
    // Simulate scanning network switch
    _handleScanResult('NET-A15');
  }

  void _handleScanResult(String code) {
    setState(() {
      _scannedCode = code;
      _machineInfo = _machineDatabase[code];
      _isScanning = false;
    });

    if (_machineInfo != null) {
      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Machine ${_machineInfo!['name']} scanned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show error for unknown code
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unknown machine code: $code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _claimTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Task Claimed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully claimed the task: ${task['title']}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The task has been assigned to you and added to your task list.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue Scanning'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/tasks');
              },
              child: const Text('View Tasks'),
            ),
          ],
        );
      },
    );
  }
}
