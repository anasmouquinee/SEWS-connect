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
  
  // Instance methods for Firebase operations
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

  Future<void> createUserDocument(String email, String username, String department, String role) async {
    final auth = _getAuth;
    final firestore = _getFirestore;
    if (auth == null || firestore == null) return;
    
    final user = auth.currentUser;
    if (user != null) {
      try {
        await firestore.collection('users').doc(user.uid).set({
          'email': email,
          'username': username,
          'department': department,
          'role': role,
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('Error creating user document: $e');
      }
    }
  }

  // Demo methods for web (when Firebase is not available)
  static Future<void> signOut() async {
    final auth = _getAuth;
    if (auth == null) return;
    try {
      await auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Mock methods for when Firebase is not available
  static Stream<QuerySnapshot>? getMessages(String channelId) {
    final firestore = _getFirestore;
    if (firestore == null) return null;
    
    try {
      return firestore
          .collection('channels')
          .doc(channelId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting messages: $e');
      return null;
    }
  }

  static Future<void> sendMessage(String channelId, String message, String senderName, String department) async {
    final firestore = _getFirestore;
    if (firestore == null) return;
    
    try {
      await firestore
          .collection('channels')
          .doc(channelId)
          .collection('messages')
          .add({
        'message': message,
        'senderName': senderName,
        'department': department,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'text',
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  static Future<void> sendNotification(String title, String body, String department, String priority) async {
    final firestore = _getFirestore;
    if (firestore == null) return;
    
    try {
      await firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'department': department,
        'priority': priority,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Task management with first-scan-wins logic
  static Future<bool> claimTask(String taskId, String userId, String username) async {
    final firestore = _getFirestore;
    if (firestore == null) return false;
    
    try {
      DocumentReference taskRef = firestore.collection('tasks').doc(taskId);
      
      return await firestore.runTransaction((transaction) async {
        DocumentSnapshot taskSnapshot = await transaction.get(taskRef);
        
        if (!taskSnapshot.exists) {
          return false; // Task doesn't exist
        }
        
        Map<String, dynamic> taskData = taskSnapshot.data() as Map<String, dynamic>;
        
        if (taskData['assignedTo'] == null) {
          // Task is available - claim it!
          transaction.update(taskRef, {
            'assignedTo': userId,
            'assignedToName': username,
            'claimedAt': DateTime.now().toIso8601String(),
            'status': 'in_progress',
          });
          return true; // Successfully claimed
        } else {
          return false; // Task already claimed
        }
      });
    } catch (e) {
      print('Error claiming task: $e');
      return false;
    }
  }

  // Admin functions
  static Stream<QuerySnapshot>? getAllUsers() {
    final firestore = _getFirestore;
    if (firestore == null) return null;
    try {
      return firestore.collection('users').snapshots();
    } catch (e) {
      print('Error getting users: $e');
      return null;
    }
  }

  static Stream<QuerySnapshot>? getAllTasks() {
    final firestore = _getFirestore;
    if (firestore == null) return null;
    try {
      return firestore.collection('tasks').snapshots();
    } catch (e) {
      print('Error getting tasks: $e');
      return null;
    }
  }
}
