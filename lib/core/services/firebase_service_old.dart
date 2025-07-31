import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseDatabase? _database;

  // Initialize Firebase services only if Firebase is available
  static bool get _isFirebaseAvailable {
    if (kIsWeb) return false; // Temporarily disabled for web
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static FirebaseAuth? get _getAuth {
    if (!_isFirebaseAvailable) return null;
    _auth ??= FirebaseAuth.instance;
    return _auth;
  }

  static FirebaseFirestore? get _getFirestore {
    if (!_isFirebaseAvailable) return null;
    _firestore ??= FirebaseFirestore.instance;
    return _firestore;
  }

  static FirebaseDatabase? get _getDatabase {
    if (!_isFirebaseAvailable) return null;
    _database ??= FirebaseDatabase.instance;
    return _database;
  }

  // Authentication
  static User? get currentUser => _getAuth?.currentUser;
  
  static Future<UserCredential?> signInAnonymously() async {
    final auth = _getAuth;
    if (auth == null) {
      print('Firebase not available - using demo mode');
      return null;
    }
    try {
      return await auth.signInAnonymously();
    } catch (e) {
      print('Anonymous sign in failed: $e');
      return null;
    }
  }

  static Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    final auth = _getAuth;
    if (auth == null) {
      print('Firebase not available - using demo mode');
      return null;
    }
    try {
      return await auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Sign in failed: $e');
      return null;
    }
  }

  // Authentication
  Future<String?> registerUser(String email, String password) async {
    final auth = _getAuth;
    if (auth == null) {
      print('Firebase not available - using demo mode');
      return null;
    }
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInUser(String email, String password) async {
    final auth = _getAuth;
    if (auth == null) {
      print('Firebase not available - using demo mode');
      return null;
    }
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> signOut() async {
    final auth = _getAuth;
    if (auth == null) return;
    await auth.signOut();
  }

  // User Document Management
  Future<void> createUserDocument(String email, String username, String department, String role) async {
    final auth = _getAuth;
    final firestore = _getFirestore;
    if (auth == null || firestore == null) return;
    
    final user = auth.currentUser;
    if (user != null) {
      await firestore.collection('users').doc(user.uid).set({
        'email': email,
        'username': username,
        'department': department,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Real-time Messaging
  static Stream<QuerySnapshot> getMessages(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage(String channelId, String message, String senderName, String department) async {
    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .add({
      'message': message,
      'senderName': senderName,
      'department': department,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': currentUser?.uid,
    });
  }

  // Department Notifications
  static Future<void> sendDepartmentNotification(String department, String title, String message, String priority) async {
    await _firestore.collection('notifications').add({
      'department': department,
      'title': title,
      'message': message,
      'priority': priority,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  static Stream<QuerySnapshot> getDepartmentNotifications(String department) {
    return _firestore
        .collection('notifications')
        .where('department', whereIn: [department, 'All'])
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Task Management with First-Scan-Wins
  static Future<bool> claimTask(String taskId, String machineId, String userId, String userName, String department) async {
    try {
      DocumentReference taskRef = _firestore.collection('tasks').doc(taskId);
      
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot taskDoc = await transaction.get(taskRef);
        
        if (!taskDoc.exists) {
          throw Exception('Task does not exist');
        }
        
        Map<String, dynamic> taskData = taskDoc.data() as Map<String, dynamic>;
        
        // Check if task is already claimed (first-scan-wins)
        if (taskData['status'] == 'claimed' || taskData['assignedTo'] != null) {
          return false; // Task already claimed
        }
        
        // Claim the task
        transaction.update(taskRef, {
          'status': 'claimed',
          'assignedTo': userId,
          'assignedName': userName,
          'assignedDepartment': department,
          'claimedAt': FieldValue.serverTimestamp(),
        });
        
        return true; // Successfully claimed
      });
    } catch (e) {
      print('Error claiming task: $e');
      return false;
    }
  }

  // Admin Dashboard Data
  static Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  static Stream<QuerySnapshot> getAllTasks() {
    return _firestore.collection('tasks').snapshots();
  }

  static Stream<QuerySnapshot> getSystemLogs() {
    return _firestore
        .collection('system_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // Equipment/Machine Management
  static Future<void> updateMachineStatus(String machineId, String status, String notes) async {
    await _firestore.collection('machines').doc(machineId).update({
      'status': status,
      'notes': notes,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  static Stream<DocumentSnapshot> getMachineInfo(String machineId) {
    return _firestore.collection('machines').doc(machineId).snapshots();
  }

  // User Management for Admin
  static Future<void> createUser(String email, String name, String department, String role) async {
    await _firestore.collection('users').add({
      'email': email,
      'name': name,
      'department': department,
      'role': role,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> isAdmin(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'admin' || userData['role'] == 'super_admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
