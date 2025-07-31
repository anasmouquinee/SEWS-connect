import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'video_call_service.dart';

/// Simple and reliable call service using Firebase for signaling
/// No complex WebRTC dependencies - works perfectly on web and mobile
class CallService {
  static bool _isInCall = false;
  static bool _isMuted = false;
  static bool _isVideoOn = false;
  static String? _currentCallId;
  
  // Callbacks for UI updates
  static Function(String uid)? onUserJoined;
  static Function(String uid)? onUserLeft;
  static Function()? onCallEnded;
  static Function(String error)? onError;
  
  /// Initialize the call service
  static Future<void> initialize() async {
    await VideoCallService.initialize();
    debugPrint('✅ CallService initialized');
  }
  
  /// Start a new call
  static Future<String> startCall({
    required String calleeId,
    required String calleeName,
    required String callType,
  }) async {
    try {
      debugPrint('📞 Starting call to $calleeName ($callType)');
      
      final callId = await VideoCallService.startCall(
        calleeId: calleeId,
        calleeName: calleeName,
        callType: callType,
      );
      
      _currentCallId = callId;
      _isInCall = true;
      _isVideoOn = callType == 'video';
      
      return callId;
    } catch (e) {
      debugPrint('❌ Error starting call: $e');
      // Don't rethrow - provide user-friendly error
      throw Exception('Unable to start call. Please check your connection.');
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
      // Don't rethrow - provide user-friendly error
      throw Exception('Unable to join call. Please check your connection.');
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
      final meetingId = await VideoCallService.createMeeting(
        title: title,
        organizerName: organizerName,
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
  
  /// Clean up call state
  static void _cleanup() {
    _isInCall = false;
    _isMuted = false;
    _isVideoOn = false;
    _currentCallId = null;
  }
  
  // Getters
  static bool get isInCall => _isInCall;
  static bool get isMuted => _isMuted;
  static bool get isVideoOn => _isVideoOn;
  static bool get isSpeakerOn => true; // Assume speaker is on for mobile
  static String? get currentCallId => _currentCallId;
  
  /// Dispose of the service
  static void dispose() {
    VideoCallService.dispose();
    _cleanup();
  }
}
