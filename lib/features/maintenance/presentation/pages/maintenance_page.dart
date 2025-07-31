import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Status Overview
            const Text(
              'Equipment Status Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusCards(),
            const SizedBox(height: 24),

            // Recent Activities
            const Text(
              'Recent Maintenance Activities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'Operational',
            '85',
            Colors.green,
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Maintenance',
            '12',
            Colors.orange,
            Icons.build,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Critical',
            '3',
            Colors.red,
            Icons.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, String count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {
        'machine': 'M-205',
        'activity': 'Routine Inspection Completed',
        'technician': 'John Doe',
        'time': '2 hours ago',
        'status': 'completed',
      },
      {
        'machine': 'QC-12',
        'activity': 'Sensor Calibration In Progress',
        'technician': 'Sarah Wilson',
        'time': '4 hours ago',
        'status': 'in_progress',
      },
    ];

    return Column(
      children: activities.map((activity) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getActivityStatusColor(activity['status']!),
              child: const Icon(Icons.build, color: Colors.white),
            ),
            title: Text(activity['activity']!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Machine: ${activity['machine']}'),
                Text('Technician: ${activity['technician']}'),
                Text('Time: ${activity['time']}'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getActivityStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'pending': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
