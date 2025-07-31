import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    try {
      final chatRooms = await FirebaseService.getChatRoomsList();
      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat rooms: $e')),
        );
      }
    }
  }

  Future<void> _createNewChatRoom() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Chat Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter chat room name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter room description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                try {
                  await FirebaseService.createSimpleChatRoom(
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadChatRooms(); // Refresh the list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat room created successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating chat room: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _createNewChatRoom,
            icon: const Icon(Icons.add_comment),
            tooltip: 'Create New Chat Room',
          ),
          IconButton(
            onPressed: _loadChatRooms,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No chat rooms available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a new chat room to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewChatRoom,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Chat Room'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chatRooms.length,
                    itemBuilder: (context, index) {
                      final chatRoom = _chatRooms[index];
                      final roomId = chatRoom['id'] ?? '';
                      final roomName = chatRoom['name'] ?? 'Unnamed Room';
                      final description = chatRoom['description'] ?? '';
                      final memberCount = (chatRoom['members'] as List?)?.length ?? 0;
                      final lastMessage = chatRoom['lastMessage'] as String?;
                      final lastMessageTime = chatRoom['lastMessageTime'];

                      String formattedTime = '';
                      if (lastMessageTime != null) {
                        try {
                          final DateTime dateTime;
                          if (lastMessageTime is int) {
                            dateTime = DateTime.fromMillisecondsSinceEpoch(lastMessageTime);
                          } else {
                            dateTime = DateTime.parse(lastMessageTime.toString());
                          }
                          final now = DateTime.now();
                          final difference = now.difference(dateTime);
                          
                          if (difference.inDays > 0) {
                            formattedTime = '${difference.inDays}d ago';
                          } else if (difference.inHours > 0) {
                            formattedTime = '${difference.inHours}h ago';
                          } else if (difference.inMinutes > 0) {
                            formattedTime = '${difference.inMinutes}m ago';
                          } else {
                            formattedTime = 'Just now';
                          }
                        } catch (e) {
                          formattedTime = '';
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[700],
                            radius: 24,
                            child: Text(
                              roomName.isNotEmpty ? roomName[0].toUpperCase() : 'C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            roomName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$memberCount member${memberCount != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (lastMessage != null && lastMessage.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    const Text('•', style: TextStyle(color: Colors.grey)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        lastMessage,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (formattedTime.isNotEmpty)
                                Text(
                                  formattedTime,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                          onTap: () {
                            if (roomId.isNotEmpty) {
                              context.push('/chat/$roomId');
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
