import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/call_service.dart';
import 'active_call_page.dart';
import '../widgets/call_test_widget.dart';
import '../widgets/call_invitation_debug_widget.dart';
import '../widgets/call_acceptance_widget.dart';

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
      // Get users stream and convert to list for the UI
      final usersStream = FirebaseService.getUsers();
      final snapshot = await usersStream.first;
      
      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'name': data['username'] ?? 'Unknown User',
          'username': data['username'] ?? 'Unknown User',
          'email': data['email'] ?? '',
          'department': data['department'] ?? '',
          'role': data['role'] ?? '',
          'status': data['isOnline'] == true ? 'online' : 'offline',
          'isOnline': data['isOnline'] ?? false,
          'avatar': (data['username'] ?? 'U').substring(0, 1).toUpperCase(),
        };
      }).toList();
      
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Call Acceptance Widget - Shows incoming calls with accept/decline buttons
          const CallAcceptanceWidget(),
          
          const SizedBox(height: 20),
          
          // Debug Widget for Call Invitations
          const CallInvitationDebugWidget(),
          
          const SizedBox(height: 20),
          
          // Test Widget for Development
          const CallTestWidget(),
          
          const SizedBox(height: 20),
          
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
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Please log in to view call history'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.getCallHistory(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading call history: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final calls = snapshot.data?.docs ?? [];

        if (calls.isEmpty) {
          return Center(
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
          );
        }

        return ListView.builder(
          itemCount: calls.length,
          itemBuilder: (context, index) {
            final callDoc = calls[index];
            final callData = callDoc.data() as Map<String, dynamic>;
            
            // Format the call data for display
            final call = {
              'id': callDoc.id,
              'name': callData['calleeName'] ?? 'Unknown User',
              'type': callData['type'] ?? 'audio',
              'duration': _formatDuration(callData['duration'] ?? 0),
              'status': callData['status'] ?? 'completed',
              'time': _formatTime(callData['timestamp']),
              'calleeId': callData['calleeId'],
            };
            
            return _buildRecentCallTile(call);
          },
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Unknown';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
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

  void _initiateCall(Map<String, dynamic> user, String type) async {
    final userName = user['name'] ?? 'Unknown User';
    final userId = user['uid'];
    
    try {
      // Show calling dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('${type == 'video' ? 'Video' : 'Audio'} Call'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Calling $userName...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      // Initialize call service if needed
      // CallService doesn't need initialization like WebRTC
      
      // Start the call
      final channelId = await CallService.startCall(
        calleeId: userId,
        calleeName: userName,
        callType: type,
        context: context,
      );
      
      // Close calling dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show waiting message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call started! Waiting for the other person to accept...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
    } catch (e) {
      // Close calling dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
      
      print('❌ Error initiating call: $e');
    }
  }

  void _callBack(Map<String, dynamic> call) async {
    final userName = call['name'];
    final calleeId = call['calleeId'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Back'),
        content: Text('Call $userName back?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() {
                _isCallActive = true;
                _callStatus = 'Calling $userName...';
              });

              // Simulate callback
              await Future.delayed(const Duration(seconds: 3));
              
              if (mounted) {
                setState(() {
                  _callStatus = 'Connected to $userName';
                });
                
                await Future.delayed(const Duration(seconds: 8));
                
                if (mounted && _isCallActive) {
                  // Log the callback
                  await FirebaseService.logCall(
                    calleeId: calleeId ?? 'unknown',
                    calleeName: userName,
                    type: 'audio', // Default for callback
                    status: 'completed',
                    duration: 11,
                  );
                  
                  setState(() {
                    _isCallActive = false;
                    _callStatus = 'Call ended';
                    _callDuration = '00:11';
                    _isMuted = false;
                    _isSpeakerOn = false;
                    _isVideoOn = false;
                  });
                  
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() {
                        _callStatus = 'Ready to call';
                        _callDuration = '00:00';
                      });
                    }
                  });
                }
              }
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
