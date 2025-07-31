import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ActiveTasksWidget extends StatelessWidget {
  const ActiveTasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      {
        'id': 'TSK001',
        'title': 'Machine M-205 Inspection',
        'description': 'Routine maintenance check for conveyor belt system',
        'priority': 'High',
        'assignedTo': 'Available',
        'machineId': 'M-205',
        'status': 'pending',
        'department': 'Maintenance',
      },
      {
        'id': 'TSK002',
        'title': 'Network Switch Replacement',
        'description': 'Replace faulty network switch in Building A',
        'priority': 'Medium',
        'assignedTo': 'Available',
        'machineId': 'NET-A15',
        'status': 'pending',
        'department': 'IT',
      },
      {
        'id': 'TSK003',
        'title': 'Quality Check Station',
        'description': 'Calibrate quality control sensors',
        'priority': 'Low',
        'assignedTo': 'John Doe',
        'machineId': 'QC-12',
        'status': 'in_progress',
        'department': 'Quality Control',
      },
    ];

    return Column(
      children: tasks.map((task) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            child: ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(task['status']!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTaskIcon(task['department']!),
                  color: _getStatusColor(task['status']!),
                  size: 20,
                ),
              ),
              title: Text(
                task['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Machine: ${task['machineId']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task['priority']!)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task['priority']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getPriorityColor(task['priority']!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task['status']!)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task['status']! == 'pending' ? 'Available' : 'In Progress',
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(task['status']!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: task['status'] == 'pending'
                  ? Icon(
                      Icons.qr_code_scanner,
                      color: AppTheme.primaryColor,
                      size: 24,
                    )
                  : Icon(
                      Icons.work,
                      color: Colors.orange,
                      size: 24,
                    ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task['description']!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Assigned to: ${task['assignedTo']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (task['status'] == 'pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _claimTask(context, task),
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan QR to Claim'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.primaryColor;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskIcon(String department) {
    switch (department) {
      case 'Maintenance':
        return Icons.build;
      case 'IT':
        return Icons.computer;
      case 'Quality Control':
        return Icons.verified;
      default:
        return Icons.task;
    }
  }

  void _claimTask(BuildContext context, Map<String, String> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Claim Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Scan the QR code on the machine to claim this task.'),
              const SizedBox(height: 16),
              Text(
                'Machine ID: ${task['machineId']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to scanner
                // context.go('/scanner');
              },
              child: const Text('Open Scanner'),
            ),
          ],
        );
      },
    );
  }
}
