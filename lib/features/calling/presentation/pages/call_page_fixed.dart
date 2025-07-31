import 'package:flutter/material.dart';
import '../../../../core/services/mock_firebase_service.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isVideoOn = false;
  bool _isCallActive = false;
  String _callStatus = 'Ready to call';
  String _callDuration = '00:00';
  
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await MockFirebaseService.getUsers();
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final department = user['department']?.toString().toLowerCase() ?? '';
        return name.contains(query) || email.contains(query) || department.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.phone), text: 'Quick Call'),
            Tab(icon: Icon(Icons.search), text: 'Search Users'),
            Tab(icon: Icon(Icons.history), text: 'Recent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuickCallTab(),
          _buildSearchUsersTab(),
          _buildRecentCallsTab(),
        ],
      ),
    );
  }

  Widget _buildQuickCallTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Call Status Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  _isCallActive ? Icons.phone : Icons.phone_outlined,
                  size: 60,
                  color: _isCallActive ? Colors.green : Colors.blue[700],
                ),
                const SizedBox(height: 10),
                Text(
                  _callStatus,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  _callDuration,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Call Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCallControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: _isMuted ? 'Unmute' : 'Mute',
                onPressed: () => setState(() => _isMuted = !_isMuted),
                isActive: _isMuted,
                color: _isMuted ? Colors.red : Colors.blue,
              ),
              _buildCallControlButton(
                icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
                label: _isVideoOn ? 'Video Off' : 'Video On',
                onPressed: () => setState(() => _isVideoOn = !_isVideoOn),
                isActive: _isVideoOn,
                color: Colors.blue,
              ),
              _buildCallControlButton(
                icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                label: _isSpeakerOn ? 'Speaker Off' : 'Speaker On',
                onPressed: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                isActive: _isSpeakerOn,
                color: Colors.blue,
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Start/End Call Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _toggleCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCallActive ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isCallActive ? Icons.call_end : Icons.call),
                  const SizedBox(width: 10),
                  Text(
                    _isCallActive ? 'End Call' : 'Start Call',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchUsersTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name, email, or department...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
        ),
        
        // Users List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No users available'
                                : 'No users found matching "${_searchController.text}"',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserTile(user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRecentCallsTab() {
    final recentCalls = [
      {
        'name': 'John Smith',
        'type': 'audio',
        'time': '10:30 AM',
        'duration': '5:24',
        'status': 'completed',
      },
      {
        'name': 'Sarah Johnson',
        'type': 'video',
        'time': '9:15 AM',
        'duration': '12:45',
        'status': 'completed',
      },
      {
        'name': 'Mike Wilson',
        'type': 'audio',
        'time': 'Yesterday',
        'duration': '3:12',
        'status': 'missed',
      },
    ];

    return recentCalls.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.call_end, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No recent calls',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: recentCalls.length,
            itemBuilder: (context, index) {
              final call = recentCalls[index];
              return _buildRecentCallTile(call);
            },
          );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isOnline = user['isOnline'] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[700],
              child: Text(
                user['avatar'] ?? user['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user['name'] ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? ''),
            Text(
              '${user['department']} • ${user['role']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _initiateCall(user, 'audio'),
              icon: const Icon(Icons.phone),
              color: Colors.green,
              tooltip: 'Audio Call',
            ),
            IconButton(
              onPressed: () => _initiateCall(user, 'video'),
              icon: const Icon(Icons.videocam),
              color: Colors.blue,
              tooltip: 'Video Call',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCallTile(Map<String, dynamic> call) {
    Color statusColor;
    IconData statusIcon;
    
    switch (call['status']) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.call_received;
        break;
      case 'missed':
        statusColor = Colors.red;
        statusIcon = Icons.call_missed;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.call;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            call['type'] == 'video' ? Icons.videocam : Icons.phone,
            color: Colors.white,
          ),
        ),
        title: Text(
          call['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${call['time']} • ${call['duration']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _callBack(call),
              icon: const Icon(Icons.call),
              color: Colors.green,
              tooltip: 'Call Back',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            color: isActive ? Colors.white : Colors.grey[700],
            iconSize: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _toggleCall() {
    setState(() {
      _isCallActive = !_isCallActive;
      if (_isCallActive) {
        _callStatus = 'Call in progress...';
        // You would start the actual call timer here
      } else {
        _callStatus = 'Call ended';
        _callDuration = '00:00';
        // Reset call state
        _isMuted = false;
        _isSpeakerOn = false;
        _isVideoOn = false;
        
        // Reset status after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _callStatus = 'Ready to call';
            });
          }
        });
      }
    });
  }

  void _initiateCall(Map<String, dynamic> user, String type) {
    final userName = user['name'] ?? 'Unknown User';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type == 'video' ? 'Video' : 'Audio'} Call'),
        content: Text('Calling $userName...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isCallActive = true;
                _callStatus = 'Calling $userName...';
                if (type == 'video') _isVideoOn = true;
              });
            },
            child: const Text('Start Call'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _callBack(Map<String, dynamic> call) {
    final userName = call['name'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Back'),
        content: Text('Call $userName back?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isCallActive = true;
                _callStatus = 'Calling $userName...';
              });
            },
            child: const Text('Call'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
