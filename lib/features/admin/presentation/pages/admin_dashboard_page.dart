import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/user_management_widget.dart';
import '../widgets/department_overview_widget.dart';
import '../widgets/system_monitoring_widget.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.admin_panel_settings),
      label: 'Overview',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Users',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.business),
      label: 'Departments',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.monitor),
      label: 'System',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWS Admin Dashboard'),
        backgroundColor: AppTheme.adminColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => context.go('/admin/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.adminColor,
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildUserManagement();
      case 2:
        return _buildDepartmentManagement();
      case 3:
        return _buildSystemMonitoring();
      case 4:
        return _buildSettings();
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.adminColor, AppTheme.adminColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SEWS Connect System Control Center',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitor and manage your organization communications',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Stats
            const Text(
              'System Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AdminStatsCard(
                    title: 'Total Users',
                    value: '247',
                    icon: Icons.people,
                    color: AppTheme.primaryColor,
                    trend: '+5.2%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminStatsCard(
                    title: 'Active Now',
                    value: '89',
                    icon: Icons.online_prediction,
                    color: AppTheme.secondaryColor,
                    trend: '+12.1%',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AdminStatsCard(
                    title: 'Messages Today',
                    value: '1,432',
                    icon: Icons.message,
                    color: AppTheme.maintenanceColor,
                    trend: '+8.7%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminStatsCard(
                    title: 'QR Scans',
                    value: '156',
                    icon: Icons.qr_code_scanner,
                    color: AppTheme.itColor,
                    trend: '-2.1%',
                    isPositive: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Department Overview
            const Text(
              'Department Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const DepartmentOverviewWidget(),
            const SizedBox(height: 20),

            // System Health
            const Text(
              'System Health',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const SystemMonitoringWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    return const UserManagementWidget();
  }

  Widget _buildDepartmentManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.build, color: AppTheme.maintenanceColor),
              title: const Text('Maintenance Department'),
              subtitle: const Text('45 users • 12 active tasks'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/admin/department/maintenance'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.precision_manufacturing, color: AppTheme.productionColor),
              title: const Text('Production Department'),
              subtitle: const Text('67 users • 8 active tasks'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/admin/department/production'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check, color: AppTheme.qaColor),
              title: const Text('Quality Assurance'),
              subtitle: const Text('23 users • 5 active tasks'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/admin/department/qa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMonitoring() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Server Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusItem('Firebase', 'Online', Colors.green),
                  _buildStatusItem('WebSocket', 'Online', Colors.green),
                  _buildStatusItem('Agora RTC', 'Online', Colors.green),
                  _buildStatusItem('Database', 'Online', Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildMetricItem('Response Time', '125ms', Colors.green),
                  _buildMetricItem('Uptime', '99.9%', Colors.green),
                  _buildMetricItem('Error Rate', '0.01%', Colors.green),
                  _buildMetricItem('Active Connections', '89', Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              subtitle: const Text('Configure system notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/admin/settings/notifications'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Security Settings'),
              subtitle: const Text('Manage access controls'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/admin/settings/security'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup & Restore'),
              subtitle: const Text('Data backup configuration'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/admin/settings/backup'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.update),
              title: const Text('System Updates'),
              subtitle: const Text('Check for updates'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.go('/admin/settings/updates'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String service, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(status, style: TextStyle(color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String metric, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh admin data
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
