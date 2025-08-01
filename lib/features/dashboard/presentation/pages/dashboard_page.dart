import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/department_notifications.dart';
import '../widgets/active_tasks_widget.dart';
import '../../../calling/presentation/widgets/call_acceptance_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  String _currentDepartment = 'Maintenance';

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Messages',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.qr_code_scanner),
      label: 'Scanner',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.task),
      label: 'Tasks',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEWS Connect'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.go('/notifications'),
          ),
          // Admin Access Button
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.orange),
            tooltip: 'Admin Dashboard',
            onPressed: () => context.go('/admin'),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildDashboard() : _buildOtherPages(),
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
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
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Department: $_currentDepartment',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ready to tackle today\'s challenges?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Incoming Call Invitations
            const CallAcceptanceWidget(),
            const SizedBox(height: 20),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const QuickActions(),
            const SizedBox(height: 20),

            // Department Notifications
            const Text(
              'Department Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const DepartmentNotifications(),
            const SizedBox(height: 20),

            // Active Tasks
            const Text(
              'Active Tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const ActiveTasksWidget(),
            const SizedBox(height: 20),

            // Dashboard Stats
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Messages',
                    value: '24',
                    icon: Icons.chat,
                    color: AppTheme.primaryColor,
                    onTap: () => context.go('/chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: 'Tasks',
                    value: '7',
                    icon: Icons.task,
                    color: AppTheme.maintenanceColor,
                    onTap: () => context.go('/tasks'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Meetings',
                    value: '3',
                    icon: Icons.video_call,
                    color: AppTheme.secondaryColor,
                    onTap: () => context.go('/meeting'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardCard(
                    title: 'Scanned',
                    value: '12',
                    icon: Icons.qr_code,
                    color: AppTheme.itColor,
                    onTap: () => context.go('/scanner'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherPages() {
    switch (_selectedIndex) {
      case 1:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/chat');
        });
        break;
      case 2:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/scanner');
        });
        break;
      case 3:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/tasks');
        });
        break;
      case 4:
        // Profile page - would be implemented later
        break;
    }
    return const Center(child: CircularProgressIndicator());
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        setState(() {
          _selectedIndex = index;
        });
        break;
      case 1:
        context.go('/chat');
        break;
      case 2:
        context.go('/scanner');
        break;
      case 3:
        context.go('/tasks');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  Future<void> _refreshDashboard() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh data here
    });
  }
}
