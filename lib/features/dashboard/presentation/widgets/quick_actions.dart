import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickAction(
            context,
            'Scan QR',
            Icons.qr_code_scanner,
            AppTheme.primaryColor,
            () => context.go('/scanner'),
          ),
          _buildQuickAction(
            context,
            'Start Call',
            Icons.phone,
            AppTheme.secondaryColor,
            () => context.go('/call'),
          ),
          _buildQuickAction(
            context,
            'New Meeting',
            Icons.video_call,
            AppTheme.accentColor,
            () => context.go('/meeting'),
          ),
          _buildQuickAction(
            context,
            'Messages',
            Icons.chat,
            AppTheme.itColor,
            () => context.go('/chat'),
          ),
          _buildQuickAction(
            context,
            'Tasks',
            Icons.task_alt,
            AppTheme.maintenanceColor,
            () => context.go('/tasks'),
          ),
          _buildQuickAction(
            context,
            'Maintenance',
            Icons.build,
            AppTheme.productionColor,
            () => context.go('/maintenance'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
