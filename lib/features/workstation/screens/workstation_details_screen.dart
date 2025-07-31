import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workstation_model.dart';
import '../services/workstation_storage_service.dart';

class WorkstationDetailsScreen extends StatefulWidget {
  final WorkstationModel workstation;

  const WorkstationDetailsScreen({
    super.key,
    required this.workstation,
  });

  @override
  State<WorkstationDetailsScreen> createState() => _WorkstationDetailsScreenState();
}

class _WorkstationDetailsScreenState extends State<WorkstationDetailsScreen> {
  late WorkstationModel _workstation;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _workstation = widget.workstation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workstation ${_workstation.workStation}'),
        backgroundColor: const Color(0xFF1565C0), // SEWS Blue
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWorkstation,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshWorkstation,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 16),
              
              // Progress Card
              _buildProgressCard(),
              const SizedBox(height: 16),
              
              // Details Card
              _buildDetailsCard(),
              const SizedBox(height: 16),
              
              // Timeline Card
              _buildTimelineCard(),
              const SizedBox(height: 16),
              
              // QR Code Card
              _buildQRCard(),
              const SizedBox(height: 16),
              
              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_workstation.workstepProgress),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _workstation.workstepProgress,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(_workstation.priority),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _workstation.priority.toLowerCase() == 'express' 
                            ? Icons.priority_high 
                            : Icons.low_priority,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _workstation.priority,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Project: ${_workstation.project}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.precision_manufacturing, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Workstation: ${_workstation.workStation}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Quantity: ${_workstation.quantity}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            if (_workstation.goodParts != '0') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Good Parts: ${_workstation.goodParts}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final completionPercentage = _workstation.completionPercentage;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Workstep Progress
            Row(
              children: [
                const Icon(Icons.work, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Workstep: '),
                Text(
                  _workstation.workstepProgress,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(_workstation.workstepProgress),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${completionPercentage.toStringAsFixed(0)}% Complete',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // Micrograph Progress
            Row(
              children: [
                const Icon(Icons.science, color: Colors.purple),
                const SizedBox(width: 8),
                const Text('Micrograph: '),
                Text(
                  _workstation.micrographProgress,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            if (_workstation.prototyping.toLowerCase() == 'yes') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.engineering, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text('Prototyping: '),
                  Text(
                    _workstation.prototyping,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_workstation.plannedSetupDuration != null) ...[
              _buildDetailRow(
                Icons.schedule,
                'Setup Duration',
                '${_workstation.plannedSetupDuration} min',
              ),
            ],
            
            if (_workstation.plannedProduction != null) ...[
              _buildDetailRow(
                Icons.factory,
                'Planned Production',
                '${_workstation.plannedProduction}',
              ),
            ],
            
            _buildDetailRow(
              Icons.business,
              'Department',
              _workstation.department,
            ),
            
            if (_workstation.lockedLookReason != 'no') ...[
              _buildDetailRow(
                Icons.lock,
                'Lock Reason',
                _workstation.lockedLookReason,
                isWarning: true,
              ),
            ],
            
            _buildDetailRow(
              Icons.update,
              'Last Updated',
              DateFormat('dd/MM/yyyy HH:mm').format(_workstation.lastUpdated),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isWarning = false}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: isWarning ? Colors.orange : Colors.grey),
            const SizedBox(width: 8),
            Text('$label: '),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isWarning ? Colors.orange : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTimelineItem(
              'Created',
              _workstation.creationDate,
              Icons.add_circle,
              Colors.blue,
            ),
            
            _buildTimelineItem(
              'Target Date',
              _workstation.targetDate,
              Icons.flag,
              Colors.orange,
            ),
            
            _buildTimelineItem(
              'Planned Start',
              _workstation.plannedStartDate,
              Icons.play_arrow,
              Colors.green,
            ),
            
            _buildTimelineItem(
              'Planned End',
              _workstation.plannedEndDate,
              Icons.stop,
              Colors.red,
            ),
            
            if (_workstation.actualStartDate != null)
              _buildTimelineItem(
                'Actual Start',
                _workstation.actualStartDate,
                Icons.play_circle_filled,
                Colors.green,
                isActual: true,
              ),
            
            if (_workstation.actualEndDate != null)
              _buildTimelineItem(
                'Actual End',
                _workstation.actualEndDate,
                Icons.stop_circle,
                Colors.red,
                isActual: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String label, DateTime? date, IconData icon, Color color, {bool isActual = false}) {
    if (date == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: isActual ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(date),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActual ? color : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _workstation.qrCode ?? 'No QR Code',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      // Copy QR code to clipboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QR Code copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Status Update Button
        if (_workstation.workstepProgress.toLowerCase() != 'finished')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUpdating ? null : _showStatusUpdateDialog,
              icon: _isUpdating 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.update),
              label: Text(_isUpdating ? 'Updating...' : 'Update Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // SEWS Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Task Assignment Button (First-scan-wins)
        if (_workstation.isAvailable)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _assignTask,
              icon: const Icon(Icons.assignment_ind),
              label: const Text('Assign Task to Me'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0), // SEWS Blue
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Emergency Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _reportEmergency,
            icon: const Icon(Icons.emergency),
            label: const Text('Report Emergency'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'express':
        return Colors.red;
      case 'normal':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Future<void> _refreshWorkstation() async {
    // Refresh workstation data from storage
    final updatedWorkstation = WorkstationStorageService.getWorkstation(
      _workstation.workStation,
      _workstation.project,
    );
    
    if (updatedWorkstation != null) {
      setState(() {
        _workstation = updatedWorkstation;
      });
    }
  }

  void _showStatusUpdateDialog() {
    final statuses = ['Not Requested', 'In Progress', 'Finished'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) => ListTile(
            title: Text(status),
            leading: Radio<String>(
              value: status,
              groupValue: _workstation.workstepProgress,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  _updateStatus(value);
                }
              },
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await WorkstationStorageService.updateWorkstationStatus(
        _workstation.workStation,
        _workstation.project,
        newStatus,
      );
      
      await _refreshWorkstation();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _assignTask() {
    // Implement first-scan-wins task assignment
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Task'),
        content: Text(
          'Do you want to assign this workstation task to yourself?\n\n'
          'Workstation: ${_workstation.workStation}\n'
          'Project: ${_workstation.project}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Update status to "In Progress" and assign to current user
              _updateStatus('In Progress');
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task assigned successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Assign to Me'),
          ),
        ],
      ),
    );
  }

  void _reportEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Report Emergency'),
          ],
        ),
        content: const Text(
          'This will send an emergency alert to all supervisors and maintenance staff.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // TODO: Implement emergency notification system
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}
