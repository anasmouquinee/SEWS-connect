import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'real_webrtc_service.dart';

/// Enhanced video call service with REAL WebRTC integration
/// Combines Firebase signaling with actual WebRTC audio/video
class VideoCallService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final Uuid _uuid = const Uuid();
  
  static bool _isInCall = false;
  static String? _currentCallId;
  static StreamSubscription<DocumentSnapshot>? _callListener;
  static bool _answerHandled = false;  // Add flag to prevent multiple answer handling
  static bool _isMuted = false;
  static bool _isVideoEnabled = true;
  
  // Call states
  static const String callStateInviting = 'inviting';
  static const String callStateConnected = 'connected';
  static const String callStateEnded = 'ended';
  static const String callStateDeclined = 'declined';

  /// Initialize the video call service with real WebRTC
  static Future<void> initialize() async {
    try {
      // Initialize Real WebRTC service
      await RealWebRTCService.initialize();
      
      // Test Firestore connection
      await _firestore.enableNetwork();
      debugPrint('✅ VideoCallService initialized - Firestore connected, Real WebRTC ready');
      
      // Optional: Clear any orphaned call documents older than 1 hour
      await _cleanupOldCalls();
    } catch (e) {
      debugPrint('❌ VideoCallService initialization failed: $e');
      throw Exception('Unable to initialize video service. Please restart the app.');
    }
  }

  /// Clean up old call documents to prevent accumulation
  static Future<void> _cleanupOldCalls() async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final oldCalls = await _firestore
          .collection('calls')
          .where('createdAt', isLessThan: oneHourAgo.toIso8601String())
          .get();

      final batch = _firestore.batch();
      for (final doc in oldCalls.docs) {
        batch.delete(doc.reference);
      }
      
      if (oldCalls.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('🧹 Cleaned up ${oldCalls.docs.length} old call documents');
      }
    } catch (e) {
      debugPrint('⚠️ Error cleaning up old calls: $e');
      // Don't throw - this is optional cleanup
    }
  }

  /// Start a new call
  static Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String callType,
  }) async {
    try {
      final caller = _auth.currentUser;
      if (caller == null) {
        throw Exception('User not authenticated');
      }

      final callId = _uuid.v4();
      
      // Prepare call data
      final callData = {
        'callId': callId,
        'callerId': caller.uid,
        'callerName': caller.displayName ?? caller.email ?? 'Unknown',
        'callerEmail': caller.email,
        'calleeId': calleeId,
        'calleeName': calleeName,
        'callType': callType,
        'state': callStateInviting,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'webrtc_enabled': true,
      };

      // Create call document
      await _firestore.collection('calls').doc(callId).set(callData);
      
      // Send invitation to callee
      await _firestore.collection('call_invitations').add({
        'callId': callId,
        'calleeId': calleeId,
        'calleeName': calleeName,
        'callerId': caller.uid,
        'callerName': caller.displayName ?? caller.email ?? 'Unknown',
        'callerEmail': caller.email,
        'callType': callType,
        'state': callStateInviting,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _currentCallId = callId;
      _isInCall = true;
      _answerHandled = false;  // Reset flag for new call
      
      debugPrint('✅ Call started with Real WebRTC: $callId');
      
      // Listen for call state changes
      _listenToCallState(callId);
      
      // Create WebRTC offer
      try {
        final isVideo = callType == 'video';
        debugPrint('🔊 About to create WebRTC offer (video: $isVideo)...');
        await RealWebRTCService.createOffer(callId, video: isVideo);
        debugPrint('✅ WebRTC offer created successfully');
      } catch (webrtcError) {
        debugPrint('❌ WebRTC offer creation failed: $webrtcError');
        // Don't fail the entire call - continue with Firebase signaling only
        debugPrint('⚠️ Continuing with Firebase signaling only (no WebRTC)');
      }
      
      return callId;
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      
      // Clean up the call document if we created it
      if (_currentCallId != null) {
        try {
          await _firestore.collection('calls').doc(_currentCallId!).delete();
          debugPrint('🧹 Cleaned up failed call document: $_currentCallId');
        } catch (cleanupError) {
          debugPrint('⚠️ Failed to cleanup call document: $cleanupError');
        }
        _currentCallId = null;
        _isInCall = false;
      }
      
      // Don't rethrow - return a failure indicator or throw a user-friendly error
      throw Exception('Unable to start call. Please check your connection and try again.');
    }
  }

  /// Accept an incoming call with real WebRTC
  static Future<void> acceptCall(String callId) async {
    try {
      // Check if call document exists first
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      
      if (!callDoc.exists) {
        throw Exception('Call document not found: $callId');
      }

      final callData = callDoc.data()!;
      final callType = callData['callType'] as String? ?? 'audio';

      await _firestore.collection('calls').doc(callId).update({
        'state': callStateConnected,
        'acceptedAt': DateTime.now().toIso8601String(),
      });

      _currentCallId = callId;
      _isInCall = true;
      _answerHandled = false;  // Reset flag for new call
      
      // Listen for call state changes
      _listenToCallState(callId);
      
      // Create WebRTC answer
      try {
        final isVideo = callType == 'video';
        debugPrint('🔊 About to create WebRTC answer (video: $isVideo)...');
        await RealWebRTCService.createAnswer(callId, video: isVideo);
        debugPrint('✅ WebRTC answer created successfully');
      } catch (webrtcError) {
        debugPrint('❌ WebRTC answer creation failed: $webrtcError');
        // Don't fail the entire call - continue with Firebase signaling only
        debugPrint('⚠️ Continuing with Firebase signaling only (no WebRTC)');
      }
      
      debugPrint('✅ Call accepted with Real WebRTC: $callId');
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      
      // Clean up if needed
      if (_currentCallId == callId) {
        _currentCallId = null;
        _isInCall = false;
      }
      
      // Don't rethrow - throw a user-friendly error
      throw Exception('Unable to accept call. Please check your connection and try again.');
    }
  }

  /// Decline an incoming call
  static Future<void> declineCall(String callId) async {
    try {
      // Check if call document exists first
      final callDoc = await _firestore.collection('calls').doc(callId).get();
      
      if (!callDoc.exists) {
        throw Exception('Call document not found: $callId');
      }

      await _firestore.collection('calls').doc(callId).update({
        'state': callStateDeclined,
        'declinedAt': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Call declined: $callId');
    } catch (e) {
      debugPrint('❌ Error declining call: $e');
      throw Exception('Unable to decline call. Please try again.');
    }
  }

  /// End the current call
  static Future<void> endCall() async {
    try {
      if (_currentCallId != null) {
        // Check if call document exists first
        final callDoc = await _firestore.collection('calls').doc(_currentCallId!).get();
        
        if (callDoc.exists) {
          await _firestore.collection('calls').doc(_currentCallId!).update({
            'state': callStateEnded,
            'endedAt': DateTime.now().toIso8601String(),
          });
          debugPrint('✅ Call ended: $_currentCallId');
        } else {
          debugPrint('⚠️ Call document not found, already ended: $_currentCallId');
        }

        // End Real WebRTC call
        await RealWebRTCService.endCall();
        
        _cleanup();
      } else {
        debugPrint('⚠️ No active call to end');
      }
    } catch (e) {
      debugPrint('❌ Error ending call: $e');
      // Clean up anyway to prevent stuck state
      await RealWebRTCService.endCall();
      _cleanup();
    }
  }

  /// Listen to call state changes and handle WebRTC signaling
  static void _listenToCallState(String callId) {
    _callListener?.cancel();
    _callListener = _firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final state = data['state'] as String;
        final webrtcState = data['webrtc_state'] as String?;
        
        debugPrint('📞 Call state changed: $state, WebRTC state: $webrtcState');
        debugPrint('🔍 Checking answer handling - callerId: ${data['callerId']}, currentUser: ${_auth.currentUser?.uid}, answerHandled: $_answerHandled');
        
        // Handle WebRTC signaling
        if (webrtcState == 'answer_created' && data['callerId'] == _auth.currentUser?.uid && !_answerHandled) {
          // Caller received answer, handle it (only once)
          debugPrint('✅ Triggering answer handling for caller...');
          _answerHandled = true;
          await RealWebRTCService.handleAnswer(callId);
          debugPrint('✅ Answer handling completed');
        } else if (webrtcState == 'answer_created') {
          debugPrint('⚠️ Answer handling skipped - Reason: callerId=${data['callerId']}, currentUser=${_auth.currentUser?.uid}, answerHandled=$_answerHandled');
        }
        
        if (state == callStateEnded || state == callStateDeclined) {
          await RealWebRTCService.endCall();
          _cleanup();
        }
      } else {
        debugPrint('⚠️ Call document not found or has no data: $callId');
        await RealWebRTCService.endCall();
        _cleanup();
      }
    }, onError: (error) async {
      debugPrint('❌ Error listening to call state: $error');
      await RealWebRTCService.endCall();
      _cleanup();
    });
  }

  /// Clean up call resources
  static void _cleanup() {
    _callListener?.cancel();
    _callListener = null;
    _isInCall = false;
    _currentCallId = null;
    _answerHandled = false;  // Reset flag on cleanup
  }

  /// Toggle microphone mute
  static Future<void> toggleMute() async {
    await RealWebRTCService.toggleMute();
  }

  /// Toggle video
  static Future<void> toggleVideo() async {
    await RealWebRTCService.toggleVideo();
  }

  /// Test Firestore connection
  static Future<bool> testFirestoreConnection() async {
    try {
      await _firestore.collection('test').doc('ping').set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Firestore connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore connection test failed: $e');
      return false;
    }
  }

  /// Get call invitations stream for a user
  static Stream<QuerySnapshot<Map<String, dynamic>>> getCallInvitations(String userId) {
    return _firestore
        .collection('call_invitations')
        .where('calleeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Create a meeting room
  static Future<String> createMeeting({
    required String title,
    required String organizerId,
    required String organizerName,
    required List<String> participantIds,
  }) async {
    try {
      final meetingId = _uuid.v4();
      
      await _firestore.collection('meetings').doc(meetingId).set({
        'meetingId': meetingId,
        'title': title,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'participantIds': participantIds,
        'createdAt': DateTime.now().toIso8601String(),
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
        'webrtc_enabled': true,
      });

      debugPrint('✅ Meeting created: $meetingId');
      return meetingId;
    } catch (e) {
      debugPrint('❌ Error creating meeting: $e');
      throw Exception('Unable to create meeting. Please check your connection.');
    }
  }

  /// Join a meeting
  static Future<void> joinMeeting(String meetingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('meetings').doc(meetingId).update({
        'participantIds': FieldValue.arrayUnion([user.uid]),
        'lastActivity': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Joined meeting: $meetingId');
    } catch (e) {
      debugPrint('❌ Error joining meeting: $e');
      throw Exception('Unable to join meeting. Please check your connection.');
    }
  }

  /// Leave a meeting
  static Future<void> leaveMeeting(String meetingId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('meetings').doc(meetingId).update({
        'participantIds': FieldValue.arrayRemove([user.uid]),
        'lastActivity': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Left meeting: $meetingId');
    } catch (e) {
      debugPrint('❌ Error leaving meeting: $e');
      throw Exception('Unable to leave meeting. Please restart the app.');
    }
  }

  /// Generate meeting URL
  static String generateMeetingUrl(String meetingId) {
    return 'https://sewsconnect.com/meeting/$meetingId';
  }

  /// Get meeting details
  static Future<Map<String, dynamic>?> getMeetingDetails(String meetingId) async {
    try {
      final doc = await _firestore.collection('meetings').doc(meetingId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('❌ Error getting meeting details: $e');
      return null;
    }
  }

  /// Dispose of the service
  static void dispose() {
    _cleanup();
    RealWebRTCService.dispose();
  }

  // Getters
  static bool get isInCall => _isInCall;
  static String? get currentCallId => _currentCallId;
  static bool get isMuted => RealWebRTCService.isMuted;
  static bool get isVideoEnabled => RealWebRTCService.isVideoEnabled;
  
  // Real WebRTC stream getters
  static get localStream => RealWebRTCService.localStream;
  static get remoteStream => RealWebRTCService.remoteStream;
  static get remoteStreamStream => RealWebRTCService.remoteStreamStream;
  static get callStateStream => RealWebRTCService.callStateStream;
}