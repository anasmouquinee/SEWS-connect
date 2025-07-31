import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DepartmentOverviewWidget extends StatelessWidget {
  const DepartmentOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Department Activity Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDepartmentItem(
              'Maintenance',
              45,
              12,
              8,
              AppTheme.maintenanceColor,
            ),
            const SizedBox(height: 12),
            _buildDepartmentItem(
              'Production',
              67,
              8,
              15,
              AppTheme.productionColor,
            ),
            const SizedBox(height: 12),
            _buildDepartmentItem(
              'Quality Assurance',
              23,
              5,
              3,
              AppTheme.qaColor,
            ),
            const SizedBox(height: 12),
            _buildDepartmentItem(
              'IT Support',
              12,
              2,
              1,
              AppTheme.itColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentItem(
    String name,
    int totalUsers,
    int activeTasks,
    int onlineUsers,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$totalUsers users',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$onlineUsers online • $activeTasks tasks',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
