import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirebaseService {
  // Mock user data for demo purposes
  static final Map<String, Map<String, String>> _mockUsers = {
    'admin@sews.com': {
      'password': 'admin123',
      'username': 'SEWS Admin',
      'department': 'Management',
      'role': 'Administrator',
    },
    'test@sews.com': {
      'password': 'test123',
      'username': 'Test User',
      'department': 'Maintenance',
      'role': 'Technician',
    },
  };

  static Map<String, dynamic>? _currentUser;

  // Mock chat rooms that can be dynamically updated
  static final List<Map<String, dynamic>> _mockChatRooms = [
    {
      'id': 'general',
      'name': 'General Discussion',
      'description': 'Company-wide announcements and general chat',
      'members': ['mock_user1', 'mock_user2', 'mock_user3'],
      'lastMessage': 'Welcome to SEWS Connect!',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch - 300000,
      'memberCount': 15,
    },
    {
      'id': 'maintenance',
      'name': 'Maintenance Team',
      'description': 'Maintenance department coordination',
      'members': ['mock_user1', 'mock_user4'],
      'lastMessage': 'Equipment check scheduled for tomorrow',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch - 180000,
      'memberCount': 8,
    },
    {
      'id': 'production',
      'name': 'Production Floor',
      'description': 'Production updates and coordination',
      'members': ['mock_user2', 'mock_user5'],
      'lastMessage': 'Shift handover notes ready',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch - 120000,
      'memberCount': 12,
    },
  ];

  static String? get currentUserId => _currentUser?['uid'];
  static Map<String, dynamic>? get currentUser => _currentUser;

  static Future<bool> signInUser(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    if (_mockUsers.containsKey(email)) {
      final userData = _mockUsers[email]!;
      if (userData['password'] == password) {
        _currentUser = {
          'uid': 'mock_${email.hashCode}',
          'email': email,
          'username': userData['username'],
          'department': userData['department'],
          'role': userData['role'],
          'isActive': true,
          'isOnline': true,
        };
        print('✅ Mock sign in successful: $email');
        return true;
      }
    }
    print('❌ Mock sign in failed: Invalid credentials');
    return false;
  }

  static Future<bool> createUser(String email, String password, String username, String department, String role) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    if (_mockUsers.containsKey(email)) {
      print('❌ Mock registration failed: User already exists');
      return false;
    }
    
    _mockUsers[email] = {
      'password': password,
      'username': username,
      'department': department,
      'role': role,
    };
    
    _currentUser = {
      'uid': 'mock_${email.hashCode}',
      'email': email,
      'username': username,
      'department': department,
      'role': role,
      'isActive': true,
      'isOnline': true,
    };
    
    print('✅ Mock user created successfully: $email');
    return true;
  }

  static Future<void> signOut() async {
    _currentUser = null;
    print('✅ Mock user signed out');
  }

  static Future<List<Map<String, dynamic>>> getChatRoomsList() async {
    await Future.delayed(Duration(milliseconds: 300));
    
    // Return the dynamic list of chat rooms
    return List<Map<String, dynamic>>.from(_mockChatRooms);
  }

  static Future<String?> createSimpleChatRoom(String name, String description) async {
    await Future.delayed(Duration(milliseconds: 500));
    
    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
    
    // Add the new room to the list
    final newRoom = {
      'id': roomId,
      'name': name,
      'description': description,
      'members': [_currentUser?['uid'] ?? 'mock_user'],
      'lastMessage': 'Chat room created! Welcome to $name',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'memberCount': 1,
    };
    
    _mockChatRooms.insert(0, newRoom); // Add at the beginning (most recent)
    
    print('✅ Mock chat room created: $name (ID: $roomId)');
    return roomId;
  }

  static Future<bool> quickAdminSetup() async {
    await Future.delayed(Duration(milliseconds: 800));
    
    const adminEmail = 'admin@sews.com';
    const adminPassword = 'admin123';
    
    _mockUsers[adminEmail] = {
      'password': adminPassword,
      'username': 'SEWS Admin',
      'department': 'Management',
      'role': 'Administrator',
    };
    
    _currentUser = {
      'uid': 'mock_admin',
      'email': adminEmail,
      'username': 'SEWS Admin',
      'department': 'Management',
      'role': 'Administrator',
      'isActive': true,
      'isOnline': true,
    };
    
    print('✅ Quick admin setup completed');
    print('📧 Admin email: $adminEmail');
    print('🔑 Admin password: $adminPassword');
    return true;
  }

  static Future<List<Map<String, dynamic>>> getUsers({String? department, bool? isActive}) async {
    await Future.delayed(Duration(milliseconds: 300));
    
    // Return mock users for calling functionality
    return [
      {
        'uid': 'user1',
        'name': 'John Smith',
        'username': 'John Smith',
        'email': 'john.smith@sews.com',
        'department': 'Maintenance',
        'role': 'Technician',
        'status': 'online',
        'isOnline': true,
        'avatar': 'JS',
      },
      {
        'uid': 'user2',
        'name': 'Sarah Johnson',
        'username': 'Sarah Johnson',
        'email': 'sarah.johnson@sews.com',
        'department': 'IT',
        'role': 'IT Support',
        'status': 'online',
        'isOnline': true,
        'avatar': 'SJ',
      },
      {
        'uid': 'user3',
        'name': 'Mike Wilson',
        'username': 'Mike Wilson',
        'email': 'mike.wilson@sews.com',
        'department': 'Production',
        'role': 'Supervisor',
        'status': 'busy',
        'isOnline': false,
        'avatar': 'MW',
      },
      {
        'uid': 'user4',
        'name': 'Lisa Chen',
        'username': 'Lisa Chen',
        'email': 'lisa.chen@sews.com',
        'department': 'Quality Control',
        'role': 'Inspector',
        'status': 'online',
        'isOnline': true,
        'avatar': 'LC',
      },
    ];
  }
}
