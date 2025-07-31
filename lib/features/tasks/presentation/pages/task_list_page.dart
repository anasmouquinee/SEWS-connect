import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tasks = [
    {
      'id': 'TSK001',
      'title': 'Machine M-205 Inspection',
      'description': 'Routine maintenance check for conveyor belt system',
      'priority': 'High',
      'assignedTo': 'You',
      'machineId': 'M-205',
      'status': 'claimed',
      'department': 'Maintenance',
      'dueDate': '2024-01-15',
      'progress': 0.0,
    },
    {
      'id': 'TSK002',
      'title': 'Network Switch Replacement',
      'description': 'Replace faulty network switch in Building A',
      'priority': 'Medium',
      'assignedTo': 'Available',
      'machineId': 'NET-A15',
      'status': 'available',
      'department': 'IT',
      'dueDate': '2024-01-16',
      'progress': 0.0,
    },
    {
      'id': 'TSK003',
      'title': 'Quality Check Station Calibration',
      'description': 'Calibrate quality control sensors',
      'priority': 'Low',
      'assignedTo': 'You',
      'machineId': 'QC-12',
      'status': 'in_progress',
      'department': 'Quality Control',
      'dueDate': '2024-01-17',
      'progress': 0.6,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Tasks'),
            Tab(text: 'Available'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTasks(),
          _buildAvailableTasks(),
          _buildCompletedTasks(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/scanner'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildMyTasks() {
    final myTasks = _tasks.where((task) => task['assignedTo'] == 'You').toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myTasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(myTasks[index], showProgress: true);
      },
    );
  }

  Widget _buildAvailableTasks() {
    final availableTasks = _tasks.where((task) => task['status'] == 'available').toList();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableTasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(availableTasks[index], showClaimButton: true);
      },
    );
  }

  Widget _buildCompletedTasks() {
    // Mock completed tasks
    final completedTasks = [
      {
        'id': 'TSK004',
        'title': 'Maintenance Report Submission',
        'description': 'Submit weekly maintenance report',
        'priority': 'Medium',
        'assignedTo': 'You',
        'machineId': 'ADMIN',
        'status': 'completed',
        'department': 'Maintenance',
        'dueDate': '2024-01-10',
        'completedDate': '2024-01-10',
        'progress': 1.0,
      },
    ];
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedTasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(completedTasks[index], isCompleted: true);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, {
    bool showProgress = false,
    bool showClaimButton = false,
    bool isCompleted = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task['priority']!).withOpacity(0.1),
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
                Text(
                  'Due: ${task['dueDate']}',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            if (showProgress && task['progress'] > 0)
              Column(
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task['progress'],
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(task['status']!),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(task['progress'] * 100).round()}% Complete',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
          ],
        ),
        trailing: showClaimButton
            ? ElevatedButton(
                onPressed: () => _claimTask(task),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(60, 30),
                ),
                child: const Text(
                  'Claim',
                  style: TextStyle(fontSize: 12),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description:',
                  style: TextStyle(
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
                if (isCompleted) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed: ${task['completedDate']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (!isCompleted && task['assignedTo'] == 'You')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateTaskProgress(task),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            task['status'] == 'claimed' ? 'Start Task' : 'Update Progress',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/scanner'),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Machine'),
                        ),
                      ),
                    ],
                  ),
                if (showClaimButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/scanner'),
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
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.blue;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return AppTheme.primaryColor;
      case 'claimed': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getTaskIcon(String department) {
    switch (department) {
      case 'Maintenance': return Icons.build;
      case 'IT': return Icons.computer;
      case 'Quality Control': return Icons.verified;
      default: return Icons.task;
    }
  }

  void _claimTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Claim Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You are about to claim this task. Once claimed, it will be assigned to you.'),
              const SizedBox(height: 16),
              Text(
                'Task: ${task['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  task['assignedTo'] = 'You';
                  task['status'] = 'claimed';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Task "${task['title']}" claimed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Claim Task'),
            ),
          ],
        );
      },
    );
  }

  void _updateTaskProgress(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double progress = task['progress'];
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Progress'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Task: ${task['title']}'),
                  const SizedBox(height: 16),
                  Text('Progress: ${(progress * 100).round()}%'),
                  Slider(
                    value: progress,
                    onChanged: (value) {
                      setDialogState(() {
                        progress = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      task['progress'] = progress;
                      if (progress >= 1.0) {
                        task['status'] = 'completed';
                      } else if (progress > 0) {
                        task['status'] = 'in_progress';
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Progress updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
