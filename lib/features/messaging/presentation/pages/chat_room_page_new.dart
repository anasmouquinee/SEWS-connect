import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_theme.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;

  const ChatRoomPage({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _chatName = '';
  String _chatType = '';
  List<String> _members = [];
  bool _isLoading = true;
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Get chat room details from Firestore
      final chatDoc = await FirebaseFirestore.instance
          .collection('channels')
          .doc(widget.chatId)
          .get();
      
      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        setState(() {
          _chatName = data['name'] ?? 'Unknown Chat';
          _chatType = data['type'] ?? 'group';
          _members = List<String>.from(data['members'] ?? []);
          _isLoading = false;
        });
        
        // Initialize messages stream
        _messagesStream = FirebaseFirestore.instance
            .collection('channels')
            .doc(widget.chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots();
      } else {
        setState(() {
          _chatName = 'Chat Not Found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _chatName = 'Error Loading Chat';
        _isLoading = false;
      });
      print('Error loading chat: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await FirebaseService.sendMessage(
        widget.chatId,
        _messageController.text.trim(),
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _showMemberManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MemberManagementSheet(
        chatId: widget.chatId,
        currentMembers: _members,
        onMembersUpdated: () {
          _initializeChat(); // Refresh chat data
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/chat'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _chatName,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${_members.length} members',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/chat'),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startVoiceCall,
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _showMemberManagement,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List with StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show newest messages at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;
                    
                    return _buildMessageBubble(messageData, messageDoc.id);
                  },
                );
              },
            ),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, String messageId) {
    final currentUser = FirebaseService.currentUser;
    final isMe = message['senderId'] == currentUser?.uid;
    final isSystem = message['senderId'] == 'system';
    final messageText = message['message'] ?? '';
    final senderName = message['senderName'] ?? 'Unknown';
    final timestamp = message['timestamp'] as Timestamp?;
    
    // Format timestamp
    String timeString = '';
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        timeString = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeString = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeString = '${difference.inMinutes}m ago';
      } else {
        timeString = 'Just now';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && !isSystem)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                senderName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe && !isSystem) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe 
                        ? AppTheme.primaryColor 
                        : isSystem 
                            ? Colors.grey[200]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      if (timeString.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeString,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _sendMessage,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _startVideoCall() {
    context.go('/meeting');
  }

  void _startVoiceCall() {
    context.go('/call');
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chat Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Chat Info'),
                onTap: () {
                  Navigator.pop(context);
                  // Show chat info
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Mute Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  // Toggle notifications
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search Messages'),
                onTap: () {
                  Navigator.pop(context);
                  // Search functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MemberManagementSheet extends StatefulWidget {
  final String chatId;
  final List<String> currentMembers;
  final VoidCallback onMembersUpdated;

  const MemberManagementSheet({
    super.key,
    required this.chatId,
    required this.currentMembers,
    required this.onMembersUpdated,
  });

  @override
  State<MemberManagementSheet> createState() => _MemberManagementSheetState();
}

class _MemberManagementSheetState extends State<MemberManagementSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _currentMemberDetails = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentMembers();
  }

  Future<void> _loadUsers() async {
    try {
      final usersStream = FirebaseService.getUsers();
      final snapshot = await usersStream.first;
      
      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'name': data['username'] ?? 'Unknown User',
          'email': data['email'] ?? '',
          'department': data['department'] ?? '',
        };
      }).toList();
      
      setState(() {
        _allUsers = users;
        _filteredUsers = users.where((user) => 
          !widget.currentMembers.contains(user['uid'])
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  Future<void> _loadCurrentMembers() async {
    try {
      final memberDetails = <Map<String, dynamic>>[];
      
      for (final memberId in widget.currentMembers) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          memberDetails.add({
            'uid': memberId,
            'name': data['username'] ?? 'Unknown User',
            'email': data['email'] ?? '',
            'department': data['department'] ?? '',
          });
        }
      }
      
      setState(() {
        _currentMemberDetails = memberDetails;
      });
    } catch (e) {
      print('Error loading current members: $e');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final department = user['department']?.toString().toLowerCase() ?? '';
        return !widget.currentMembers.contains(user['uid']) &&
               (name.contains(query) || email.contains(query) || department.contains(query));
      }).toList();
    });
  }

  Future<void> _addMember(String userId) async {
    try {
      await FirebaseService.addMemberToChatRoom(widget.chatId, userId);
      widget.onMembersUpdated();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add member: $e')),
      );
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      await FirebaseService.removeMemberFromChatRoom(widget.chatId, userId);
      widget.onMembersUpdated();
      setState(() {
        _currentMemberDetails.removeWhere((member) => member['uid'] == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove member: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Row(
              children: [
                Icon(Icons.group, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Manage Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Current Members Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Members (${_currentMemberDetails.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: _currentMemberDetails.isEmpty
                      ? const Center(child: Text('No members'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currentMemberDetails.length,
                          itemBuilder: (context, index) {
                            final member = _currentMemberDetails[index];
                            final currentUser = FirebaseService.currentUser;
                            final isCurrentUser = member['uid'] == currentUser?.uid;
                            
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.blue[100],
                                        child: Text(
                                          (member['name'] ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (!isCurrentUser)
                                        Positioned(
                                          top: -5,
                                          right: -5,
                                          child: GestureDetector(
                                            onTap: () => _removeMember(member['uid']),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      member['name'] ?? 'Unknown',
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Add Members Section
          Expanded(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterUsers(),
                    decoration: InputDecoration(
                      hintText: 'Search users to add...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),

                // Available Users List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredUsers.isEmpty
                          ? const Center(
                              child: Text('No users available to add'),
                            )
                          : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Text(
                                      (user['name'] ?? 'U')[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(user['name'] ?? 'Unknown User'),
                                  subtitle: Text(user['email'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green),
                                    onPressed: () => _addMember(user['uid']),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
