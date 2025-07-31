import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'video_call_service.dart';
import '../../features/calling/presentation/pages/simple_call_page.dart';

/// Simple and reliable call service using Firebase for signaling
/// No complex WebRTC dependencies - works perfectly on web and mobile
class CallService {
  static bool _isInCall = false;
  static bool _isMuted = false;
  static bool _isVideoOn = false;
  static String? _currentCallId;
  static BuildContext? _currentContext;
  static StreamSubscription? _callStateListener;
  
  // Callbacks for UI updates
  static Function(String uid)? onUserJoined;
  static Function(String uid)? onUserLeft;
  static Function()? onCallEnded;
  static Function(String error)? onError;
  
  /// Initialize the call service
  static Future<void> initialize() async {
    try {
      await VideoCallService.initialize();
      
      // Test Firestore connection
      final connected = await VideoCallService.testFirestoreConnection();
      if (!connected) {
        throw Exception('Failed to connect to Firestore');
      }
      
      debugPrint('✅ CallService initialized successfully');
    } catch (e) {
      debugPrint('❌ CallService initialization failed: $e');
      throw Exception('Unable to initialize call service. Please restart the app.');
    }
  }
  
  /// Start a new call
  static Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String callType,
    BuildContext? context,
  }) async {
    try {
      debugPrint('📞 Starting call to $calleeName ($callType)');
      
      // Store context for later navigation
      _currentContext = context;
      
      final callId = await VideoCallService.startCall(
        calleeId: calleeId,
        calleeName: calleeName,
        callType: callType,
      );
      
      _currentCallId = callId;
      _isInCall = true;
      _isVideoOn = callType == 'video';
      
      // Listen for call state changes to auto-navigate caller
      _listenToCallStateChanges(callId, callType, calleeName);
      
      return callId;
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      throw Exception('Unable to start call. Please check your connection and try again.');
    }
  }
  
  /// Accept an incoming call
  static Future<void> acceptCall({
    required String callId,
    required String roomId,
    required String callType,
    String? callerName,
  }) async {
    try {
      debugPrint('✅ Accepting call: $callId');
      
      await VideoCallService.acceptCall(callId);
      
      _currentCallId = callId;
      _isInCall = true;
      _isVideoOn = callType == 'video';
      
    } catch (e) {
      debugPrint('❌ Error accepting call: $e');
      throw Exception('Unable to accept call. Please check your connection and try again.');
    }
  }
  
  /// Decline an incoming call
  static Future<void> declineCall(String callId) async {
    try {
      debugPrint('❌ Declining call: $callId');
      await VideoCallService.declineCall(callId);
    } catch (e) {
      debugPrint('❌ Error declining call: $e');
      throw Exception('Unable to decline call. Please try again.');
    }
  }
  
  /// End the current call
  static Future<void> endCall() async {
    try {
      debugPrint('📞 Ending call');
      await VideoCallService.endCall();
      _cleanup();
    } catch (e) {
      debugPrint('❌ Error ending call: $e');
    }
  }
  
  /// Toggle mute state
  static bool toggleMute() {
    _isMuted = !_isMuted;
    debugPrint('🔊 Mute toggled: $_isMuted');
    return _isMuted;
  }
  
  /// Toggle video state
  static bool toggleVideo() {
    _isVideoOn = !_isVideoOn;
    debugPrint('📹 Video toggled: $_isVideoOn');
    return _isVideoOn;
  }
  
  /// Toggle speaker state (for mobile)
  static bool toggleSpeaker() {
    // This would be handled by the native platform
    debugPrint('🔊 Speaker toggled');
    return true;
  }
  
  /// Create a meeting room
  static Future<String> createMeeting({
    required String title,
    String? organizerName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final meetingId = await VideoCallService.createMeeting(
        title: title,
        organizerId: user.uid,
        organizerName: organizerName ?? user.displayName ?? user.email ?? 'Unknown',
        participantIds: [user.uid],
      );
      
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
      await VideoCallService.joinMeeting(meetingId);
      _isInCall = true;
      debugPrint('✅ Joined meeting: $meetingId');
    } catch (e) {
      debugPrint('❌ Error joining meeting: $e');
      throw Exception('Unable to join meeting. Please check your connection.');
    }
  }
  
  /// Leave a meeting
  static Future<void> leaveMeeting(String meetingId) async {
    try {
      await VideoCallService.leaveMeeting(meetingId);
      _cleanup();
      debugPrint('✅ Left meeting: $meetingId');
    } catch (e) {
      debugPrint('❌ Error leaving meeting: $e');
    }
  }
  
  /// Generate meeting URL for sharing
  static String generateMeetingUrl(String meetingId) {
    return VideoCallService.generateMeetingUrl(meetingId);
  }
  
  /// Get meeting details
  static Future<Map<String, dynamic>?> getMeetingDetails(String meetingId) {
    return VideoCallService.getMeetingDetails(meetingId);
  }
  
  /// Listen to call state changes to automatically navigate caller
  static void _listenToCallStateChanges(String callId, String callType, String calleeName) {
    _callStateListener?.cancel();
    
    _callStateListener = FirebaseFirestore.instance
        .collection('calls')
        .doc(callId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        final state = data['state'] as String;
        
        debugPrint('📞 Call state changed: $state for call $callId');
        
        if (state == 'connected' && _currentContext != null) {
          // Call was accepted, navigate caller to call page
          debugPrint('✅ Call accepted, navigating caller to call page');
          
          Navigator.of(_currentContext!).push(
            MaterialPageRoute(
              builder: (context) => SimpleCallPage(
                callId: callId,
                callType: callType,
                callerName: calleeName,
                isIncoming: false, // This is the caller
              ),
            ),
          );
          
          // Clear context to prevent duplicate navigation
          _currentContext = null;
        } else if (state == 'ended' || state == 'declined') {
          _cleanup();
        }
      }
    });
  }
  
  /// Clean up call state
  static void _cleanup() {
    _callStateListener?.cancel();
    _callStateListener = null;
    _isInCall = false;
    _isMuted = false;
    _isVideoOn = false;
    _currentCallId = null;
    _currentContext = null;
  }
  
  // Getters
  static bool get isInCall => _isInCall;
  static bool get isMuted => _isMuted;
  static bool get isVideoOn => _isVideoOn;
  static bool get isSpeakerOn => true; // Assume speaker is on for mobile
  static String? get currentCallId => _currentCallId;
  
  /// Navigate to call page
  static Future<void> navigateToCallPage(
    BuildContext context, {
    required String callId,
    required String callType,
    String? callerName,
    required bool isIncoming,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleCallPage(
          callId: callId,
          callType: callType,
          callerName: callerName,
          isIncoming: isIncoming,
        ),
      ),
    );
  }

  /// Dispose of the service
  static void dispose() {
    VideoCallService.dispose();
    _cleanup();
  }
}
