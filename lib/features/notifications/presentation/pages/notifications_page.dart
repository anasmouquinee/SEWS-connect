import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Machine M-205 Alert',
        'message': 'Temperature sensor reading above normal levels - Immediate attention required',
        'time': '5 min ago',
        'priority': 'high',
        'department': 'Maintenance',
        'read': false,
      },
      {
        'title': 'Task Assignment',
        'message': 'New maintenance task assigned for Machine QC-12',
        'time': '15 min ago',
        'priority': 'medium',
        'department': 'Maintenance',
        'read': false,
      },
      {
        'title': 'System Update',
        'message': 'Network maintenance scheduled for tonight 11 PM - 2 AM',
        'time': '1 hour ago',
        'priority': 'low',
        'department': 'IT',
        'read': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: notification['read'] as bool ? null : AppTheme.primaryColor.withOpacity(0.05),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getPriorityColor(notification['priority']! as String),
                child: Icon(
                  _getDepartmentIcon(notification['department']! as String),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                notification['title']! as String,
                style: TextStyle(
                  fontWeight: notification['read'] as bool ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['message']! as String),
                  const SizedBox(height: 4),
                  Text(
                    notification['time']! as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: notification['priority'] == 'high'
                  ? const Icon(Icons.priority_high, color: Colors.red)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  IconData _getDepartmentIcon(String department) {
    switch (department) {
      case 'Maintenance': return Icons.build;
      case 'IT': return Icons.computer;
      case 'Production': return Icons.factory;
      default: return Icons.business;
    }
  }
}
