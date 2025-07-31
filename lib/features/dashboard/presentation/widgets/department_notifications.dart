import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DepartmentNotifications extends StatelessWidget {
  const DepartmentNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Machine M-205 Alert',
        'message': 'Temperature sensor reading above normal levels',
        'time': '5 min ago',
        'priority': 'high',
        'department': 'Maintenance',
      },
      {
        'title': 'System Update',
        'message': 'Network maintenance scheduled for tonight',
        'time': '1 hour ago',
        'priority': 'medium',
        'department': 'IT',
      },
      {
        'title': 'Production Target',
        'message': 'Daily production target achieved ahead of schedule',
        'time': '2 hours ago',
        'priority': 'low',
        'department': 'Production',
      },
    ];

    return Column(
      children: notifications.map((notification) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getPriorityColor(notification['priority']!),
                child: Icon(
                  _getDepartmentIcon(notification['department']!),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                notification['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['message']!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notification['time']!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(notification['priority']!)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          notification['department']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getPriorityColor(notification['priority']!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: notification['priority'] == 'high'
                  ? const Icon(
                      Icons.priority_high,
                      color: Colors.red,
                      size: 20,
                    )
                  : null,
              onTap: () {
                // Handle notification tap
                _showNotificationDetails(context, notification);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
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

  IconData _getDepartmentIcon(String department) {
    switch (department) {
      case 'Maintenance':
        return Icons.build;
      case 'IT':
        return Icons.computer;
      case 'Production':
        return Icons.factory;
      case 'HR':
        return Icons.people;
      default:
        return Icons.business;
    }
  }

  void _showNotificationDetails(BuildContext context, Map<String, String> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(notification['title']!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification['message']!),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification['time']!,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (notification['department'] == 'Maintenance')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to scanner for maintenance tasks
                },
                child: const Text('Scan QR Code'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Mark as acknowledged
              },
              child: const Text('Acknowledge'),
            ),
          ],
        );
      },
    );
  }
}
