import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final rtdb.FirebaseDatabase _database = rtdb.FirebaseDatabase.instance;

  // REAL Firebase initialization - NO MORE PLACEHOLDERS
  static bool get isInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      print('Firebase not initialized: $e');
      return false;
    }
  }

  // Authentication - REAL WORKING FUNCTIONS
  static User? get currentUser => _auth.currentUser;
  
  static Future<UserCredential?> createUser(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      print('✅ User created successfully: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ Auth Error: ${e.message}');
      throw e;
    }
  }

  static Future<UserCredential?> signInUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      print('✅ User signed in: ${result.user?.email}');
      return result;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in Error: ${e.message}');
      throw e;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ User signed out');
    } catch (e) {
      print('❌ Sign out error: $e');
    }
  }
  
  // REAL USER DOCUMENT CREATION
  static Future<void> createUserDocument(String email, String username, String department, String role) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'username': username,
          'department': department,
          'role': role,
          'isActive': true,
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'profilePicture': '',
          'phoneNumber': '',
        });
        print('✅ User document created successfully');
      } catch (e) {
        print('❌ Error creating user document: $e');
        throw e;
      }
    }
  }

  // Quick admin setup for development
  static Future<bool> quickAdminSetup() async {
    try {
      const adminEmail = 'admin@sews.com';
      const adminPassword = 'admin123';
      
      // Create admin user
      final userCredential = await createUser(adminEmail, adminPassword);
      if (userCredential != null) {
        // Create admin user document
        await createUserDocument(adminEmail, 'SEWS Admin', 'Management', 'admin');
        print('✅ Quick admin setup completed');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Admin setup failed: $e');
      return false;
    }
  }

  // REAL MESSAGING FUNCTIONS
  static Stream<QuerySnapshot> getMessages(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  static Future<void> sendMessage(String channelId, String message, [String? senderName, String? department]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for default values if not provided
      String userName = senderName ?? 'Unknown User';
      String userDept = department ?? 'General';
      
      if (senderName == null || department == null) {
        try {
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            userName = userData['username'] ?? 'Unknown User';
            userDept = userData['department'] ?? 'General';
          }
        } catch (e) {
          print('⚠️ Could not fetch user data, using defaults: $e');
        }
      }

      await _firestore
          .collection('channels')
          .doc(channelId)
          .collection('messages')
          .add({
        'message': message,
        'senderName': userName,
        'senderId': user.uid,
        'department': userDept,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'isRead': false,
        'reactions': {},
      });

      // Update channel last activity
      await _firestore.collection('channels').doc(channelId).update({
        'lastActivity': FieldValue.serverTimestamp(),
        'lastMessage': message,
        'lastMessageSender': userName,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      throw e;
    }
  }

  // REAL NOTIFICATION SYSTEM
  static Future<void> sendNotification(String title, String body, String department, String priority) async {
    try {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'department': department,
        'priority': priority,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'recipients': [],
        'type': 'general',
        'actionRequired': priority == 'high',
      });
      print('✅ Notification sent successfully');
    } catch (e) {
      print('❌ Error sending notification: $e');
      throw e;
    }
  }

  static Stream<QuerySnapshot> getNotifications(String department) {
    return _firestore
        .collection('notifications')
        .where('department', whereIn: [department, 'all'])
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // REAL TASK MANAGEMENT with first-scan-wins logic
  static Future<bool> claimTask(String taskId, String userId, String username) async {
    try {
      DocumentReference taskRef = _firestore.collection('tasks').doc(taskId);
      
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot taskSnapshot = await transaction.get(taskRef);
        
        if (!taskSnapshot.exists) {
          return false; // Task doesn't exist
        }
        
        Map<String, dynamic> taskData = taskSnapshot.data() as Map<String, dynamic>;
        
        if (taskData['assignedTo'] == null || taskData['status'] == 'open') {
          // Task is available - claim it!
          transaction.update(taskRef, {
            'assignedTo': userId,
            'assignedToName': username,
            'claimedAt': FieldValue.serverTimestamp(),
            'status': 'in_progress',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Send notification to department
          await sendNotification(
            'Task Claimed',
            'Task "${taskData['title']}" has been claimed by $username',
            taskData['department'],
            'low',
          );
          
          return true; // Successfully claimed
        } else {
          return false; // Task already claimed
        }
      });
    } catch (e) {
      print('❌ Error claiming task: $e');
      return false;
    }
  }

  static Future<void> completeTask(String taskId, String notes) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completionNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Task completed successfully');
    } catch (e) {
      print('❌ Error completing task: $e');
      throw e;
    }
  }

  static Future<String> createTask(Map<String, dynamic> taskData) async {
    try {
      DocumentReference taskRef = await _firestore.collection('tasks').add({
        ...taskData,
        'status': 'open',
        'assignedTo': null,
        'assignedToName': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Send notification to department
      await sendNotification(
        'New Task Available',
        'New task: ${taskData['title']}',
        taskData['department'],
        taskData['priority'] ?? 'medium',
      );
      
      print('✅ Task created successfully');
      return taskRef.id;
    } catch (e) {
      print('❌ Error creating task: $e');
      throw e;
    }
  }

  static Stream<QuerySnapshot> getTasks({String? department, String? status}) {
    Query query = _firestore.collection('tasks');
    
    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // REAL ADMIN FUNCTIONS
  static Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  static Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User role updated successfully');
    } catch (e) {
      print('❌ Error updating user role: $e');
      throw e;
    }
  }

  static Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User deactivated successfully');
    } catch (e) {
      print('❌ Error deactivating user: $e');
      throw e;
    }
  }

  // REAL CHAT ROOM MANAGEMENT - FULLY FUNCTIONAL
  static Future<String?> createChatRoom(String name, String type, List<String> members, String createdBy) async {
    try {
      DocumentReference roomRef = await _firestore.collection('channels').add({
        'name': name,
        'type': type, // 'direct', 'group', 'department'
        'members': members,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageSender': '',
        'isActive': true,
        'memberCount': members.length,
        'settings': {
          'allowAttachments': true,
          'allowVoiceMessages': true,
          'requireApproval': false,
        },
      });
      
      // Create initial welcome message
      await roomRef.collection('messages').add({
        'message': type == 'group' ? 'Group chat created by system' : 'Chat started',
        'senderName': 'System',
        'senderId': 'system',
        'department': 'System',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
        'isRead': false,
      });
      
      print('✅ Chat room created successfully: ${roomRef.id}');
      return roomRef.id;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      return null;
    }
  }

  static Stream<QuerySnapshot> getChatRooms(String userId) {
    // Simplified query to avoid complex index requirements
    return _firestore
        .collection('channels')
        .where('members', arrayContains: userId)
        .snapshots();
  }

  // ULTRA SIMPLIFIED - NO QUERIES AT ALL, just get everything and filter locally
  static Future<List<Map<String, dynamic>>> getChatRoomsList() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        return [];
      }
      
      print('📍 Fetching all channels for user: ${user.uid}');
      
      // Simplest possible query - get ALL documents from channels collection
      QuerySnapshot snapshot = await _firestore
          .collection('channels')
          .get();
      
      print('📍 Retrieved ${snapshot.docs.length} total channels');
      
      // Filter everything in-app to avoid ANY Firestore query complexity
      List<Map<String, dynamic>> rooms = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          // Check if user is a member (handle null gracefully)
          List<dynamic> members = data['members'] ?? [];
          bool userIsMember = members.contains(user.uid);
          
          // Check if active (default to true if not specified)
          bool isActive = data['isActive'] ?? true;
          
          if (userIsMember && isActive) {
            rooms.add(data);
            print('✅ Added room: ${data['name']} (${doc.id})');
          }
        } catch (e) {
          print('⚠️ Skipped malformed document ${doc.id}: $e');
        }
      }
      
      // Sort by lastActivity in-app (handle missing timestamps gracefully)
      rooms.sort((a, b) {
        try {
          dynamic aActivity = a['lastActivity'];
          dynamic bActivity = b['lastActivity'];
          
          // Convert to comparable timestamps
          int aTime = 0;
          int bTime = 0;
          
          if (aActivity is Timestamp) {
            aTime = aActivity.millisecondsSinceEpoch;
          } else if (aActivity is int) {
            aTime = aActivity;
          }
          
          if (bActivity is Timestamp) {
            bTime = bActivity.millisecondsSinceEpoch;
          } else if (bActivity is int) {
            bTime = bActivity;
          }
          
          return bTime.compareTo(aTime); // Most recent first
        } catch (e) {
          return 0; // If comparison fails, keep original order
        }
      });
      
      print('✅ Successfully got ${rooms.length} chat rooms for user');
      return rooms;
    } catch (e) {
      print('❌ Error getting chat rooms: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  static Future<String?> createSimpleChatRoom(String name, String description) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      DocumentReference roomRef = await _firestore.collection('channels').add({
        'name': name,
        'description': description,
        'type': 'group',
        'members': [user.uid],
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageSender': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isActive': true,
        'memberCount': 1,
        'settings': {
          'allowAttachments': true,
          'allowVoiceMessages': true,
          'requireApproval': false,
        },
      });
      
      // Create initial welcome message
      await roomRef.collection('messages').add({
        'message': 'Chat room created! Welcome to $name',
        'senderName': 'System',
        'senderId': 'system',
        'department': 'System',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
        'isRead': false,
      });
      
      print('✅ Chat room created successfully: ${roomRef.id}');
      return roomRef.id;
    } catch (e) {
      print('❌ Error creating chat room: $e');
      return null;
    }
  }

  static Future<void> addMemberToChatRoom(String roomId, String userId) async {
    try {
      await _firestore.collection('channels').doc(roomId).update({
        'members': FieldValue.arrayUnion([userId]),
        'lastActivity': FieldValue.serverTimestamp(),
        'memberCount': FieldValue.increment(1),
      });
      
      // Add system message
      await _firestore
          .collection('channels')
          .doc(roomId)
          .collection('messages')
          .add({
        'message': 'User joined the chat',
        'senderName': 'System',
        'senderId': 'system',
        'department': 'System',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
        'isRead': false,
      });
      
      print('✅ Member added to chat room successfully');
    } catch (e) {
      print('❌ Error adding member to chat room: $e');
      throw e;
    }
  }

  static Future<void> removeMemberFromChatRoom(String roomId, String userId) async {
    try {
      await _firestore.collection('channels').doc(roomId).update({
        'members': FieldValue.arrayRemove([userId]),
        'lastActivity': FieldValue.serverTimestamp(),
        'memberCount': FieldValue.increment(-1),
      });
      
      // Add system message
      await _firestore
          .collection('channels')
          .doc(roomId)
          .collection('messages')
          .add({
        'message': 'User left the chat',
        'senderName': 'System',
        'senderId': 'system',
        'department': 'System',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
        'isRead': false,
      });
      
      print('✅ Member removed from chat room successfully');
    } catch (e) {
      print('❌ Error removing member from chat room: $e');
      throw e;
    }
  }

  // REAL EQUIPMENT MANAGEMENT
  static Stream<QuerySnapshot> getEquipment({String? department, String? status}) {
    Query query = _firestore.collection('equipment');
    
    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.orderBy('name').snapshots();
  }

  static Future<void> updateEquipmentStatus(String equipmentId, String status, String notes) async {
    try {
      await _firestore.collection('equipment').doc(equipmentId).update({
        'status': status,
        'lastMaintenance': FieldValue.serverTimestamp(),
        'maintenanceNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Equipment status updated successfully');
    } catch (e) {
      print('❌ Error updating equipment status: $e');
      throw e;
    }
  }

  // REAL USER MANAGEMENT
  static Stream<QuerySnapshot> getUsers({String? department, bool? isActive}) {
    Query query = _firestore.collection('users');
    
    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }
    
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }
    
    return query.orderBy('username').snapshots();
  }

  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  static Future<QuerySnapshot> getUserByEmail(String email) async {
    try {
      return await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
    } catch (e) {
      print('❌ Error getting user by email: $e');
      rethrow;
    }
  }

  // REAL CALL HISTORY MANAGEMENT
  static Future<void> logCall({
    required String calleeId,
    required String calleeName,
    required String type, // 'audio', 'video'
    required String status, // 'completed', 'missed', 'declined'
    required int duration, // in seconds
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('call_history').add({
        'callerId': user.uid,
        'calleeId': calleeId,
        'calleeName': calleeName,
        'type': type,
        'status': status,
        'duration': duration,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Call logged successfully');
    } catch (e) {
      print('❌ Error logging call: $e');
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getCallHistory(String userId) {
    return _firestore
        .collection('call_history')
        .where('callerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  static Future<void> markCallAsRead(String callId) async {
    try {
      await _firestore.collection('call_history').doc(callId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking call as read: $e');
    }
  }

  // REAL MEETING MANAGEMENT
  static Future<String?> createMeeting({
    required String title,
    required String description,
    required DateTime startTime,
    required int duration,
    required List<String> participants,
    required String type, // 'video', 'audio', 'conference'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for organizer info
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      String meetingId = 'MTG-${DateTime.now().millisecondsSinceEpoch}';
      String jitsiRoomId = 'sews-${DateTime.now().millisecondsSinceEpoch}';
      
      DocumentReference meetingRef = await _firestore.collection('meetings').add({
        'meetingId': meetingId,
        'jitsiRoomId': jitsiRoomId, // Add Jitsi room ID
        'title': title,
        'description': description,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(startTime.add(Duration(minutes: duration))),
        'duration': duration,
        'participants': participants,
        'organizer': user.uid,
        'organizerName': userData['username'] ?? 'Unknown User',
        'organizerEmail': userData['email'] ?? '',
        'type': type,
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'joinUrl': 'https://meet.jit.si/$jitsiRoomId', // Use Jitsi URL
        'settings': {
          'allowRecording': true,
          'allowScreenShare': true,
          'requirePassword': false,
          'maxParticipants': 50,
        },
      });

      // Send notifications to all participants
      for (String participantId in participants) {
        if (participantId != user.uid) { // Don't notify organizer
          await sendNotification(
            'Meeting Invitation',
            'You\'ve been invited to "$title" on ${startTime.day}/${startTime.month}',
            'all', // Send to all departments since it's a meeting
            'medium',
          );
        }
      }

      print('✅ Meeting created successfully: ${meetingRef.id}');
      return meetingRef.id;
    } catch (e) {
      print('❌ Error creating meeting: $e');
      return null;
    }
  }

  static Future<void> joinMeeting(String meetingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('meetings').doc(meetingId).update({
        'joinedParticipants': FieldValue.arrayUnion([user.uid]),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      print('✅ Joined meeting successfully');
    } catch (e) {
      print('❌ Error joining meeting: $e');
      throw e;
    }
  }

  static Future<void> endMeeting(String meetingId) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Meeting ended successfully');
    } catch (e) {
      print('❌ Error ending meeting: $e');
      throw e;
    }
  }

  static Stream<QuerySnapshot> getMeetings({String? userId, String? status}) {
    Query query = _firestore.collection('meetings');
    
    if (userId != null) {
      query = query.where('participants', arrayContains: userId);
    }
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    // Remove orderBy to avoid Firebase index requirements
    return query.snapshots();
  }

  static Future<Map<String, dynamic>?> getMeetingDetails(String meetingId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('meetings').doc(meetingId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting meeting details: $e');
      return null;
    }
  }
  static Future<void> seedInitialData() async {
    try {
      // Create departments
      final departments = ['Maintenance', 'Production', 'Quality Control', 'IT', 'Management'];
      
      for (String dept in departments) {
        await _firestore.collection('departments').doc(dept.toLowerCase()).set({
          'name': dept,
          'isActive': true,
          'memberCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Create department channel
        await createChatRoom('$dept Department', 'department', [], 'system');
      }
      
      // Create sample equipment
      final equipment = [
        {
          'id': 'EQ001',
          'name': 'Assembly Line A',
          'department': 'Production',
          'status': 'operational',
          'type': 'assembly_line',
        },
        {
          'id': 'EQ002',
          'name': 'Quality Scanner B',
          'department': 'Quality Control',
          'status': 'maintenance_needed',
          'type': 'scanner',
        },
        {
          'id': 'EQ003',
          'name': 'Packaging Unit C',
          'department': 'Production',
          'status': 'offline',
          'type': 'packaging',
        },
        {
          'id': 'EQ004',
          'name': 'Server Room AC',
          'department': 'IT',
          'status': 'warning',
          'type': 'hvac',
        },
      ];
      
      for (var eq in equipment) {
        await _firestore.collection('equipment').doc(eq['id']).set({
          ...eq,
          'lastMaintenance': FieldValue.serverTimestamp(),
          'nextMaintenance': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
          'createdAt': FieldValue.serverTimestamp(),
          'maintenanceNotes': '',
        });
      }
      
      // Create sample tasks
      final tasks = [
        {
          'title': 'Fix Assembly Line A Motor',
          'description': 'Motor making unusual noise, needs inspection and possible replacement',
          'equipmentId': 'EQ001',
          'department': 'Maintenance',
          'priority': 'high',
          'estimatedHours': 4,
          'category': 'mechanical',
        },
        {
          'title': 'Calibrate Quality Scanner',
          'description': 'Scanner accuracy has decreased to 85%, needs recalibration',
          'equipmentId': 'EQ002',
          'department': 'Quality Control',
          'priority': 'medium',
          'estimatedHours': 2,
          'category': 'calibration',
        },
        {
          'title': 'Replace Packaging Unit Conveyor Belt',
          'description': 'Belt showing signs of wear, replace before failure',
          'equipmentId': 'EQ003',
          'department': 'Production',
          'priority': 'low',
          'estimatedHours': 6,
          'category': 'replacement',
        },
      ];
      
      for (var task in tasks) {
        await createTask(task);
      }
      
      print('✅ Initial Firebase data seeded successfully!');
      
    } catch (e) {
      print('⚠️ Error seeding data: $e');
    }
  }

  // Call invitation methods
  static Future<void> sendCallInvitation({
    String? callerId,
    String? callerName,
    required String calleeId,
    required String calleeName,
    String? channelId,
    String? jitsiRoomId,
    required String callType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get caller info from current user if not provided
      final currentCallerId = callerId ?? user.uid;
      final currentCallerName = callerName ?? user.displayName ?? 'Unknown User';
      
      debugPrint('📞 Sending call invitation:');
      debugPrint('   callerId: $currentCallerId');
      debugPrint('   callerName: $currentCallerName');
      debugPrint('   calleeId: $calleeId');
      debugPrint('   calleeName: $calleeName');
      debugPrint('   channelId: $channelId');
      debugPrint('   jitsiRoomId: $jitsiRoomId');
      debugPrint('   callType: $callType');
      
      await _firestore.collection('call_invitations').add({
        'callerId': currentCallerId,
        'callerName': currentCallerName,
        'calleeId': calleeId,
        'calleeName': calleeName,
        'channelId': channelId, // Keep for backward compatibility
        'jitsiRoomId': jitsiRoomId, // New Jitsi room ID
        'callType': callType,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'platform': 'jitsi', // Mark as Jitsi call
      });
      
      print('✅ Call invitation sent from $currentCallerName to $calleeName');
    } catch (e) {
      print('❌ Error sending call invitation: $e');
      throw e;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getCallInvitations(String userId) {
    debugPrint('👂 Listening for call invitations for userId: $userId');
    // Simplified query to avoid Firebase index requirements
    return _firestore
        .collection('call_invitations')
        .where('calleeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  static Future<void> respondToCallInvitation({
    required String invitationId,
    required String response, // 'accepted' or 'declined'
  }) async {
    try {
      await _firestore.collection('call_invitations').doc(invitationId).update({
        'status': response,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Call invitation $response');
    } catch (e) {
      print('❌ Error responding to call invitation: $e');
      throw e;
    }
  }
}
