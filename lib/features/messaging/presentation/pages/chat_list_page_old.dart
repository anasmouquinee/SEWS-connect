import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final List<Map<String, dynamic>> _conversations = [
    {
      'id': 'dept_maintenance',
      'name': 'Maintenance Team',
      'type': 'department',
      'lastMessage': 'Machine M-205 inspection completed',
      'timestamp': '10:30 AM',
      'unreadCount': 3,
      'participants': ['John Doe', 'Sarah Wilson', 'Mike Johnson'],
      'isOnline': true,
    },
    {
      'id': 'dept_it',
      'name': 'IT Support',
      'type': 'department',
      'lastMessage': 'Network maintenance scheduled for tonight',
      'timestamp': '9:45 AM',
      'unreadCount': 1,
      'participants': ['Alex Chen', 'Maria Garcia'],
      'isOnline': true,
    },
    {
      'id': 'user_john',
      'name': 'John Doe',
      'type': 'direct',
      'lastMessage': 'Thanks for the help with the conveyor issue',
      'timestamp': 'Yesterday',
      'unreadCount': 0,
      'department': 'Maintenance',
      'isOnline': false,
    },
    {
      'id': 'group_emergency',
      'name': 'Emergency Response',
      'type': 'emergency',
      'lastMessage': 'All clear - Issue resolved',
      'timestamp': '2 days ago',
      'unreadCount': 0,
      'participants': ['Emergency Team'],
      'isOnline': true,
    },
    {
      'id': 'dept_production',
      'name': 'Production Floor',
      'type': 'department',
      'lastMessage': 'Daily target achieved ahead of schedule',
      'timestamp': '3 days ago',
      'unreadCount': 0,
      'participants': ['Production Team'],
      'isOnline': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showNewChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Access Buttons
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickAccessButton(
                  'Emergency',
                  Icons.emergency,
                  Colors.red,
                  () => _startEmergencyChat(),
                ),
                _buildQuickAccessButton(
                  'Maintenance',
                  Icons.build,
                  AppTheme.maintenanceColor,
                  () => _openDepartmentChat('dept_maintenance'),
                ),
                _buildQuickAccessButton(
                  'IT Support',
                  Icons.computer,
                  AppTheme.itColor,
                  () => _openDepartmentChat('dept_it'),
                ),
                _buildQuickAccessButton(
                  'Production',
                  Icons.factory,
                  AppTheme.productionColor,
                  () => _openDepartmentChat('dept_production'),
                ),
              ],
            ),
          ),
          const Divider(),

          // Conversations List
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conversation = _conversations[index];
                return _buildConversationTile(conversation);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatOptions,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildQuickAccessButton(
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: _getConversationColor(conversation['type']),
            child: Icon(
              _getConversationIcon(conversation['type']),
              color: Colors.white,
              size: 20,
            ),
          ),
          if (conversation['isOnline'] == true)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation['name'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (conversation['type'] == 'emergency')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'EMERGENCY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversation['lastMessage'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: conversation['unreadCount'] > 0 
                  ? Colors.black87 
                  : Colors.grey[600],
              fontWeight: conversation['unreadCount'] > 0 
                  ? FontWeight.w500 
                  : FontWeight.normal,
            ),
          ),
          if (conversation['participants'] != null)
            Text(
              '${conversation['participants'].length} participants',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation['timestamp'],
            style: TextStyle(
              fontSize: 12,
              color: conversation['unreadCount'] > 0 
                  ? AppTheme.primaryColor 
                  : Colors.grey[500],
              fontWeight: conversation['unreadCount'] > 0 
                  ? FontWeight.w600 
                  : FontWeight.normal,
            ),
          ),
          if (conversation['unreadCount'] > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                conversation['unreadCount'].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      onTap: () => _openChat(conversation['id']),
    );
  }

  Color _getConversationColor(String type) {
    switch (type) {
      case 'department':
        return AppTheme.primaryColor;
      case 'direct':
        return AppTheme.secondaryColor;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getConversationIcon(String type) {
    switch (type) {
      case 'department':
        return Icons.groups;
      case 'direct':
        return Icons.person;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.chat;
    }
  }

  void _openChat(String chatId) {
    context.go('/chat/$chatId');
  }

  void _openDepartmentChat(String departmentId) {
    context.go('/chat/$departmentId');
  }

  void _startEmergencyChat() {
    context.go('/chat/group_emergency');
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: ChatSearchDelegate(_conversations),
    );
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Start New Conversation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('New Direct Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showUserSelection();
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Create Group Chat'),
                onTap: () {
                  Navigator.pop(context);
                  _showGroupCreation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emergency, color: Colors.red),
                title: const Text('Emergency Broadcast'),
                onTap: () {
                  Navigator.pop(context);
                  _startEmergencyChat();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> conversations;

  ChatSearchDelegate(this.conversations);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredConversations = conversations
        .where((conversation) =>
            conversation['name'].toLowerCase().contains(query.toLowerCase()) ||
            conversation['lastMessage'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor,
            child: Icon(
              conversation['type'] == 'department' ? Icons.groups : Icons.person,
              color: Colors.white,
            ),
          ),
          title: Text(conversation['name']),
          subtitle: Text(conversation['lastMessage']),
          onTap: () {
            close(context, null);
            // Navigate to chat
          },
        );
      },
    );
  }

  void _showUserSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Start Direct Message'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                // Sample users - in real app, fetch from Firebase
                _buildUserTile('John Smith', 'Maintenance', 'user1'),
                _buildUserTile('Sarah Johnson', 'Production', 'user2'),
                _buildUserTile('Mike Wilson', 'Quality Control', 'user3'),
                _buildUserTile('Lisa Brown', 'Engineering', 'user4'),
                _buildUserTile('David Miller', 'Safety', 'user5'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserTile(String name, String department, String userId) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Text(
          name.split(' ').map((n) => n[0]).join(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(name),
      subtitle: Text(department),
      onTap: () async {
        Navigator.pop(context);
        
        // Create direct message room
        final roomId = await FirebaseService.createChatRoom(
          'Direct: $name', 
          'direct', 
          ['current_user', userId], 
          'current_user'
        );
        
        if (roomId != null && mounted) {
          context.go('/chat/$roomId');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create chat room')),
          );
        }
      },
    );
  }

  void _showGroupCreation() {
    final TextEditingController groupNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Group Chat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Members:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView(
                  children: [
                    CheckboxListTile(
                      title: const Text('John Smith - Maintenance'),
                      value: false,
                      onChanged: (value) {
                        // Handle member selection
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Sarah Johnson - Production'),
                      value: false,
                      onChanged: (value) {
                        // Handle member selection
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Mike Wilson - Quality Control'),
                      value: false,
                      onChanged: (value) {
                        // Handle member selection
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupNameController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  
                  // Create group chat room
                  final roomId = await FirebaseService.createChatRoom(
                    groupNameController.text.trim(),
                    'group',
                    ['current_user'], // Add selected members here
                    'current_user'
                  );
                  
                  if (roomId != null && mounted) {
                    context.go('/chat/$roomId');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to create group chat')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
